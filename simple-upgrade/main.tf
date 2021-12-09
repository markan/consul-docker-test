resource "docker_network" "consul_network" {
   name = "consul-simple-net"
   check_duplicate = "true"
   driver = "bridge"
   options = {
      "com.docker.network.bridge.enable_icc" = "true"
      "com.docker.network.bridge.enable_ip_masquerade" = "true"
   }
   internal = false
}

variable "consul_image" {
   type = string
   default = "hashicorp/consul-enterprise:1.8-ent"
   description = "Name of the Consul container image to use"
}

resource "docker_image" "consul_base" {
   name = "hashicorp/consul-enterprise:1.8-ent"
   keep_locally = true
}

resource "docker_image" "consul_upgrade" {
   name = "hashicorp/consul-enterprise:1.11.0-ent-rc"
   keep_locally = true
}

module "primary_servers" {
   source = "../modules/servers"

   persistent_data = true
   datacenter = "primary"
   default_networks = [docker_network.consul_network.name]
   default_image = docker_image.consul_base.latest
   default_name_prefix="consul-upgrade-server-"

   default_config = {
     "agent-conf.hcl" = file("agent-conf.hcl")
     "license.hclic" = file("../../license.hclic")
   }
  
   # 3 servers all with defaults
  servers = [
    {
    image = docker_image.consul_upgrade.latest
    },
    {},
    {}]
}

module "primary_clients" {
   source = "../modules/clients"

   persistent_data = true
   datacenter = "primary"
   default_networks = [docker_network.consul_network.name]
   default_image = docker_image.consul_base.latest
   extra_args = module.primary_servers.join

   default_config = {
     "agent-conf.hcl" = file("agent-conf.hcl")
     "license.hclic" = file("../../license.hclic")
   }
  
   clients = [
      {
         "name" : "consul-simple-ui"
         "extra_args": ["-ui"],
         "ports": {
            "http": {
               "internal": 8500,
               "external": 8500,
               "protocol": "tcp",
            },
            "dns": {
               "internal": 8600,
               "external": 8600,
               "protocol": "udp",
            },
         }
      },
        {
	  "name" : "consul-counting",
	  "client_commands" : "touch /tigger",
	}
   ]
}
