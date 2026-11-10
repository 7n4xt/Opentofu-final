# Define input variables here.
variable "subscription_id" {
  type        = string
  description = "ID de l'abonnement Azure"
}
variable "binome" {
  type        = string
  description = "Votre nom de binôme"
}
variable "numgroupe" {
  type        = string
  description = "Numéro du groupe"
}
variable "region" {
  type    = string
  default = "spaincentral"
}