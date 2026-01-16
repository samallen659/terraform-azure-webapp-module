variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  validation {
    condition     = length(var.project_name) <= 10
    error_message = "Project name must be 10 characters or less"
  }
}

variable "location" {
  description = "Azure region that the resources will be deployed too (UK South, UK West)"
  type        = string
  validation {
    condition     = contains(["UK South", "UK West"], var.location)
    error_message = "Location must be one of 'UK South' or 'UK West'"
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of 'dev', 'staging', or 'prod'"
  }
}

variable "admin_username" {
  description = "Admin username of the virtual machines in the scale set"
  type        = string
  default     = "adminvmss"
}

variable "admin_password" {
  description = "Admin password of the virtual machines in the scale set"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.admin_password) >= 8
    error_message = "Admin password must be at least 8 characters long"
  }
}
