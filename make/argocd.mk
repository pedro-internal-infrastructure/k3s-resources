.PHONY: install uninstall link unlink port-forward password status pods deploy-apps remove-apps install-argocd-bin authenticate argocd-sync

install-argocd-bin: Logs
	@if [ -f "$(ARGOCD_CLI)" ]; then \
		echo "$(GREEN)ArgoCD CLI already installed at $(ARGOCD_CLI)$(NC)"; \
	else \
		echo "$(BLUE)Downloading ArgoCD CLI $(ARGOCD_VERSION)...$(NC)"; \
		mkdir -p bin; \
		curl -sSL -o $(ARGOCD_CLI) https://github.com/argoproj/argo-cd/releases/download/$(ARGOCD_VERSION)/argocd-linux-amd64; \
		chmod +x $(ARGOCD_CLI); \
		echo "$(GREEN)ArgoCD CLI installed successfully$(NC)"; \
		$(ARGOCD_CLI) version --client; \
	fi

authenticate: install-argocd-bin
	@echo "$(BLUE)Authenticating to ArgoCD...$(NC)"
	@PASSWORD=$$($(BIN) get secret argocd-initial-admin-secret -n $(NAMESPACE) -o jsonpath="{.data.password}" 2>/dev/null | base64 -d); \
	if [ -z "$$PASSWORD" ]; then \
		echo "$(RED)Error: Could not retrieve ArgoCD password$(NC)"; \
		exit 1; \
	fi; \
	$(ARGOCD_CLI) login localhost:8443 --username admin --password "$$PASSWORD" --grpc-web; \
	echo "$(GREEN)Successfully authenticated to ArgoCD$(NC)"

argocd-sync: install-argocd-bin
	@if [ -z "$(APP)" ]; then \
		echo "$(RED)Error: APP not specified. Usage: make sync APP=<app-name>$(NC)"; \
		echo "$(YELLOW)Example: make sync APP=istio-base$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Syncing application: $(APP)...$(NC)"
	@$(ARGOCD_CLI) app sync $(APP) --server localhost:8443 --grpc-web
	@echo "$(GREEN)Application $(APP) synced successfully$(NC)"

install: Logs
	@echo "$(BLUE)Installing ArgoCD in the cluster...$(NC)"
	@$(BIN) apply --server-side --force-conflicts -k $(BOOTSTRAP_DIR) > logs/install.log 2>&1 \
		|| (echo "$(RED)Installation failed. Check logs/install.log for details.$(NC)" && exit 1)
	@echo "$(GREEN)ArgoCD installed.$(NC)"

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

link:
	@echo "$(BLUE)Linking ArgoCD to the repository...$(NC)"
	@$(BIN) apply -f $(ROOT_APP)

unlink:
	@echo "$(YELLOW)Unlinking ArgoCD from the repository...$(NC)"
	@$(BIN) delete -f $(ROOT_APP) --ignore-not-found

port-forward: Logs
	@echo "$(BLUE)Starting port-forwarding for ArgoCD server...$(NC)"
	@echo "  Open: https://localhost:8443"
	@$(BIN) port-forward svc/argocd-server -n $(NAMESPACE) 8443:443 &> logs/port-forward.log &

password:
	@$(BIN) get secret argocd-initial-admin-secret -n $(NAMESPACE) \
		-o jsonpath="{.data.password}" | base64 -d && echo


status:
	@$(BIN) get all -n $(NAMESPACE)

pods:
	@$(BIN) get pods -A -o wide

deploy-apps:
	@$(BIN) apply -k $(APPS_DIR)

remove-apps:
	@$(BIN) delete -k $(APPS_DIR) --ignore-not-found
