KUBE_FLUENTD_VERSION ?= 0.9.3
FLUENTD_VERSION ?= 0.14.9

REPOSITORY ?= mumoshu/kube-fluentd
TAG ?= $(FLUENTD_VERSION)-$(KUBE_FLUENTD_VERSION)
IMAGE ?= $(REPOSITORY):$(TAG)
ALIAS ?= $(REPOSITORY):$(FLUENTD_VERSION)

BUILD_ROOT ?= build/$(TAG)
DOCKERFILE ?= $(BUILD_ROOT)/Dockerfile
ROOTFS ?= $(BUILD_ROOT)/rootfs
FLUENT_CONF ?= $(BUILD_ROOT)/fluent.conf
DOCKER_CACHE ?= docker-cache
SAVED_IMAGE ?= $(DOCKER_CACHE)/image-$(FLUENTD_VERSION).tar

.PHONY: build
build: $(DOCKERFILE) $(ROOTFS) $(FLUENT_CONF)
	cd $(BUILD_ROOT) && docker build -t $(IMAGE) . && docker tag $(IMAGE) $(ALIAS)

.PHONY: clean
clean:
	rm -rf $(BUILD_ROOT)

publish:
	docker push $(IMAGE) && docker push $(ALIAS)

$(DOCKERFILE): $(BUILD_ROOT)
	sed 's/%%FLUENTD_VERSION%%/'"$(FLUENTD_VERSION)"'/g;' Dockerfile.template > $(DOCKERFILE)

$(ROOTFS): $(BUILD_ROOT)
	cp -R rootfs $(ROOTFS)

$(FLUENT_CONF): $(BUILD_ROOT)
	cp fluent.conf $(FLUENT_CONF)

$(BUILD_ROOT):
	mkdir -p $(BUILD_ROOT)

travis-env:
	travis env set DOCKER_EMAIL $(DOCKER_EMAIL)
	travis env set DOCKER_USERNAME $(DOCKER_USERNAME)
	travis env set DOCKER_PASSWORD $(DOCKER_PASSWORD)

test:
	@echo There are no tests available for now. Skipping

save-docker-cache: $(DOCKER_CACHE)
	docker save $(IMAGE) $(shell docker history -q $(IMAGE) | tail -n +2 | grep -v \<missing\> | tr '\n' ' ') > $(SAVED_IMAGE)
	ls -lah $(DOCKER_CACHE)

load-docker-cache: $(DOCKER_CACHE)
	if [ -e $(SAVED_IMAGE) ]; then docker load < $(SAVED_IMAGE); fi

$(DOCKER_CACHE):
	mkdir -p $(DOCKER_CACHE)

docker-run: DOCKER_CMD ?=
docker-run:
	docker run --rm -it \
	  -e GOOGLE_FLUENTD_PRIVATE_KEY_ID="$(GOOGLE_FLUENTD_PRIVATE_KEY_ID)" \
	  -e GOOGLE_FLUENTD_PRIVATE_KEY="$(GOOGLE_FLUENTD_PRIVATE_KEY)" \
	  -e GOOGLE_FLUENTD_PROJECT_ID="$(GOOGLE_FLUENTD_PROJECT_ID)" \
	  -e GOOGLE_FLUENTD_CLIENT_EMAIL="$(GOOGLE_FLUENTD_CLIENT_EMAIL)" \
	  -e GOOGLE_FLUENTD_CLIENT_ID="$(GOOGLE_FLUENTD_CLIENT_ID)" \
	  -e GOOGLE_FLUENTD_CLIENT_X509_CERT_URL="$(GOOGLE_FLUENTD_CLIENT_X509_CERT_URL)" \
	$(IMAGE) $(DOCKER_CMD)

define SECRET_YAML
apiVersion: v1
kind: Secret
metadata:
  name: fluentd
type: Opaque
data:
  private.key.id: $(shell bash -c 'echo -n "$$GOOGLE_FLUENTD_PRIVATE_KEY_ID" | base64')
  private.key: $(shell bash -c 'echo -n "$$GOOGLE_FLUENTD_PRIVATE_KEY" | base64')
  project.id: $(shell bash -c 'echo -n "$$GOOGLE_FLUENTD_PROJECT_ID" | base64')
  client.email: $(shell bash -c 'echo -n "$$GOOGLE_FLUENTD_CLIENT_EMAIL" | base64')
  client.id: $(shell bash -c 'echo -n "$$GOOGLE_FLUENTD_CLIENT_ID" | base64')
  client.x509.cert.url: $(shell bash -c 'echo -n "$$GOOGLE_FLUENTD_CLIENT_X509_CERT_URL" | base64')
endef
export SECRET_YAML

fluentd.secret.yaml:
	echo "$$SECRET_YAML" > fluentd.secret.yaml
