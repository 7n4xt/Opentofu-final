# Define providers, resources, and modules here.
resource "azurerm_resource_group" "rg_nimbus" {
  name     = "rg-nimbus-${var.binome}"
  location = var.region
  tags = {
    cpu    = "virtualisation"
    owner  = var.binome
    projet = var.projet
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-nimbus-${var.binome}"
  address_space       = ["10.${var.binome}.0.0/16"]
  location            = azurerm_resource_group.rg_nimbus.location
  resource_group_name = azurerm_resource_group.rg_nimbus.name
}

resource "azurerm_subnet" "web" {
  name                 = "snet-web-${var.binome}"
  resource_group_name  = azurerm_resource_group.rg_nimbus.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.${var.binome}.1.0/24"]
}

resource "azurerm_subnet" "admin" {
  name                 = "snet-admin-${var.binome}"
  resource_group_name  = azurerm_resource_group.rg_nimbus.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.${var.binome}.2.0/24"]
}


resource "azurerm_network_security_group" "web" {
  name                = "nsg-web-${var.binome}"
  location            = azurerm_resource_group.rg_nimbus.location
  resource_group_name = azurerm_resource_group.rg_nimbus.name
  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}

