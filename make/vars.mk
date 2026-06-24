GITLAB_DIR      := $(HOME)/personal/k3s.install/k8s/kustomize/gitlab
BOOTSTRAP_DIR   := $(HOME)/personal/k3s.install/k8s/bootstrap
APPS_DIR        := $(HOME)/personal/k3s.install/k8s/kustomize
ROOT_APP        := $(BOOTSTRAP_DIR)/root-app.yml
DOMAINS_FILE    := $(HOME)/personal/k3s.install/config/domains
BIN             := k3s kubectl
NAMESPACE       := argocd
HTTP_PORT       := 30080
HTTPS_PORT      := 30443
NODE_IP         ?= 127.0.0.1
K3S_INSTALL_URL := https://get.k3s.io
K3S_UNINSTALL   := /usr/local/bin/k3s-uninstall.sh
K3S_SERVICE     := k3s

# Colors
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
BLUE   := \033[0;34m
CYAN   := \033[0;36m
BOLD   := \033[1m
NC     := \033[0m

Logs:
	@mkdir -p logs
