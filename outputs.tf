output "site_url" {
  description = "URL HTTP publique du site NimbusShop via le Load Balancer."
  value       = "http://${azurerm_public_ip.lb.ip_address}"
}

output "jumpbox_public_ip" {
  description = "IPv4 publique de la jumpbox, accessible en SSH uniquement depuis allowed_ssh_cidr."
  value       = azurerm_public_ip.jumpbox.ip_address
}

output "web_private_ips" {
  description = "IPv4 privées des VM web, accessibles en SSH via la jumpbox."
  value       = azurerm_network_interface.web[*].private_ip_address
}
