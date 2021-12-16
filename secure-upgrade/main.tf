// some randomness so we can create two of these clusters at once if necessary
resource "random_string" "cluster_id" {
  length = 4
  special = false
  upper = false
}

locals {
   cluster_id = var.use_cluster_id ? "-${random_string.cluster_id.result}" : ""
   ca_key_pem = file(var.tls_ca_key_file)
   ca_cert_pem = file(var.tls_ca_cert_file)
}

resource "docker_network" "consul_network" {
   name = "consul-secure${local.cluster_id}"
   check_duplicate = "true"
   driver = "bridge"
   options = {
      "com.docker.network.bridge.enable_icc" = "true"
      "com.docker.network.bridge.enable_ip_masquerade" = "true"
   }
   internal = false
}

resource "docker_image" "consul_base" {
   name = "hashicorp/consul-enterprise:1.8-ent"
   keep_locally = true
}

resource "docker_image" "consul_upgrade" {
   name = "hashicorp/consul-enterprise:1.11.1-ent"
   keep_locally = true
}

# See utils/consul-envoy for how these images were created
resource "docker_image" "consul_envoy_base" {
   name = "local/consul-enterprise-envoy:1.8-ent"
   keep_locally = true
}

resource "docker_image" "consul_envoy_upgrade" {
   name = "local/consul-enterprise-envoy:1.11.1-ent"
   keep_locally = true
}


module "servers" {
   source = "../modules/servers"

   persistent_data = true
   datacenter = "primary"
  
   default_networks = [docker_network.consul_network.name]

   # change to consul_upgrade.name to upgrade
   default_image = docker_image.consul_base.latest

   default_config = {
     "agent-conf.hcl" = file("agent-conf.hcl")
     "license.hclic" = file("../../license.hclic")
   }
   default_name_include_dc = false
   default_name_prefix = "con-srv-secure-upgrade-"
   default_name_suffix = "${local.cluster_id}"
   enable_healthcheck = true
   
   tls_enabled = true
   tls_ca_cert = local.ca_cert_pem
   tls_ca_key = local.ca_key_pem
   tls_organization = var.tls_organization
   tls_organizational_unit = var.tls_organizational_unit
   tls_country = var.tls_country
   tls_province = var.tls_province
   tls_locality = var.tls_locality
   tls_street_address = var.tls_street_address
   tls_postal_code = var.tls_postal_code

   # 3 servers all with defaults
   servers = [
    {
    image = docker_image.consul_upgrade.latest
    },
    {},
    {}]
}

module "clients" {
   source = "../modules/clients"

   persistent_data = true

   datacenter = "primary"
  default_networks = [docker_network.consul_network.name]

  default_image = docker_image.consul_envoy_base.latest

  default_config = {
     "agent-conf.hcl" = file("client-conf.hcl")
     "license.hclic" = file("../../license.hclic")
   }
   extra_args = module.servers.join
   
   tls_enabled = true
   tls_ca_cert = local.ca_cert_pem
   tls_ca_key = local.ca_key_pem
   tls_organization = var.tls_organization
   tls_organizational_unit = var.tls_organizational_unit
   tls_country = var.tls_country
   tls_province = var.tls_province
   tls_locality = var.tls_locality
   tls_street_address = var.tls_street_address
   tls_postal_code = var.tls_postal_code
   
   clients = [
      {
         "name": "con-cli-secure-ui${local.cluster_id}",
         "extra_args": ["-ui"],
         "ports": {
            "http": {
               "internal": 8501,
               "external": 8501,
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
	  "name" : "con-cli-counting",
	  "script" : { "service_setup.sh" = "counting-service-setup.sh" }
	},
       {
	  "name" = "con-cli-dashboard",
	   image = docker_image.consul_envoy_base.latest
	  "script" = { "service_setup.sh" = "dashboard-service-setup.sh" }
	}
   ]
}
