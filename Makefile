.DEFAULT_GOAL := help

REPO_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

include $(REPO_ROOT)/make/vars.mk
include $(REPO_ROOT)/make/help.mk
include $(REPO_ROOT)/make/k3s.mk
include $(REPO_ROOT)/make/argocd.mk
include $(REPO_ROOT)/make/hosts.mk
include $(REPO_ROOT)/make/cleanup.mk
