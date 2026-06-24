.PHONY: hosts-add hosts-remove

hosts-add:
	@echo "$(BLUE)Adding domains to /etc/hosts (NODE_IP=$(NODE_IP))...$(NC)"
	@grep -v '^#' $(DOMAINS_FILE) | grep -v '^$$' | awk '{print "$(NODE_IP) " $$1}' | while read entry; do \
		if grep -qF "$$entry" /etc/hosts; then \
			echo "  already exists: $$entry"; \
		else \
			echo "$$entry" | sudo tee -a /etc/hosts > /dev/null && echo "  added: $$entry"; \
		fi; \
	done

hosts-remove:
	@echo "$(YELLOW)Removing project domains from /etc/hosts...$(NC)"
	@grep -v '^#' $(DOMAINS_FILE) | grep -v '^$$' | awk '{print $$1}' | while read domain; do \
		sudo sed -i "/[[:space:]]$$domain$$/d" /etc/hosts && echo "  removed: $$domain"; \
	done
