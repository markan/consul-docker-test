mkdir /dashboard && cd /dashboard

# Download sample data layer service, Dashboard service
wget https://github.com/hashicorp/demo-consul-101/releases/download/0.0.3.1/dashboard-service_linux_amd64.zip
# Unzip Counting service
unzip dashboard-service_linux_amd64.zip

# Start Dashboard service as background process in container
./dashboard-service_linux_amd64 &

# Start Consul Sidecar Proxy for Dashboard service
consul connect proxy -sidecar-for dashboard -token $CONSUL_HTTP_TOKEN &
