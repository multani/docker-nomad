DOCKER_TAG = local/nomad
DIR = latest
DOCKERFILE = $(DIR)/Dockerfile

.PHONY: all
all: build

.PHONY: build
build:
	docker buildx build --file $(DOCKERFILE) --tag "$(DOCKER_TAG)" $(DIR)

test:
	docker run --rm "$(DOCKER_TAG)" version
	docker run --rm "$(DOCKER_TAG)" agent -help
