# Define providers, resources, and modules here.
resource "azurerm_resource_group" "rg_nimbus" {
  name     = "rg-nimbus-${var.binome}"
  location = var.region
  tags = {
    env    = var.env
    owner  = var.binome
    projet = var.projet
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-nimbus-${var.binome}"
  address_space       = ["10.${var.numgroupe}.0.0/16"]
  location            = azurerm_resource_group.rg_nimbus.location
  resource_group_name = azurerm_resource_group.rg_nimbus.name
  tags                = azurerm_resource_group.rg_nimbus.tags
}

resource "azurerm_subnet" "web" {
  name                 = "snet-nimbus-${var.binome}-web"
  resource_group_name  = azurerm_resource_group.rg_nimbus.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.${var.numgroupe}.1.0/24"]
}

resource "azurerm_subnet" "admin" {
  name                 = "snet-nimbus-${var.binome}-admin"
  resource_group_name  = azurerm_resource_group.rg_nimbus.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.${var.numgroupe}.2.0/24"]
}


resource "azurerm_network_security_group" "web" {
  name                = "nsg-nimbus-${var.binome}-web"
  location            = azurerm_resource_group.rg_nimbus.location
  resource_group_name = azurerm_resource_group.rg_nimbus.name
  tags                = azurerm_resource_group.rg_nimbus.tags
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
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  count                           = 2
  name                            = "vm-nimbus-${var.binome}-${count.index + 1}"
  resource_group_name             = azurerm_resource_group.rg_nimbus.name
  location                        = azurerm_resource_group.rg_nimbus.location
  size                            = var.taille_vm
  admin_username                  = var.admin_username
  network_interface_ids           = [azurerm_network_interface.web[count.index].id]
  disable_password_authentication = true
  custom_data                     = filebase64("${path.module}/cloud-init.yaml")
  tags                            = azurerm_resource_group.rg_nimbus.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(pathexpand(var.ssh_public_key_path))
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

resource "azurerm_network_interface" "web" {
  count               = 2
  name                = "nic-nimbus-${var.binome}-web-${count.index + 1}"
  location            = azurerm_resource_group.rg_nimbus.location
  resource_group_name = azurerm_resource_group.rg_nimbus.name
  tags                = azurerm_resource_group.rg_nimbus.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
  }
}
