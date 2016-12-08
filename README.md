# kube-fluentd

[![Build Status](https://travis-ci.org/mumoshu/kube-fluentd.svg?branch=master)](https://travis-ci.org/mumoshu/kube-fluentd)

[Docker Hub](https://hub.docker.com/r/mumoshu/kube-fluentd)

A docker image for running fluentd in Kubernetes pods.

Based on:

* [gcr.io/google_containers/ubuntu-slim](https://console.cloud.google.com/kubernetes/images/tags/ubuntu-slim?location=GLOBAL&project=google-containers)
* [Fluentd](https://github.com/fluent/fluentd)
* [s6-overlay](https://github.com/just-containers/s6-overlay)
* [confd](https://github.com/kelseyhightower/confd)
* [go-dnsmasq](https://github.com/janeczku/go-dnsmasq)

## Supported tags

 * `latest`/`0.14.2-0.9.2` (Fluentd v0.14.2)

Naming convention for images is `$FLUENTD_VERSION`-`$KUBE_FLUENTD_VERSION`

## Changelog

* `0.9.2`
  * I had fixed the wrong part of fluent.conf in 0.9.1. Now I've done it right.
  * Bump Fluentd to 0.14.2 to fix [the issue reported in the metadata filter repo](https://github.com/fabric8io/fluent-plugin-kubernetes_metadata_filter/issues/33#issuecomment-238377746)
* `0.9.1`
  * Use multiple threads for processing as per [a change in GoogleCloudPlatform/google-fluentd](https://github.com/GoogleCloudPlatform/google-fluentd/commit/283eb7052d3a256078f37d03e8ea3a496794a28f)

## Usage in Kubernetes

```
# (1) Provide GOOGLE_FLEUNTD_* environments appropriate values
# (2) Build the definition for a k8s secret object
$ make fluentd.secret.yaml
# (3) Create the secret object from the definition
$ kubectl create -f fluentd.secret.yaml
# (4) Create a fluentd daemonset that reads and depends on the secret
$ kubectl create -f fluentd.daemonset.yaml
```
