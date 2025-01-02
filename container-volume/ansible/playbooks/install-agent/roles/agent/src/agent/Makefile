SHELL = /bin/bash

MODULE_NAME := "cmp-agent"
PROJECT_NAME := "${MODULE_NAME}"
PKG_LIST := $(shell go list ${PROJECT_NAME}/... 2>&1)

GOPROXY_OPTION := GOPROXY=direct GOSUMDB=off
GO_COMMAND := ${GOPROXY_OPTION} go
GOPATH := $(shell go env GOPATH)

.PHONY: all

all:
	@echo Building...
	@CGO_ENABLED=0 ${GO_COMMAND} build -o ${MODULE_NAME} main.go;
	@mv ${MODULE_NAME} ../../agent-install-files/bin/
	@echo Build finished!
