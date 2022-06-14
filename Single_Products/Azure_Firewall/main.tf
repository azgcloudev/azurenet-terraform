terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Resource group
resource "azurerm_resource_group" "default_resource_group" {
  name     = "rg-firewall-263165"
  location = "East US"
  tags = {
    deployedBy = "terraform"
  }
}

# Virtual Network and Subnet 
resource "azurerm_virtual_network" "fw_vnet" {
  name                = "Firewall-Vnet"
  address_space       = ["10.130.0.0/16"]
  location            = azurerm_resource_group.default_resource_group.location
  resource_group_name = azurerm_resource_group.default_resource_group.name
}

resource "azurerm_subnet" "fw_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.default_resource_group.name
  virtual_network_name = azurerm_virtual_network.fw_vnet.name
  address_prefixes     = ["10.130.1.0/24"]
}

# Public IP
resource "azurerm_public_ip" "fw_pip_01" {
  name                = "pip-firewall_tf_01"
  location            = azurerm_resource_group.default_resource_group.location
  resource_group_name = azurerm_resource_group.default_resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
}


# Firewall policy
resource "azurerm_firewall_policy" "fw_default_policy" {
  name                = "policy-firewall-01"
  resource_group_name = azurerm_resource_group.default_resource_group.name
  location            = azurerm_resource_group.default_resource_group.location
}

resource "azurerm_firewall_policy_rule_collection_group" "fw_pol_rcg" {
    name = "default-rule-rcg"
    firewall_policy_id = azurerm_firewall_policy.fw_default_policy.id
    priority = 500

    network_rule_collection {
    name     = "network_rule_collection1"
    priority = 1000
    action   = "Allow"
    rule {
      name                  = "Allow all L3 traffic"
      protocols             = ["TCP", "UDP"]
      source_addresses      = ["*"]
      destination_addresses = ["*"]
      destination_ports     = ["*"]
    }
  }
}



# Firewall
resource "azurerm_firewall" "firewall01" {
  name                = "fw-testing-01"
  resource_group_name = azurerm_resource_group.default_resource_group.name
  location            = azurerm_resource_group.default_resource_group.location
  sku_name            = "AZFW_VNet"
  sku_tier            = var.fw_tier
  firewall_policy_id = azurerm_firewall_policy.fw_default_policy.id
  tags = {
    deployedBy = "terraform"
  }

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.fw_subnet.id
    public_ip_address_id = azurerm_public_ip.fw_pip_01.id
  }
}
