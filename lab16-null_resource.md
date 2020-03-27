# Lab 16: Null Resource

Duration: 15 minutes

This lab demonstrates the use of the `null_resource`. Instances of `null_resource` are treated like normal resources, but they don't do anything. Like with any other resource, you can configure provisioners and connection details on a null_resource. You can also use its triggers argument and any meta-arguments to control exactly where in the dependency graph its provisioners will run.

- Task 1: Create a VM using Terraform
- Task 2: Use `null_resource` with a VM to take action with `triggers`.

We'll demonstrate how `null_resource` can be used to take action on a set of existing resources that are specified within the `triggers` argument


## Task 1: Create a VM using Terraform
### Step 16.1.1: Create VM
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

  tags       = ["${vsphere_tag.tag_prod.id}", "${vsphere_tag.tag_linux.id}"]
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

## Task 2: Use `null_resource` with a VM to take action with `triggers`
### Step 16.2.1: Use `null_resource`

Add `null_resource` stanza to the `main.tf`.  Notice that the trigger for this resource is set to 

```hcl
resource "null_resource" "cluster" {
  # Changes to the annotation (Notes) of the VM requires re-provisioning
  triggers = {
    cluster_annotation = vsphere_virtual_machine.linux_vm.annotation
  }

  # Bootstrap script can run on any VM
  connection {
    type     = "ssh"
    user     = "root"
    password = "P@ssw0rd01"
    host     = vsphere_virtual_machine.linux_vm.default_ip_address
  }

  provisioner "remote-exec" {
    # Bootstrap script called with private_ip of each node in the cluster
    inline = [
      "yum -y update"
    ]
  }
}
```
Initialize the configuration with a `terraform init` followed by a `plan` and `apply`.

### Step 16.2.2: Re-run `plan` and `apply` to trigger `null_resource`
After the infrastructure has completed its buildout, re-run a plan and apply and notice that the null resource is triggered.  This is because the `annotation` attribute of our VM was updated with a new time stamp.

```shell
terraform apply


```

Run `apply` a few times to see the `null_resource` trigger a `yum update` on the VM after every run.

### Step 16.2.3: Destroy
Finally, run `destroy`.

```shell
terraform destroy
```
