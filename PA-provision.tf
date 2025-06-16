# Terraform IaC for Prisma Access (Full stack: RN, MU, SC, DNS/Proxy/Logging)

terraform {
  required_providers {
    prismaaccess = {
      source  = "PaloAltoNetworks/prismaaccess"
      version = ">= 1.0.0"
    }
  }
}

provider "prismaaccess" {
  client_id     = var.client_id
  client_secret = var.client_secret
  base_url      = "https://api.prismaaccess.paloaltonetworks.com"
}

###########################
# 1. Remote Network Site #
###########################
resource "prismaaccess_remote_network" "seoul_branch" {
  name              = "remote-network-seoul"
  location          = "South Korea"
  ipsec_tunnel {
    primary {
      ip_address      = "203.0.113.1"
      pre_shared_key  = var.psk
    }
  }
  bandwidth_mbps    = 100
  bgp_enabled       = false
}

#############################
# 2. Mobile User Configuration #
#############################
resource "prismaaccess_mobile_users" "global_mus" {
  region            = "apac"
  authentication {
    method          = "SAML"
    profile_name    = "saml-profile"
  }
  location          = "South Korea"
  public_ip_pool    = ["198.51.100.0/24"]
  ip_pool           = ["10.20.0.0/16"]
  dns {
    primary         = "8.8.8.8"
    secondary       = "1.1.1.1"
  }
}

#################################
# 3. Service Connection (DC VPN) #
#################################
resource "prismaaccess_service_connection" "seoul_dc" {
  name              = "service-connection-seoul"
  location          = "South Korea"
  ipsec_tunnel {
    primary {
      ip_address     = "198.51.100.2"
      pre_shared_key = var.psk
    }
  }
  bgp_enabled       = true
  bgp_peer_ip       = "10.255.255.1"
  bgp_peer_asn      = 65001
  local_asn         = 65000
}

######################
# 4. DNS & Proxy Set #
######################
resource "prismaaccess_dns_settings" "default" {
  primary_dns   = "8.8.8.8"
  secondary_dns = "1.1.1.1"
}

resource "prismaaccess_proxy_settings" "default" {
  enable_proxy = true
  proxy_url    = "http://proxy.example.com"
}

##################################
# 5. Logging Configuration (CDL) #
##################################
resource "prismaaccess_logging_settings" "default" {
  log_forwarding_profile = "default-log-profile"
  enable_logging_service = true
}

#################
# Input Variables
#################
variable "client_id" {}
variable "client_secret" {}
variable "psk" {}
