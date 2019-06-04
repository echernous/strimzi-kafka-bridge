# Makefile.docker contains the shared tasks for building, tagging and pushing Docker images.
# This file is included into the Makefile files which contain the Dockerfile files (E.g.
# kafka-base, kafka etc.).
#
# The DOCKER_ORG (default is name of the current user) and DOCKER_TAG (based on Git Tag,
# default latest) variables are used to name the Docker image. DOCKER_REGISTRY identifies
# the registry where the image will be pushed (default is Docker Hub).
TOPDIR=$(dir $(lastword $(MAKEFILE_LIST)))
DOCKERFILE_DIR     ?= ./
DOCKER_REGISTRY    ?= docker.io
DOCKER_ORG         ?= $(USER)
DOCKER_TAG         ?= latest
BUILD_TAG          ?= latest
RELEASE_VERSION    ?= $(shell cat $(TOPDIR)/release.version)


.PHONY: docker_build
docker_build: .docker_build

.docker_build: target/kafka-bridge-$(RELEASE_VERSION).zip
	# Build Docker image ...
	$(DOCKER) build $(DOCKER_BUILD_ARGS) --build-arg strimzi_kafka_bridge_version=$(RELEASE_VERSION) -t strimzi/$(PROJECT_NAME):latest $(DOCKERFILE_DIR)
#   The Dockerfiles all use FROM ...:latest, so it is necessary to tag images with latest (-t above)
#   But because we generate Kafka images for different versions we also need to tag with something
#   including the kafka version number. This BUILD_TAG is used by the docker_tag target.
	# Also tag with $(BUILD_TAG)
	$(DOCKER) tag strimzi/$(PROJECT_NAME):latest strimzi/$(PROJECT_NAME):$(BUILD_TAG)
	touch .docker_build

.PHONY: docker_tag
docker_tag: .docker_tag

.docker_tag: .docker_build
	# Tag the $(BUILD_TAG) image we built with the given $(DOCKER_TAG) tag
	$(DOCKER) tag strimzi/$(PROJECT_NAME):$(BUILD_TAG) $(DOCKER_REGISTRY)/$(DOCKER_ORG)/$(PROJECT_NAME):$(DOCKER_TAG)
	touch .docker_tag

.PHONY: docker_push
docker_push: docker_tag
	# Push the $(DOCKER_TAG)-tagged image to the registry
	$(DOCKER) push $(DOCKER_REGISTRY)/$(DOCKER_ORG)/$(PROJECT_NAME):$(DOCKER_TAG)