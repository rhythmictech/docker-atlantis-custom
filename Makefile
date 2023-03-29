
IMAGE = rhythmictech/docker-atlantis-custom:dirty

.PHONY: build
build:
	docker build . -t $(IMAGE)
