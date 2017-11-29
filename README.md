# kube-fluentd

[![Build Status](https://travis-ci.org/mumoshu/kube-fluentd.svg?branch=master)](https://travis-ci.org/mumoshu/kube-fluentd)

[Docker Hub](https://hub.docker.com/r/mumoshu/kube-fluentd)

A docker image for running fluentd in Kubernetes pods.

Based on:

* [gcr.io/google_containers/ubuntu-slim](https://console.cloud.google.com/kubernetes/images/tags/ubuntu-slim?location=GLOBAL&project=google-containers)
* [Fluentd](https://github.com/fluent/fluentd)
* [s6-overlay](https://github.com/just-containers/s6-overlay)
* [confd](https://github.com/kelseyhightower/confd)

## Supported tags

 * `latest`/`0.14.22-0.9.9` (Fluentd v0.14.22)

Naming convention for images is `$FLUENTD_VERSION`-`$KUBE_FLUENTD_VERSION`

## Changelog

* `0.9.10-rc.1`
  * Bump Fluentd to 0.14.22
  * Support for credentials from volume mounts (See `fluentd.daemonset.credfromfile.yaml`)
* `0.9.9`
  * Bump Fluentd to 0.14.14 to incorporate the fix for https://github.com/fluent/fluentd/issues/1485
* `0.9.8`
  * Set buffer_queue_full_action to `block` for tail plugins so that we won't drop messages anymore
* `0.9.7`
  * fluentd.conf is customizable via environment variables (#3, thanks to @cw-hayashi)
* `0.9.6`
  * Fix the fluentd OOM issue when ingesting a lot of log
    * Also see https://github.com/fluent/fluentd/issues/1260 for why we don't use `overflow_action block`
* `0.9.5`
  * Remove /var/lib/apt/lists/* to save approximately 20MB of image size
* `0.9.4`
  * Build confd outside of containers to save 1MB of image size
* `0.9.3`
  * Switch from alpine to ubuntu-slim:0.4
  * Use jemalloc
  * Fluentd 0.14.9
* `0.9.2`
  * I had fixed the wrong part of fluent.conf in 0.9.1. Now I've done it right.
  * Bump Fluentd to 0.14.2 to fix [the issue reported in the metadata filter repo](https://github.com/fabric8io/fluent-plugin-kubernetes_metadata_filter/issues/33#issuecomment-238377746)
* `0.9.1`
  * Use multiple threads for processing as per [a change in GoogleCloudPlatform/google-fluentd](https://github.com/GoogleCloudPlatform/google-fluentd/commit/283eb7052d3a256078f37d03e8ea3a496794a28f)

## Usage in Kubernetes

(1) Create a new GCP service account key in https://console.cloud.google.com/apis/credentials and obtain `${gcp_project_name}-${service_account_key_id}.json1`

(2) Run the following commands:

```
$ cp ${gcp_project_name}-${service_account_key_id}.json application_default_credentials.json
$ kubectl kubectl create secret generic kube-fluentd-google-application-default-credentials --from-file application_default_credentials.json --namespace kube-system
$ kubectl create -f fluentd.rbac.yaml
$ kubectl create -f fluentd.daemonset.credfromfile.yaml
```
