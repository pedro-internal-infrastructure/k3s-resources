.PHONY: deploy-gitlab remove-gitlab

# Creates the ArgoCD AppProject and Application — ArgoCD then syncs GitLab from GitHub
deploy-gitlab: Logs
	@echo "$(BLUE)Creating GitLab ArgoCD Application...$(NC)"
	@$(BIN) apply -f $(GITLAB_DIR)/namespace.yml \
		-f $(GITLAB_DIR)/project.yml \
		-f $(GITLAB_DIR)/application.yml 2>&1 | tee logs/deploy-gitlab.log
	@echo "$(GREEN)GitLab Application created in ArgoCD. ArgoCD will sync it from GitHub.$(NC)"
	@echo "  Access at http://localhost/gitlab once the pod is ready."
	@echo "  Initial root password: ChangeMe123!"
	@echo "  Track readiness with: make pods"

remove-gitlab:
	@echo "$(YELLOW)Removing GitLab ArgoCD Application and AppProject...$(NC)"
	@$(BIN) patch application gitlab -n $(NAMESPACE) --type=json \
		-p='[{"op":"remove","path":"/metadata/finalizers"}]' 2>/dev/null || true
	@$(BIN) delete -f $(GITLAB_DIR)/application.yml --ignore-not-found
	@$(BIN) delete -f $(GITLAB_DIR)/project.yml --ignore-not-found
	@$(BIN) delete -f $(GITLAB_DIR)/namespace.yml --ignore-not-found
	@echo "$(GREEN)GitLab removed.$(NC)"
