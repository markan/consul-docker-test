CONSUL_HTTP_TOKEN=df87bdaa-b277-42d5-9b40-98d5d0fba61f

mkdir /count && cd /count

# Download sample data layer service, Counting service
wget https://github.com/hashicorp/demo-consul-101/releases/download/0.0.3.1/counting-service_linux_amd64.zip
# Unzip Counting service
unzip counting-service_linux_amd64.zip
# Start Counting service as background process in container
./counting-service_linux_amd64 &
# Start Consul Sidecar Proxy for Counting service
consul connect proxy -sidecar-for counting-1 -token $CONSUL_HTTP_TOKEN &


