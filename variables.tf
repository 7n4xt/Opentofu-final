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
  type        = number
  description = "Numéro de groupe utilisé comme deuxième octet du réseau 10.numgroupe.0.0/16."

  validation {
    condition     = var.numgroupe >= 0 && var.numgroupe <= 255 && floor(var.numgroupe) == var.numgroupe
    error_message = "Le numéro de groupe doit être un entier entre 0 et 255."
  }
}
variable "region" {
  type        = string
  description = "Région Azure retenue lors du TP."
  default     = "spaincentral"
}
variable "projet" {
  type        = string
  description = "Nom du projet"
}
variable "taille_vm" {
  type        = string
  description = "Taille des VM retenue lors du TP Azure."
  default     = "Standard_B2ats_v2"
}
variable "env" {
  type        = string
  description = "Environnement utilisé dans le tag env."
  default     = "tp"
}
variable "admin_username" {
  type        = string
  description = "Nom du compte administrateur des VM."
  default     = "azureuser"
}
variable "ssh_public_key_path" {
  type        = string
  description = "Chemin local de la clé publique SSH (.pub), jamais de la clé privée."
}

variable "allowed_ssh_cidr" {
  type        = string
  description = "Votre IPv4 publique autorisée en SSH sur la jumpbox, au format a.b.c.d/32."

  validation {
    condition     = can(cidrnetmask(var.allowed_ssh_cidr)) && endswith(var.allowed_ssh_cidr, "/32")
    error_message = "Indiquez une seule IPv4 au format a.b.c.d/32, jamais un réseau ouvert à tous."
  }
}
