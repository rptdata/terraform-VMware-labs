# Lab 15: Lifecycle

Duration: 15 minutes

This lab demonstrates how to use lifecycle directives to control the order in which Terraform creates and destroys resources.

## Task 1: Use `prevent_destroy` with an instance

We'll demonstrate how `prevent_destroy` can be used to guard an instance from being destroyed.

### Step 15.1.1: Create VM
Create a directory with a `main.tf` and `terraform.tfvars` file with the following configuration:

`main.tf`
```hcl
variable "vsphere_ip" {}
variable "username" {
  default = "administrator@vsphere.local"
}
variable "password" {}
variable "datacenter" {}
variable "cluster" {}
variable "datastore" {}
variable "network" {}
variable "server_name" {}
variable "vcpus" {}
variable "memory" {}
variable "disk_size" {}
variable "linux_template" {}
variable "linux_admin_password" {}

provider "vsphere" {
  user                 = var.username
  password             = var.password
  vsphere_server       = var.vsphere_ip
  allow_unverified_ssl = true
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

data "vsphere_virtual_machine" "linux_template" {
  name          = "CentOS7"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "linux_vm" {
  name             = "${var.server_name}-CentOS"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus  = var.vcpus
  memory    = var.memory
  firmware  = "bios"
  guest_id  = data.vsphere_virtual_machine.linux_template.guest_id
  scsi_type = data.vsphere_virtual_machine.linux_template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.linux_template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.linux_template.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.linux_template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.linux_template.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.linux_template.id

    customize {
      linux_options {
        host_name = "${var.server_name}-CentOS"
        domain    = "test.internal"
        time_zone = "US/Eastern"
      }
      network_interface {}
    }
  }
  
  tags = ["${vsphere_tag.tag_prod.id}", "${vsphere_tag.tag_linux.id}"]
  annotation = "Server built with Terraform - ${formatdate("DD MMM YYYY hh:mm ZZZ", timestamp())}"
}

resource "vsphere_tag_category" "category" {
  name        = "Server Tier - <YOUR INITIALS>"
  cardinality = "MULTIPLE"
  description = "Managed by Terraform"

  associable_types = [
    "VirtualMachine",
    "Datastore",
  ]
}

resource "vsphere_tag" "tag_prod" {
  name        = "Production"
  category_id = vsphere_tag_category.category.id
  description = "Production Environment - Managed by Terraform"
}

resource "vsphere_tag" "tag_linux" {
  name        = "CentOS 7"
  category_id = vsphere_tag_category.category.id
  description = "CentOS 7 Server - Managed by Terraform"
}

output "server_name" {
  value = vsphere_virtual_machine.linux_vm.name
}

output "server_memory" {
  value = vsphere_virtual_machine.linux_vm.memory
}

output "server_ip" {
  value = vsphere_virtual_machine.linux_vm.default_ip_address
}
```

`terraform.tfvars`
```hcl
vsphere_ip           = "<VSPHERE_IP>"
username             = "<YOUR_USERNAME>"
password             = "<YOUR_PASSWORD>"
datacenter           = "Datacenter"
cluster              = "East"
datastore            = "<YOUR_DATASTORE>"
network              = "VM Network"
server_name          = "<YOUR_INITALS>"
vcpus                = "2"
memory               = "4096"
disk_size            = "20"
linux_template       = "CentOS7"
linux_admin_password = "P@ssw0rd01"
```


### Step 15.1.2: Use `prevent_destroy`

Add `prevent_destroy = true` in a `lifecycle` stanza on the VM.

```bash
resource "vsphere_virtual_machine" "linux_vm" {
  name             = "${var.server_name}-CentOS"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  ...
  
  tags = ["${vsphere_tag.tag_prod.id}", "${vsphere_tag.tag_linux.id}"]
  annotation = "Server built with Terraform - ${formatdate("DD MMM YYYY hh:mm ZZZ", timestamp())}"
}
  ...

  lifecycle {
    prevent_destroy = true
  }
}
```
Initialize the configuration with a `terraform init` followed by a `plan` and `apply`.

### Step 15.1.3: Use `prevent_destroy`
After the infrastructure has complted its buildout, attempt to destroy the existing infrastructure. You should see the error that follows.

```shell
terraform destroy
```

```
Error: Instance cannot be destroyed

  on main.tf line 48:
  48: resource "vsphere_virtual_machine" "linux_vm" {

Resource vsphere_virtual_machine.linux_vm has lifecycle.prevent_destroy set,
but the plan calls for this resource to be destroyed. To avoid this error and
continue with the plan, either disable lifecycle.prevent_destroy or reduce the
scope of the plan using the -target flag.
```

### Step 15.1.4: Destroy cleanly

Now that you have finished the steps in this lab, destroy the infrastructure you have created.

Remove the `prevent_destroy` attribute by commenting it out or removing it.

```bash
  # ...
  # Comment out or delete these lines
  # lifecycle {
    # prevent_destroy = true
  #}
}
```

Finally, run `destroy`.

```shell
terraform destroy -force
```

The command should succeed and you should see a message confirming `Destroy complete! Resources: 2 destroyed.`
