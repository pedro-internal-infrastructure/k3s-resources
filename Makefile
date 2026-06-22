BOOTSTRAP_DIR := $(HOME)/personal/k3s.install/k8s/bootstrap
APPS_DIR      := $(HOME)/personal/k3s.install/k8s/kustomize
ROOT_APP      := $(BOOTSTRAP_DIR)/root-app.yml
BIN           := k3s kubectl
NAMESPACE     := argocd
HTTP_PORT     := 30080
HTTPS_PORT    := 30443

.PHONY: install uninstall link unlink port-forward password status deploy-apps remove-apps

install:
	$(BIN) apply --server-side --force-conflicts -k $(BOOTSTRAP_DIR)

uninstall:
	$(BIN) delete -k $(BOOTSTRAP_DIR) --ignore-not-found

# Apply the root Application — links ArgoCD to the repo (run once after install)
link:
	$(BIN) apply -f $(ROOT_APP)

unlink:
	$(BIN) delete -f $(ROOT_APP) --ignore-not-found

port-forward:
	$(BIN) port-forward svc/argocd-server -n $(NAMESPACE) 8080:80

password:
	@$(BIN) get secret argocd-initial-admin-secret -n $(NAMESPACE) \
		-o jsonpath="{.data.password}" | base64 -d && echo

status:
	$(BIN) get all -n $(NAMESPACE)

# Deploy ArgoCD Application manifests (run after `make install` and ArgoCD is ready)
deploy-apps:
	$(BIN) apply -f $(APPS_DIR)/

remove-apps:
	$(BIN) delete -f $(APPS_DIR)/ --ignore-not-found
