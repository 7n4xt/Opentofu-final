resource "azurerm_public_ip" "lb" {
  name                = "pip-nimbus-${var.binome}-lb"
  location            = azurerm_resource_group.rg_nimbus.location
  resource_group_name = azurerm_resource_group.rg_nimbus.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = azurerm_resource_group.rg_nimbus.tags
}

resource "azurerm_lb" "web" {
  name                = "lb-nimbus-${var.binome}"
  location            = azurerm_resource_group.rg_nimbus.location
  resource_group_name = azurerm_resource_group.rg_nimbus.name
  sku                 = "Standard"
  tags                = azurerm_resource_group.rg_nimbus.tags

  frontend_ip_configuration {
    name                 = "frontend-nimbus-${var.binome}"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "web" {
  name            = "pool-nimbus-${var.binome}-web"
  loadbalancer_id = azurerm_lb.web.id
}

resource "azurerm_network_interface_backend_address_pool_association" "web" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.web[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.web.id
}

resource "azurerm_lb_probe" "web" {
  name                = "probe-nimbus-${var.binome}-http"
  loadbalancer_id     = azurerm_lb.web.id
  protocol            = "Http"
  port                = 80
  request_path        = "/sante"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "http" {
  name                           = "rule-nimbus-${var.binome}-http"
  loadbalancer_id                = azurerm_lb.web.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = azurerm_lb.web.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web.id]
  probe_id                       = azurerm_lb_probe.web.id
  # Use only the explicit outbound rule for SNAT.
  disable_outbound_snat = true
}

resource "azurerm_lb_outbound_rule" "web" {
  name                    = "outbound-nimbus-${var.binome}-web"
  loadbalancer_id         = azurerm_lb.web.id
  protocol                = "All"
  backend_address_pool_id = azurerm_lb_backend_address_pool.web.id

  frontend_ip_configuration {
    name = azurerm_lb.web.frontend_ip_configuration[0].name
  }
}
