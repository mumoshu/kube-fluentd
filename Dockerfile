FROM alpine:3.4
MAINTAINER Yusuke KUOKA <ykuoka@gmail.com>

ENV S6_OVERLAY_VERSION=v1.17.2.0

RUN apk add --update --no-cache wget \
 && wget https://github.com/just-containers/s6-overlay/releases/download/v1.17.1.1/s6-overlay-amd64.tar.gz --no-check-certificate -O /tmp/s6-overlay.tar.gz \
 && tar xvfz /tmp/s6-overlay.tar.gz -C / \
 && rm -f /tmp/s6-overlay.tar.gz \
 && apk del wget

# Until confd package arrives to Alpine packages, build it ourselves:
# Installation process inspired by: https://github.com/smebberson/docker-alpine/blob/master/alpine-confd/Dockerfile
ENV CONFD_VERSION=0.11.0

RUN apk add --no-cache go git gcc musl-dev && \
    git clone https://github.com/kelseyhightower/confd.git /src/confd && \
    cd /src/confd && \
    git checkout -q --detach "v$CONFD_VERSION" && \
    cd /src/confd/src/github.com/kelseyhightower/confd && \
    GOPATH=/src/confd/vendor:/src/confd go build -a -installsuffix cgo -ldflags '-extld ld -extldflags -static' -x . && \
    mv ./confd /bin/ && \
    chmod +x /bin/confd && \
    apk del go git gcc musl-dev && \
    rm -rf /src

# Use https://github.com/janeczku/go-dnsmasq to support `search` directive or etc in /etc/resolve.conf
# Installation process inspired by: https://github.com/janeczku/docker-alpine-kubernetes/blob/master/versions/3.3/Dockerfile
ENV GODNSMASQ_VERSION=1.0.6

RUN apk add --no-cache curl && \
    curl -sSL https://github.com/janeczku/go-dnsmasq/releases/download/${GODNSMASQ_VERSION}/go-dnsmasq-min_linux-amd64 -o /bin/go-dnsmasq && \
    chmod +x /bin/go-dnsmasq && \
    apk del curl

# Directs output from go-dnsmasq to:
ENV GO_DNSMASQ_LOG_FILE /dev/stdout

ENV FLUENTD_VERSION 0.14.1

# Do not split this into multiple RUN!
# Docker creates a layer for every RUN-Statement
# therefore an 'apk delete build*' has no effect
RUN apk --no-cache --update add \
                            build-base \
                            ca-certificates \
                            ruby \
                            ruby-irb \
                            ruby-dev && \
    echo 'gem: --no-document' >> /etc/gemrc && \
    gem install oj && \
    gem install fluentd -v $FLUENTD_VERSION && \
    # We install fluent plugins here because doing so requires build-base and ruby-dev in order to build native extensions
    gem install fluent-plugin-google-cloud && \
    gem install fluent-plugin-kubernetes_metadata_filter && \
    gem install fluent-plugin-record-reformer && \
    apk del build-base ruby-dev && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

RUN adduser -D -g '' -u 1000 -h /home/fluent fluent
RUN chown -R fluent:fluent /home/fluent

# for log storage (maybe shared with host)
RUN mkdir -p /fluentd/log
# configuration/plugins path (default: copied from .)
RUN mkdir -p /fluentd/etc /fluentd/plugins

RUN chown -R fluent:fluent /fluentd

USER fluent
WORKDIR /home/fluent

# Tell ruby to install packages as user
RUN echo "gem: --user-install --no-document" >> ~/.gemrc
ENV PATH /home/fluent/.gem/ruby/2.3.0/bin:$PATH
ENV GEM_PATH /home/fluent/.gem/ruby/2.3.0:$GEM_PATH

USER root
WORKDIR /

COPY rootfs /

COPY fluent.conf /fluentd/etc/

RUN sed -i -e 's/type/@type/g' /fluentd/etc/fluent.conf

ENV FLUENTD_OPT=""
ENV FLUENTD_CONF="fluent.conf"

EXPOSE 24224 5140

ENTRYPOINT [ "/init" ]

CMD /bin/s6-envuidgid fluent fluentd -c /fluentd/etc/$FLUENTD_CONF -p /fluentd/plugins $FLUENTD_OPT
