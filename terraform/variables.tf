variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "northcentralus"
}

variable "prefix" {
  description = "Short prefix used in resource names"
  type        = string
  default     = "ctd"
}

variable "tags" {
  description = "Tags applied to every resource"
  type        = map(string)
  default = {
    project     = "cloud-threat-detection"
    environment = "lab"
    owner       = "andre-soler"
  }
}
