ARG ENVOY_VERSION
ARG CONSUL_VERSION

FROM envoyproxy/envoy:v${ENVOY_VERSION} as envoy-bin

FROM hashicorp/consul-enterprise:${CONSUL_VERSION} 

COPY --from=envoy-bin /usr/local/bin/envoy /bin/envoy

