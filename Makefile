SHELL := /bin/bash

CLANG_VERSION := 13
CMAKE_VERSION := 3.20.5

NAMESPACE := invasy
IMAGE := clang-remote
CONTAINER := clang_remote
PORT := 22001

tag := $(NAMESPACE)/$(IMAGE):$(CLANG_VERSION)-cmake-$(CMAKE_VERSION)
latest := $(NAMESPACE)/$(IMAGE):latest

.PHONY: all build run push pull up down
all: up

build: Dockerfile
	@docker build \
		--build-arg=CLANG_VERSION=$(CLANG_VERSION) \
		--build-arg=CMAKE_VERSION=$(CMAKE_VERSION) \
		--tag "$(tag)" --tag "$(latest)" .

run: build
	@docker run --detach --cap-add=sys_ptrace --name="$(CONTAINER)" \
		--publish="127.0.0.1:$(PORT):22" --restart=unless-stopped "$(latest)"

push: build
	@docker image push "$(tag)" && \
	docker image push "$(latest)"

pull:
	@docker image pull "$(latest)"

up: docker-compose.yml
	@docker-compose up -d

down: docker-compose.yml
	@docker-compose down
