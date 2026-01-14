# Standard Web Application Infrastructure Module

## Overview

Build a reusable Terraform module for a scalable three-tier web application on Azure.

## Architecture

### Network Layer

- Resource Group with tagging
- VNet (10.0.0.0/16) with subnets: web (10.0.1.0/24), database (10.0.2.0/24)
- NSGs: web tier allows 80/443 from internet; database tier allows 1433 from web tier only

### Compute Layer

- Azure Load Balancer (Standard SKU) with public IP, health probe, backend pool
- VMSS: Ubuntu/Windows, min 2 max 10 instances, custom script to install web server
- Autoscaling: scale out at CPU > 75%, scale in at CPU < 25%

### Database Layer

- Azure SQL Server with private endpoint
- SQL Database with TDE enabled
- Firewall rules for Azure services only

### Security

- Key Vault for storing SQL credentials
- Managed identity for VMSS to access Key Vault
- No public IPs on VMs (optional Bastion for access)

### Monitoring (Optional)

- Application Insights
- Log Analytics Workspace

## Module Interface

### Required Variables

- project_name, environment, location, admin_username

### Optional Variables

- vm_sku (default: Standard_B2s)
- vm_instances_min/max (default: 2/10)
- sql_sku (environment-dependent)
- enable_bastion, enable_monitoring (default: false)

### Outputs

- load_balancer_fqdn, sql_server_fqdn, resource_group_name, key_vault_name

## File Structure

```bash
modules/web-app/
├── main.tf # Main resources
├── variables.tf # Input variables
├── outputs.tf # Outputs
├── networking.tf # VNet, NSGs
├── compute.tf # Load balancer, VMSS
├── database.tf # SQL resources
├── security.tf # Key Vault, identities
├── versions.tf # Provider versions
└── README.md # Documentation
```

## Implementation Plan

### Week 1: Foundation

- Networking (VNet, subnets, NSGs)
- Resource group with naming and tagging

### Week 2: Compute & Database

- Load balancer and VMSS with autoscaling
- Azure SQL with private endpoint

### Week 3: Security

- Key Vault integration
- Managed identities
- Move credentials to Key Vault

### Week 4: Testing & Documentation

- Load testing and autoscaling verification
- Complete README with examples
- Test multi-environment deployment

### Testing Checklist

- [ ] Module deploys with default variables
- [ ] Application accessible via load balancer
- [ ] Autoscaling works under CPU load
- [ ] Database only accessible from web tier
- [ ] Credentials stored in Key Vault
- [ ] Clean destruction without errors
- [ ] Works across dev/staging/prod environments

## Stretch Goals

- Azure Front Door or CDN
- Container support with ACR
- Blue-green deployment capability
- Multi-region with Traffic Manager
- Sentinel policy integration
