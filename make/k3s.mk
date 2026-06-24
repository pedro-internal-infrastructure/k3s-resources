.PHONY: k3s-setup k3s-start k3s-stop k3s-enable k3s-disable k3s-delete

k3s-setup: Logs
	@echo "$(BLUE)Installing k3s from $(K3S_INSTALL_URL)...$(NC)"
	@curl -sfL $(K3S_INSTALL_URL) | \
		INSTALL_K3S_EXEC="--node-ip=$(NODE_IP) --flannel-iface=eth1" \
		sudo sh - 2>&1 | tee logs/k3s-setup.log
	@echo "$(GREEN)k3s installed. Run 'make k3s-enable && make k3s-start' to bring it up.$(NC)"

k3s-start:
	@echo "$(GREEN)Starting k3s service...$(NC)"
	@sudo systemctl start $(K3S_SERVICE)
	@systemctl is-active $(K3S_SERVICE)

k3s-stop:
	@echo "$(YELLOW)Stopping k3s service...$(NC)"
	@sudo systemctl stop $(K3S_SERVICE)

k3s-enable:
	@echo "$(GREEN)Enabling k3s service at boot...$(NC)"
	@sudo systemctl enable $(K3S_SERVICE)

k3s-disable:
	@echo "$(YELLOW)Disabling k3s service at boot...$(NC)"
	@sudo systemctl disable $(K3S_SERVICE)

k3s-delete:
	@if [ ! -x "$(K3S_UNINSTALL)" ]; then \
		echo "$(RED)$(K3S_UNINSTALL) not found — is k3s installed?$(NC)"; exit 1; \
	fi
	@echo "$(RED)Uninstalling k3s from the system...$(NC)"
	@sudo $(K3S_UNINSTALL)
	@echo "$(GREEN)k3s removed.$(NC)"
