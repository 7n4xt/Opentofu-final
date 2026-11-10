output "site_url" {
  description = "URL HTTP publique du site NimbusShop via le Load Balancer."
  value       = "http://${azurerm_public_ip.lb.ip_address}"
}
