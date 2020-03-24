# Lab 9: Terraform Modules

Duration: 40 minutes

In this challenge, you will create a module to contain a scalable virtual machine deployment, then create an environment where you will call the module.

- Task 1: Create Folder Structure
- Task 2: Create the Module
- Task 3: Create Variables and Module Declaration
- Task 4: Initialize and Run Plan
- Task 5: Set Required Variables
- Task 6: Add Another Module

## Task 1: Create Folder Structure
### Step 9.1.1

Change directory into a folder specific to this challenge.

For example: `/workstation/terraform/lab9-modules`.

In order to organize your code, create the following folder structure with `main.tf` files.

```sh
├ main.tf
├ terraform.tfvars
└── modules
    └── my_windows_vm
        └── main.tf
```

## Task 2: Create the Module

### Step 9.2.1

Inside the `my_windows_vm` module folder there should be a `main.tf` file with the following contents:

> Note: This is very similar to the original VM lab.

```hcl
variable "prefix" {}
variable "vcpus" {}
variable "memory" {}
variable "windows_template" {}
variable "windows_count" {}
variable "tag_tier" {}
variable "tag_release" {}
variable "datacenter" {
  default = "Datacenter"
}
variable "cluster" {
  default = "East"
}
variable "datastore" {
  default = "<DATASTORE_NAME>"
}
variable "network" {
  default = "VM Network"
}
variable "disk_size" {
  default = "20"
}
variable "windows_workgroup" {
  default="Workgroup" 
}
variable "windows_admin_password" {
  default="P@ssw0rd01"
}
variable "timezone" {
  default = "040"
}

data "vsphere_datacenter" "dc" {
  name = var.datacenter
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "windows_template" {
  name          = var.windows_template
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_tag_category" "category" {
  name        = "Server Tier - ${var.prefix}"
  cardinality = "MULTIPLE"
  description = "Managed by Terraform"

  associable_types = [
    "VirtualMachine",
    "Datastore",
  ]
}

resource "vsphere_tag" "tag_tier" {
  name        = var.tag_tier
  category_id = vsphere_tag_category.category.id
  description = "Production Environment - Managed by Terraform"
}

resource "vsphere_tag" "tag_release" {
  name        = var.tag_release
  category_id = vsphere_tag_category.category.id
  description = "Windows 2019 Server - Managed by Terraform"
}

resource "vsphere_virtual_machine" "windows_vm" {
  count            = var.windows_count
  name             = "${var.prefix}-Windows-${count.index}"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus  = var.vcpus
  memory    = var.memory
  firmware  = "efi"
  guest_id  = data.vsphere_virtual_machine.windows_template.guest_id
  scsi_type = data.vsphere_virtual_machine.windows_template.scsi_type

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.windows_template.disks.0.size
    thin_provisioned = data.vsphere_virtual_machine.windows_template.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.windows_template.id
    customize {
      windows_options {
        computer_name  = "${var.prefix}-Windows-${count.index}"
        workgroup      = var.windows_workgroup
        admin_password = var.windows_admin_password
        time_zone      = var.timezone
      }
      network_interface {}
    }
  }
  tags = ["${vsphere_tag.tag_tier.id}", "${vsphere_tag.tag_release.id}"]
  annotation = "Server built with Terraform - ${formatdate("DD MMM YYYY hh:mm ZZZ", timestamp())}"
}

output "windows_server_name" {
  value = vsphere_virtual_machine.windows_vm[*].name
}

output "windows_server_memory" {
  value = vsphere_virtual_machine.windows_vm[*].memory
}

output "windows_ip_address" {
  value = vsphere_virtual_machine.windows_vm[*].default_ip_address
}
```

## Task 3: Create Variables and Module Declaration

### Step 9.3.1 - Create Variables in Root
In your root directory, there should be a `main.tf` file.

Create "vsphere_ip", "username", "password", "prefix", "vcpus", "memory", "windows_template" "windows_count", "tag_tier", and "tag_release" variables without defaults.

This will result in them being required.

```hcl
variable "vsphere_ip" {}
variable "username" {}
variable "password" {}
variable "prefix" {}
variable "vcpus" {}
variable "memory" {}
variable "datastore" {}
variable "windows_template" {}
variable "windows_count" {}
variable "tag_tier" {}
variable "tag_release" {}
```

### Step 9.3.2 - Pass in Variables
In the root directory add the following variables to the `terraform.tfvars` file, updating the values provided to you by the instructor.

```sh
vsphere_ip       = "<VSPHERE_SERVER>"
username         = "<VSPHERE_USERNAME>"
password         = "<VSPHERE_PASSWORD>"
prefix           = "<YOUR_INITIALS>"
vcpus            = "2"
memory           = "4096"
datastore        = "<DATASTORE_NAME>"
windows_template = "<VM_TEMPLATE>"
windows_count    = 1
tag_tier         = "Gold"
tag_release      = "Windows 2019 - FY2020 Q1 Release"
```
### Step 9.3.3 - Create the Module declaration in Root

Update the `main.tf` in the root directory to add the vsphere provider and declare your module, it could look similar to this:

```hcl
provider "vsphere" {
  user           = var.username
  password       = var.password
  vsphere_server = var.vsphere_ip

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

module "myawesomewindowsvm-a" {
  source   = "./modules/my_windows_vm"
}
```

> Notice the relative module sourcing.

Save all of your files!!!

## Task 4: Initialize and Run Plan

### Step 9.4.1

Since we have created a new directory tree for our module work, we must run `terraform init` again before running `terraform plan`.

```sh
terraform init
terraform plan
```

```sh

Error: Missing required argument

  on main.tf line 22, in module "myawesomewindowsvm-a":
  22: module "myawesomewindowsvm-a" {

The argument "windows_count" is required, but no definition was found.


Error: Missing required argument

  on main.tf line 22, in module "myawesomewindowsvm-a":
  22: module "myawesomewindowsvm-a" {

The argument "tag_os" is required, but no definition was found.


Error: Missing required argument

  on main.tf line 22, in module "myawesomewindowsvm-a":
  22: module "myawesomewindowsvm-a" {

The argument "memory" is required, but no definition was found.

...

```
We have a problem! We didn't set required variables for our module.


## Task 5: Set Required Variables
### Step 9.5.1
Update the module in the `main.tf` file to include the required input variables:

```hcl
module "myawesomewindowsvm-a" {
  source           = "./modules/my_windows_vm"
  prefix           = "${var.prefix}a"
  vcpus            = var.vcpus
  memory           = var.memory
  datastore        = var.datastore
  windows_template = var.windows_template
  windows_count    = 1
  tag_tier         = "Gold"
  tag_release      = "Windows 2019 - FY2020 Q1 Release"
}
```

Rerun the plan:

```sh
terraform plan
```

and apply

```sh
terraform apply
```

## Task 6: Add Another Module 
Add another `module` block describing another set of Virtual Machines:

### Step 9.6.1
Update `main.tf` to add your module, it could look similar to this:

```hcl
module "myawesomewindowsvm-b" {
  source           = "./modules/my_windows_vm"
  prefix           = "${var.prefix}b"
  vcpus            = var.vcpus
  memory           = var.memory
  datastore        = var.datastore
  windows_template = var.windows_template
  windows_count    = 1
  tag_tier         = "Bronze"
  tag_release      = "Windows 2019 - FY2020 Q1 Release"
}
```

run `terraform plan`.

```sh
terraform plan
```

```text
Error: Module not installed

  on main.tf line 34:
  34: module "myawesomewindowsvm-b" {

This module is not yet installed. Run "terraform init" to install all modules
required by this configuration.
```

### Step 9.6.2
Since we added another module call, we must run `terraform init` again before running `terraform plan`.

We should see the addition of another VM as well as the date time stamp update to our existing VM.

```sh
  # module.myawesomewindowsvm-a.vsphere_virtual_machine.windows_vm[0] will be updated in-place
  ~ resource "vsphere_virtual_machine" "windows_vm" {
      ~ annotation                              = "Server built with Terraform - 18 Mar 2020 16:11 UTC" -> (known after apply)
        boot_delay                              = 0
        boot_retry_delay                        = 10000

...

  # module.myawesomewindowsvm-b.vsphere_virtual_machine.windows_vm[0] will be created
  + resource "vsphere_virtual_machine" "windows_vm" {
      + annotation                              = (known after apply)
      + boot_retry_delay                        = 10000
      + change_version                          = (known after apply)

...

Plan: 4 to add, 1 to change, 0 to destroy.

```

> Note: Feel free to apply this infrastructure to validate the workflow. Be sure to destroy when you are done.


## Advanced areas to explore

1. Extend module outputs to root level outputs.
1. Add a reference to the Public Terraform Module

Example: GitHub Repository

```hcl
provider "github" {
  # Alternatively set auth token as env variable: GITHUB_TOKEN
  token        = var.github_token 
  organization = "rptcloud"
}

module "repository" {
  source = "innovationnorway/repository/github"
  name = "example"
  description = "My example codebase"
  private = false
  gitignore_template = "Terraform"
  auto_init = true
  license_template   = "mit"
  topics = ["example"]
}
```

## Resources

- [Using Terraform Modules](https://www.terraform.io/docs/modules/usage.html)
- [Source Terraform Modiules](https://www.terraform.io/docs/modules/sources.html)
- [Public Module Registry](https://www.terraform.io/docs/registry/index.html)