.PHONY: k3s-download k3s-install k3s-start k3s-stop k3s-restart k3s-enable k3s-disable k3s-status k3s-delete k3s-purge

# Download the k3s binary from GitHub releases.
k3s-download: Logs
	@echo "$(BLUE)Downloading k3s $(K3S_RELEASE)...$(NC)"
	@RELEASE="$(K3S_RELEASE)" bash $(DOWNLOAD_SCRIPT) 2>&1 | tee logs/k3s-download.log
	@echo "$(GREEN)k3s binary ready at $(K3S_BIN).$(NC)"

# Install the systemd service using the local binary (no get.k3s.io).
# Run 'make k3s-download' first if the binary is not yet present.
k3s-install: Logs
	@if [ ! -x "$(K3S_BIN)" ]; then \
		echo "$(RED)$(K3S_BIN) not found — run 'make k3s-download' first.$(NC)"; exit 1; \
	fi
	@echo "$(BLUE)Writing systemd service to $(K3S_SERVICE_FILE)...$(NC)"
	@printf '%s\n' \
		'[Unit]' \
		'Description=Lightweight Kubernetes' \
		'Documentation=https://k3s.io' \
		'Wants=network-online.target' \
		'After=network-online.target' \
		'' \
		'[Service]' \
		'Type=notify' \
		'EnvironmentFile=-/etc/systemd/system/k3s.service.env' \
		'ExecStartPre=-/sbin/modprobe br_netfilter' \
		'ExecStartPre=-/sbin/modprobe overlay' \
		'ExecStart=$(K3S_BIN) server' \
		'KillMode=process' \
		'Delegate=yes' \
		'LimitNOFILE=1048576' \
		'LimitNPROC=infinity' \
		'LimitCORE=infinity' \
		'TasksMax=infinity' \
		'TimeoutStartSec=0' \
		'Restart=always' \
		'RestartSec=5s' \
		'' \
		'[Install]' \
		'WantedBy=multi-user.target' \
		| sudo tee $(K3S_SERVICE_FILE) > /dev/null
	@sudo systemctl daemon-reload
	@echo "$(GREEN)Service installed. Run 'make k3s-enable && make k3s-start' to bring it up.$(NC)"

k3s-start:
	@echo "$(GREEN)Starting k3s service...$(NC)"
	@sudo systemctl start $(K3S_SERVICE)
	@systemctl is-active $(K3S_SERVICE)

k3s-stop:
	@echo "$(YELLOW)Stopping k3s service...$(NC)"
	@sudo systemctl stop $(K3S_SERVICE)

k3s-restart:
	@echo "$(YELLOW)Restarting k3s service...$(NC)"
	@sudo systemctl restart $(K3S_SERVICE)
	@systemctl is-active $(K3S_SERVICE)

k3s-enable:
	@echo "$(GREEN)Enabling k3s service at boot...$(NC)"
	@sudo systemctl enable $(K3S_SERVICE)

k3s-disable:
	@echo "$(YELLOW)Disabling k3s service at boot...$(NC)"
	@sudo systemctl disable $(K3S_SERVICE)

k3s-status:
	@systemctl status $(K3S_SERVICE) --no-pager || true

k3s-delete:
	@echo "$(RED)Removing k3s service and binary...$(NC)"
	@sudo systemctl stop $(K3S_SERVICE) 2>/dev/null || true
	@sudo systemctl disable $(K3S_SERVICE) 2>/dev/null || true
	@sudo rm -f $(K3S_SERVICE_FILE)
	@sudo systemctl daemon-reload
	@sudo rm -f $(K3S_BIN)
	@echo "$(GREEN)k3s service and binary removed.$(NC)"

k3s-purge:
	@echo "$(RED)$(BOLD)Completely removing k3s and all configuration...$(NC)"
	@echo "Step 1/6 — Stopping and disabling k3s service..."
	@sudo systemctl stop $(K3S_SERVICE) 2>/dev/null || true
	@sudo systemctl disable $(K3S_SERVICE) 2>/dev/null || true
	@echo "Step 2/6 — Removing systemd service files..."
	@sudo rm -f $(K3S_SERVICE_FILE)
	@sudo rm -f /etc/systemd/system/k3s.service.env
	@sudo systemctl daemon-reload
	@echo "Step 3/6 — Removing k3s binary..."
	@sudo rm -f $(K3S_BIN)
	@echo "Step 4/6 — Removing configuration and data..."
	@sudo rm -rf /etc/rancher/k3s
	@sudo rm -rf /var/lib/rancher/k3s
	@sudo rm -rf /var/lib/rancher/credentialprovider
	@echo "Step 5/6 — Cleaning up network interfaces..."
	@sudo ip link delete cni0 2>/dev/null || true
	@sudo ip link delete flannel.1 2>/dev/null || true
	@echo "Step 6/6 — Done."
	@echo "$(GREEN)$(BOLD)k3s completely purged from the system.$(NC)"
	@echo "$(YELLOW)Note: You may need to reboot to fully clean up network state.$(NC)"
