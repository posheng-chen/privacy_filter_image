IMAGE_NAME=privacy_filter_image
IMAGE_TAG=0.0

.PHONY: build test clean clean-cache

build:
	docker build \
		--build-arg run_as_user=privacy_filter \
		--build-arg run_as_group=privacy_filter \
		-t $(IMAGE_NAME):$(IMAGE_TAG) .

test:
	echo "My email is alice@example.com and phone is 0912-345-678" | \
	docker run --rm -i $(IMAGE_NAME):$(IMAGE_TAG) \
		--device cpu --output-mode typed

clean:
	-docker image rm -f $(IMAGE_NAME):$(IMAGE_TAG)

clean-cache:
	docker builder prune -af
