.DEFAULT_GOAL := help

include make/vars.mk
include make/help.mk
include make/k3s.mk
include make/gitlab.mk
include make/argocd.mk
include make/hosts.mk
include make/cleanup.mk
