#!/usr/bin/env bash
#
# download.sh — Download the k3s binary from the k3s-io GitHub releases
#               and install it locally to /usr/local/bin/k3s.
#
# The binary and its sha256 checksum are fetched directly from
# https://github.com/k3s-io/k3s/releases, verified, then installed.
#
# Usage:
#   ./download.sh                 # download + verify + install RELEASE below
#   RELEASE="v1.36.2+k3s1" ./download.sh
#   INSTALL_DIR=/usr/local/bin ./download.sh
#
set -euo pipefail

# --- Configuration ----------------------------------------------------------
RELEASE="${RELEASE:-v1.36.2+k3s1}"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
GITHUB_BASE="https://github.com/k3s-io/k3s/releases/download"

# --- Helpers ----------------------------------------------------------------
log()  { printf '\033[0;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[0;32m✓\033[0m %s\n' "$*"; }
err()  { printf '\033[0;31mError:\033[0m %s\n' "$*" >&2; }

cleanup() { [ -n "${TMP_DIR:-}" ] && rm -rf "$TMP_DIR"; }
trap cleanup EXIT

# --- Detect architecture ----------------------------------------------------
# Map `uname -m` to the suffix used by the k3s release assets.
arch="$(uname -m)"
case "$arch" in
	x86_64 | amd64)        SUFFIX="" ;;          # k3s
	aarch64 | arm64)       SUFFIX="-arm64" ;;    # k3s-arm64
	armv7l | armhf | arm)  SUFFIX="-armhf" ;;    # k3s-armhf
	s390x)                 SUFFIX="-s390x" ;;    # k3s-s390x
	*)
		err "Unsupported architecture: $arch"
		exit 1
		;;
esac

BINARY="k3s${SUFFIX}"

# URL-encode the '+' in the release tag (e.g. v1.36.2+k3s1 -> v1.36.2%2Bk3s1).
RELEASE_ENC="${RELEASE//+/%2B}"
BINARY_URL="${GITHUB_BASE}/${RELEASE_ENC}/${BINARY}"
SHA_URL="${GITHUB_BASE}/${RELEASE_ENC}/sha256sum-${arch}.txt"

# --- Download ---------------------------------------------------------------
TMP_DIR="$(mktemp -d)"

log "Downloading k3s ${RELEASE} (${BINARY}) for ${arch}..."
if ! curl -fL --progress-bar -o "${TMP_DIR}/k3s" "$BINARY_URL"; then
	err "Failed to download ${BINARY_URL}"
	exit 1
fi
ok "Binary downloaded."

# --- Verify checksum (best effort) ------------------------------------------
log "Fetching checksum..."
if curl -fsSL -o "${TMP_DIR}/sha256sum.txt" "$SHA_URL"; then
	expected="$(grep -E "[[:space:]]k3s${SUFFIX}\$" "${TMP_DIR}/sha256sum.txt" | awk '{print $1}' | head -n1)"
	if [ -n "$expected" ]; then
		actual="$(sha256sum "${TMP_DIR}/k3s" | awk '{print $1}')"
		if [ "$expected" = "$actual" ]; then
			ok "Checksum verified."
		else
			err "Checksum mismatch! expected=${expected} actual=${actual}"
			exit 1
		fi
	else
		err "Could not find ${BINARY} entry in checksum file; skipping verification."
	fi
else
	err "Checksum file unavailable; skipping verification."
fi

# --- Install ----------------------------------------------------------------
chmod +x "${TMP_DIR}/k3s"

SUDO=""
if [ ! -w "$INSTALL_DIR" ]; then
	SUDO="sudo"
	log "Installing to ${INSTALL_DIR} (requires sudo)..."
else
	log "Installing to ${INSTALL_DIR}..."
fi

$SUDO install -m 0755 "${TMP_DIR}/k3s" "${INSTALL_DIR}/k3s"
ok "k3s installed to ${INSTALL_DIR}/k3s"

# --- Done -------------------------------------------------------------------
"${INSTALL_DIR}/k3s" --version
