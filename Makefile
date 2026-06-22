BOOTSTRAP_DIR := $(HOME)/personal/k3s.install/k8s/bootstrap
APPS_DIR      := $(HOME)/personal/k3s.install/k8s/kustomize
ROOT_APP      := $(BOOTSTRAP_DIR)/root-app.yml
DOMAINS_FILE  := $(HOME)/personal/k3s.install/config/domains
BIN           := k3s kubectl
NAMESPACE     := argocd
HTTP_PORT     := 30080
HTTPS_PORT    := 30443
NODE_IP       ?= 127.0.0.1

.PHONY: install uninstall link unlink port-forward password status deploy-apps remove-apps nuke-apps prune-apps ghcr-secret hosts-add hosts-remove

Logs:
	mkdir -p logs

install: Logs 
	@echo "Installing ArgoCD in the cluster..."
	@$(BIN) apply --server-side --force-conflicts -k $(BOOTSTRAP_DIR) > logs/install.log 2>&1 || (echo "Installation failed. Check logs/install.log for details." && exit 1)

uninstall: Logs
	@echo "Step 1/3 — Removing finalizers from root app and all Applications..."
	@$(BIN) patch -f $(ROOT_APP) --type=json \
		-p='[{"op":"remove","path":"/metadata/finalizers"}]' 2>/dev/null || true
	@for app in $$($(BIN) get applications.argoproj.io -n $(NAMESPACE) -o name 2>/dev/null); do \
		$(BIN) patch $$app -n $(NAMESPACE) --type=json \
			-p='[{"op":"remove","path":"/metadata/finalizers"}]' 2>/dev/null || true; \
	done
	@echo "Step 2/3 — Deleting root app and all Applications..."
	@$(BIN) delete -f $(ROOT_APP) --ignore-not-found
	@$(BIN) delete applications.argoproj.io --all -n $(NAMESPACE) --ignore-not-found
	@echo "Step 3/3 — Uninstalling ArgoCD..."
	@$(BIN) delete -k $(BOOTSTRAP_DIR) --ignore-not-found

# Apply the root Application — links ArgoCD to the repo (run once after install)
link:
	@echo "Linking ArgoCD to the repository..."
	@$(BIN) apply -f $(ROOT_APP)

unlink:
	@echo "Unlinking ArgoCD from the repository..."
	@$(BIN) delete -f $(ROOT_APP) --ignore-not-found

port-forward: Logs
	@echo "Starting port-forwarding for ArgoCD server..."
	@$(BIN) port-forward svc/argocd-server -n $(NAMESPACE) 8080:80

password:
	@$(BIN) get secret argocd-initial-admin-secret -n $(NAMESPACE) \
		-o jsonpath="{.data.password}" | base64 -d && echo

status:

	$(BIN) get all -n $(NAMESPACE)

# Deploy ArgoCD Application manifests (run after `make install` and ArgoCD is ready)
deploy-apps:
	$(BIN) apply -k $(APPS_DIR)

remove-apps:
	$(BIN) delete -k $(APPS_DIR) --ignore-not-found

# Add project domains to /etc/hosts (requires sudo)
hosts-add:
	@echo "Adding domains to /etc/hosts (NODE_IP=$(NODE_IP))..."
	@grep -v '^#' $(DOMAINS_FILE) | grep -v '^$$' | awk '{print "$(NODE_IP) " $$1}' | while read entry; do \
		if grep -qF "$$entry" /etc/hosts; then \
			echo "  already exists: $$entry"; \
		else \
			echo "$$entry" | sudo tee -a /etc/hosts > /dev/null && echo "  added: $$entry"; \
		fi; \
	done

# Remove project domains from /etc/hosts (requires sudo)
hosts-remove:
	@echo "Removing project domains from /etc/hosts..."
	@grep -v '^#' $(DOMAINS_FILE) | grep -v '^$$' | awk '{print $$1}' | while read domain; do \
		sudo sed -i "/[[:space:]]$$domain$$/d" /etc/hosts && echo "  removed: $$domain"; \
	done

# Delete namespaces left behind when uninstall ran without finalizers
prune-apps:
	@echo "Pruning app namespaces left behind by uninstall..."
	@for ns in triggerdev istio-system istio-ingress; do \
		$(BIN) delete namespace $$ns --ignore-not-found; \
	done

# Add ghcr.io OCI repository credentials to ArgoCD (required to pull triggerdotdev Helm chart)
# Usage: make ghcr-secret GHCR_USER=<github-username> GHCR_TOKEN=<github-pat>
ghcr-secret:
	@if [ -z "$(GHCR_USER)" ] || [ -z "$(GHCR_TOKEN)" ]; then \
		echo "Error: GHCR_USER and GHCR_TOKEN must be set."; \
		echo "Usage: make ghcr-secret GHCR_USER=<github-username> GHCR_TOKEN=<github-pat>"; \
		exit 1; \
	fi
	@$(BIN) delete secret ghcr-triggerdev-charts -n $(NAMESPACE) --ignore-not-found
	@$(BIN) create secret generic ghcr-triggerdev-charts \
		-n $(NAMESPACE) \
		--from-literal=type=helm \
		--from-literal=name=ghcr-triggerdev-charts \
		--from-literal=url=ghcr.io \
		--from-literal=enableOCI=true \
		--from-literal=username=$(GHCR_USER) \
		--from-literal=password=$(GHCR_TOKEN)
	@$(BIN) label secret ghcr-triggerdev-charts -n $(NAMESPACE) \
		argocd.argoproj.io/secret-type=repository
	@echo "ghcr.io repository secret applied to ArgoCD."

# Delete every ArgoCD Application in the cluster (cascade-deletes managed resources via finalizers)
nuke-apps:
	@echo "Removing all ArgoCD Applications from the cluster..."
	@$(BIN) delete applications.argoproj.io --all -n $(NAMESPACE) --ignore-not-found
