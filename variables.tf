# Define input variables here.
variable "subscription_id" {
  type        = string
  description = "ID de l'abonnement Azure"
}
variable "binome" {
  type        = string
  description = "Votre nom de binôme"
}
variable "region" {
  type    = string
  default = "spaincentral"
}
variable "projet" {
  type        = string
  description = "Nom du projet"
}
variable "taille_vm" {
  type    = string
  default = "Standard_B2ats_v2"
}
variable "admin_ssh_public_key" {
  type        = string
  description = "Clé publique SSH pour l'utilisateur malek des VM web (jamais la clé privée)."
}
