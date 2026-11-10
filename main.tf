# Define providers, resources, and modules here.
resource "azurerm_resource_group" "example" {
  name     = "rg-nimbus-${var.binome}"
  location = var.region
  tags = {
    cpu   = "virtualisation"
    owner = var.binome
    projet = var.projet
  }
}