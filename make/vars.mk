REPO_ROOT       ?= $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
BOOTSTRAP_DIR   ?= $(REPO_ROOT)/k8s/bootstrap
APPS_DIR        ?= $(REPO_ROOT)/k8s/kustomize
ROOT_APP        ?= $(BOOTSTRAP_DIR)/root-app.yml
DOMAINS_FILE    ?= $(REPO_ROOT)/config/domains
LOGS_DIR        ?= $(REPO_ROOT)/logs
BIN             ?= k3s kubectl
ARGOCD_CLI      ?= $(REPO_ROOT)/bin/argocd
ARGOCD_VERSION  ?= v2.10.4
NAMESPACE       ?= argocd
HTTP_PORT       ?= 30080
HTTPS_PORT      ?= 30443
NODE_IP          ?= 127.0.0.1
K3S_SERVICE      ?= k3s
K3S_RELEASE      ?= v1.36.2+k3s1
K3S_BIN          ?= /usr/local/bin/k3s
K3S_SERVICE_FILE ?= /etc/systemd/system/k3s.service
DOWNLOAD_SCRIPT  ?= $(REPO_ROOT)/make/scripts/download.sh

# Colors
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
BLUE   := \033[0;34m
CYAN   := \033[0;36m
BOLD   := \033[1m
NC     := \033[0m

Logs:
	@mkdir -p $(LOGS_DIR)
