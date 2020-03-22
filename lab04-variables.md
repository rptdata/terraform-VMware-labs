# Lab 4: Variables

Duration: 15 minutes

We don't want to hard code all of our values in the main.tf file. We can create a variable file for easier use.

- Task 1: Create variables in a configuration block
- Task 2: Interpolate those variables
- Task 3: Create a terraform.tfvars file

## Task 1: Create a new configuration block for variables

### Step 4.1.1

Add four variables at the top of your configuration file:

```hcl
variable "vsphere_ip" {}
variable "username" {
  default = "administrator@vsphere.local"
}
variable "password" {}
```

## Task 2: Interpolate those variables into your existing code

### Step 4.2.1

In the provider block, update the hard-coded values to reflect the new variables.

```hcl
provider "vsphere" {
  user           = var.username
  password       = var.password
  vsphere_server = var.vsphere_ip
  allow_unverified_ssl = true
}
```

### Step 4.2.2

Rerun `terraform plan` for Terraform to pick up the new variables. Notice that you will be prompted for input now.

```shell
$ terraform plan
var.password
  Enter a value:
```

Use Ctrl+C to exit out of this plan.

## Task 3: Edit your terraform.tfvars file

Variables only defined in the configuration file will be prompted for input. We
can avoid this by creating a variables file. You'll find a file called
`terraform.tfvars` in your Terraform directory with several commented lines.

### Step 4.3.1

Edit the terraform.tfvars file and set the key-value pairs.

```
vsphere_ip = "<IP_PROVIDED_BY_INSTRUCTOR>"
username   = "<USERNAME_PROVIDED_BY_INSTRUCTOR>"
password   = "<PASSWORD_PROVIDED_BY_INSTRUCTOR>"
```
Rerun `terraform plan` and notice that this no longer prompts you for input.

### Step 4.3.2

The additional variables need to be added to our main.tf file.

```hcl
variable "datacenter" {}
variable "cluster" {}
variable "datastore" {}
variable "network" {}
variable "server_name" {}
variable "vcpus" {}
variable "memory" {}
variable "disk_size" {}
```

### Step 4.3.3

Edit your resource block with these changes as well.

```hcl
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

resource "vsphere_virtual_machine" "vm" {
  name             = var.server_name
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = var.vcpus
  memory   = var.memory
  guest_id = "other3xLinux64Guest"

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  wait_for_guest_net_timeout = 0

  disk {
    label = "disk0"
    size  = var.disk_size
  }
}
```
Add the rest of your lines in your terraform.tfvars file and rerun terraform apply.

```hcl
datacenter  = "Datacenter"
cluster     = "East"
datastore   = "Datastore2"
network     = "VM Network"
server_name = "<YOUR_VM_NAME>"
vcpus       = "2"
memory      = "2048"
disk_size   = "20"
```

After making these changes, run `terraform apply`.
