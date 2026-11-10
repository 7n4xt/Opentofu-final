resource "azurerm_public_ip" "jumpbox" {
  name                = "pip-nimbus-${var.binome}-jumpbox"
  location            = azurerm_resource_group.rg_nimbus.location
  resource_group_name = azurerm_resource_group.rg_nimbus.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = azurerm_resource_group.rg_nimbus.tags
}

resource "azurerm_network_interface" "jumpbox" {
  name                = "nic-nimbus-${var.binome}-jumpbox"
  location            = azurerm_resource_group.rg_nimbus.location
  resource_group_name = azurerm_resource_group.rg_nimbus.name
  tags                = azurerm_resource_group.rg_nimbus.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.admin.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jumpbox.id
  }
}

resource "azurerm_linux_virtual_machine" "jumpbox" {
  depends_on = [azurerm_subnet_network_security_group_association.admin]

  name                            = "vm-nimbus-${var.binome}-jumpbox"
  resource_group_name             = azurerm_resource_group.rg_nimbus.name
  location                        = azurerm_resource_group.rg_nimbus.location
  size                            = var.taille_vm
  admin_username                  = var.admin_username
  network_interface_ids           = [azurerm_network_interface.jumpbox.id]
  disable_password_authentication = true
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
