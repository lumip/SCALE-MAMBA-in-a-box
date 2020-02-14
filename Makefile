VERSION = 1.7
BUILD = 0-ubuntu
TAG = $(VERSION).$(BUILD)

IMAGE = lumip/scale-mamba

.PHONY: build
build: build-latest

.PHONY: upload
upload: upload-version upload-major upload-latest

.PHONY: test-build
test-build:
	- docker build -t $(IMAGE):$(TAG) .

.PHONY: build-version
build-version:
	- docker build -t $(IMAGE):$(TAG) .
	- docker build --target quickstart-bundle --build-arg PARTIES=2 -t $(IMAGE):$(TAG)-quickstart-2 .
	- docker build --target quickstart-bundle --build-arg PARTIES=3 -t $(IMAGE):$(TAG)-quickstart-3 .
	- docker build --target quickstart-bundle --build-arg PARTIES=4 -t $(IMAGE):$(TAG)-quickstart-4 .
	- docker build --target quickstart-bundle --build-arg PARTIES=5 -t $(IMAGE):$(TAG)-quickstart-5 .
	- docker tag $(IMAGE):$(TAG)-quickstart-2 $(IMAGE):$(TAG)-quickstart

.PHONY: upload-version
upload-version:
	- docker push $(IMAGE):$(TAG)
	- docker push $(IMAGE):$(TAG)-quickstart-2
	- docker push $(IMAGE):$(TAG)-quickstart-3
	- docker push $(IMAGE):$(TAG)-quickstart-4
	- docker push $(IMAGE):$(TAG)-quickstart-5
	- docker push $(IMAGE):$(TAG)-quickstart

.PHONY: build-major
build-major: build-version
	- docker tag $(IMAGE):$(TAG) $(IMAGE):$(VERSION)
	- docker tag $(IMAGE):$(TAG)-quickstart-2 $(IMAGE):$(VERSION)-quickstart-2
	- docker tag $(IMAGE):$(TAG)-quickstart-3 $(IMAGE):$(VERSION)-quickstart-3
	- docker tag $(IMAGE):$(TAG)-quickstart-4 $(IMAGE):$(VERSION)-quickstart-4
	- docker tag $(IMAGE):$(TAG)-quickstart-5 $(IMAGE):$(VERSION)-quickstart-5
	- docker tag $(IMAGE):$(TAG)-quickstart $(IMAGE):$(VERSION)-quickstart

.PHONY: upload-major
upload-major:
	- docker push $(IMAGE):$(VERSION)
	- docker push $(IMAGE):$(VERSION)-quickstart-2
	- docker push $(IMAGE):$(VERSION)-quickstart-3
	- docker push $(IMAGE):$(VERSION)-quickstart-4
	- docker push $(IMAGE):$(VERSION)-quickstart-5
	- docker push $(IMAGE):$(VERSION)-quickstart

.PHONY: build-latest
build-latest: build-major
	- docker tag $(IMAGE):$(TAG) $(IMAGE):latest
	- docker tag $(IMAGE):$(TAG)-quickstart-2 $(IMAGE):quickstart-2
	- docker tag $(IMAGE):$(TAG)-quickstart-3 $(IMAGE):quickstart-3
	- docker tag $(IMAGE):$(TAG)-quickstart-4 $(IMAGE):quickstart-4
	- docker tag $(IMAGE):$(TAG)-quickstart-5 $(IMAGE):quickstart-5
	- docker tag $(IMAGE):$(TAG)-quickstart $(IMAGE):quickstart

.PHONY: upload-latest
upload-latest:
	- docker push $(IMAGE):latest
	- docker push $(IMAGE):quickstart-2
	- docker push $(IMAGE):quickstart-3
	- docker push $(IMAGE):quickstart-4
	- docker push $(IMAGE):quickstart-5
	- docker push $(IMAGE):quickstart
	
