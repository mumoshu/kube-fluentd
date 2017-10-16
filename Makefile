KUBE_FLUENTD_VERSION ?= 0.9.11
FLUENTD_VERSION ?= 0.14.14

REPOSITORY ?= cwsakamoto/kube-fluentd
TAG ?= $(FLUENTD_VERSION)-$(KUBE_FLUENTD_VERSION)
IMAGE ?= $(REPOSITORY):$(TAG)
ALIAS ?= $(REPOSITORY):$(FLUENTD_VERSION)

BUILD_ROOT ?= build/$(TAG)
DOCKERFILE ?= $(BUILD_ROOT)/Dockerfile
ROOTFS ?= $(BUILD_ROOT)/rootfs
DOCKER_CACHE ?= docker-cache
SAVED_IMAGE ?= $(DOCKER_CACHE)/image-$(FLUENTD_VERSION).tar

.PHONY: build
build: $(DOCKERFILE) $(ROOTFS)
	./build-confd
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

$(BUILD_ROOT):
	mkdir -p $(BUILD_ROOT)

travis-env:
	travis env set DOCKER_EMAIL $(DOCKER_EMAIL)
	travis env set DOCKER_USERNAME $(DOCKER_USERNAME)
	travis env set DOCKER_PASSWORD $(DOCKER_PASSWORD)

test: build
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
	  --privileged \
	  -v /mnt/sda1:/mnt/sda1 \
	  -v /var/lib/docker/containers:/var/lib/docker/containers \
	  -v /var/log:/var/log \
	  -e GOOGLE_FLUENTD_PRIVATE_KEY_ID="$(GOOGLE_FLUENTD_PRIVATE_KEY_ID)" \
	  -e GOOGLE_FLUENTD_PRIVATE_KEY="$(GOOGLE_FLUENTD_PRIVATE_KEY)" \
	  -e GOOGLE_FLUENTD_PROJECT_ID="$(GOOGLE_FLUENTD_PROJECT_ID)" \
	  -e GOOGLE_FLUENTD_CLIENT_EMAIL="$(GOOGLE_FLUENTD_CLIENT_EMAIL)" \
	  -e GOOGLE_FLUENTD_CLIENT_ID="$(GOOGLE_FLUENTD_CLIENT_ID)" \
	  -e GOOGLE_FLUENTD_CLIENT_X509_CERT_URL="$(GOOGLE_FLUENTD_CLIENT_X509_CERT_URL)" \
	  -e FLUENTD_OUT_KUBESYS_BUFFER_CHUNK_LIMIT="$(FLUENTD_OUT_KUBESYS_BUFFER_CHUNK_LIMIT)" \
	  -e FLUENTD_OUT_KUBESYS_BUFFER_QUEUE_LIMIT="$(FLUENTD_OUT_KUBESYS_BUFFER_QUEUE_LIMIT)" \
	  -e FLUENTD_OUT_KUBESYS_NUM_THREADS="$(FLUENTD_OUT_KUBESYS_NUM_THREADS)" \
	  -e FLUENTD_OUT_KUBESYS_BUFFER_FLUSH_INTERVAL="$(FLUENTD_OUT_KUBESYS_BUFFER_FLUSH_INTERVAL)" \
	  -e FLUENTD_OUT_KUBESYS_RETRY_LIMIT_DISABLE="$(FLUENTD_OUT_KUBESYS_RETRY_LIMIT_DISABLE)" \
	  -e FLUENTD_OUT_KUBESYS_RETRY_LIMIT="$(FLUENTD_OUT_KUBESYS_RETRY_LIMIT)" \
	  -e FLUENTD_OUT_KUBEUSER_BUFFER_CHUNK_LIMIT="$(FLUENTD_OUT_KUBEUSER_BUFFER_CHUNK_LIMIT)" \
	  -e FLUENTD_OUT_KUBEUSER_BUFFER_QUEUE_LIMIT="$(FLUENTD_OUT_KUBEUSER_BUFFER_QUEUE_LIMIT)" \
	  -e FLUENTD_OUT_KUBEUSER_NUM_THREADS="$(FLUENTD_OUT_KUBEUSER_NUM_THREADS)" \
	  -e FLUENTD_OUT_KUBEUSER_BUFFER_FLUSH_INTERVAL="$(FLUENTD_OUT_KUBEUSER_BUFFER_FLUSH_INTERVAL)" \
	  -e FLUENTD_OUT_KUBEUSER_RETRY_LIMIT_DISABLE="$(FLUENTD_OUT_KUBEUSER_RETRY_LIMIT_DISABLE)" \
	  -e FLUENTD_OUT_KUBEUSER_RETRY_LIMIT="$(FLUENTD_OUT_KUBEUSER_RETRY_LIMIT)" \
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
