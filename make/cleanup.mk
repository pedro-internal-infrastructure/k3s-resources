.PHONY: nuke-apps prune-apps ghcr-secret

nuke-apps:
	@echo "$(RED)Removing all ArgoCD Applications from the cluster...$(NC)"
	@$(BIN) delete applications.argoproj.io --all -n $(NAMESPACE) --ignore-not-found

prune-apps:
	@echo "$(YELLOW)Pruning app namespaces left behind by uninstall...$(NC)"
	@echo "  stripping finalizers from ArgoCD Applications..."
	@$(BIN) get applications.argoproj.io -n $(NAMESPACE) -o name 2>/dev/null \
		| xargs -I{} $(BIN) patch {} -n $(NAMESPACE) \
			--type=json -p='[{"op":"remove","path":"/metadata/finalizers"}]' 2>/dev/null || true
	@for ns in triggerdev istio-system istio-ingress monitoring kubernetes-dashboard; do \
		if $(BIN) get namespace $$ns > /dev/null 2>&1; then \
			echo "  stripping finalizers in $$ns..."; \
			$(BIN) api-resources --verbs=list --namespaced -o name 2>/dev/null \
				| xargs -I{} $(BIN) get {} -n $$ns -o name 2>/dev/null \
				| xargs -I{} $(BIN) patch {} -n $$ns \
					--type=json -p='[{"op":"remove","path":"/metadata/finalizers"}]' 2>/dev/null || true; \
			echo "  deleting namespace $$ns..."; \
			$(BIN) delete namespace $$ns --ignore-not-found; \
		fi; \
	done

# Usage: make ghcr-secret GHCR_USER=<github-username> GHCR_TOKEN=<github-pat>
ghcr-secret:
	@if [ -z "$(GHCR_USER)" ] || [ -z "$(GHCR_TOKEN)" ]; then \
		echo "$(RED)Error: GHCR_USER and GHCR_TOKEN must be set.$(NC)"; \
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
	@echo "$(GREEN)ghcr.io repository secret applied to ArgoCD.$(NC)"
