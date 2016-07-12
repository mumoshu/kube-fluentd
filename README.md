# kube-fluentd

[![Build Status](https://travis-ci.org/mumoshu/kube-fluentd.svg?branch=master)](https://travis-ci.org/mumoshu/kube-fluentd)

[Docker Hub](https://hub.docker.com/r/mumoshu/kube-fluentd)

A docker image for running fluentd in Kubernetes pods.

Based on:

* Alpine Linux 3.4
* [Fluentd](https://github.com/fluent/fluentd)
* [s6-overlay](https://github.com/just-containers/s6-overlay)
* [confd](https://github.com/kelseyhightower/confd)
* [go-dnsmasq](https://github.com/janeczku/go-dnsmasq)

## Supported tags

 * `latest`/`0.14.1-0.9.0` (Fluentd v0.14.1)

Naming convention for images is `$FLUENTD_VERSION`-`$KUBE_FLUENTD_VERSION`
