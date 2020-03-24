# Lab 10: Terraform Provisioners - Linux

Duration: 30 minutes

In this lab you will create a Virtual Machine but this time layer in Terraform Provisioners to configure the machines as part the Terraform apply.

- Task 1: Define a Provisoner
- Task 2: Running Provisoners
- Task 3: Cleanup
- Task 4: Failed provisioners and tainted resources
- Task 5: Destroy Provisoners

Terraform [provisioners](https://www.terraform.io/docs/provisioners/index.html) help you do additional setup and configuration when a resource is created or destroyed. You can move files, run shell scripts, and install software.

Provisioners are not intended to maintain desired state and configuration for existing resources. For that purpose, you should use one of the many tools for configuration management, such as [Chef](https://www.chef.io/chef/), [Ansible](https://www.ansible.com/), and PowerShell [Desired State Configuration](https://docs.microsoft.com/en-us/powershell/dsc/overview/overview). (Terraform includes a [chef](https://www.terraform.io/docs/provisioners/chef.html) provisioner.)

An imaged-based infrastructure, such as images created with [Packer](https://www.packer.io), can eliminate much of the need to configure resources when they are created. In this common scenario, Terraform is used to provision infrastructure based on a custom image. The image is managed as code.

## Task 1: Define a Provisoner
### Step 10.1.1
Provisioners are defined on resources, most commonly a new instance of a virtual machine or container.

The complete configuration for this example is given below. By now, you should be familiar with most of the contents.

Notice that the vsphere_virtual_machine resource contains two provisioner blocks:

```hcl
resource "vsphere_virtual_machine" "linux_vm" {

    <...snip...>

 provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "root"
      password = var.linux_admin_password
      host     = vsphere_virtual_machine.linux_vm.default_ip_address
    }

    inline = [
      "yum -y update"
    ]

  }
}
```

As this example shows, you can define more than one provisioner in a resource block. The [file](https://www.terraform.io/docs/provisioners/file.html) and [remote-exec](https://www.terraform.io/docs/provisioners/remote-exec.html) providers are used to perform two simple setup tasks:

-   File copies a powershell file from the machine that is running Terraform to the new VM instance.
-   Remote-exec runs commands to run a powershell command to install IIS.

Both providers need a [connection](https://www.terraform.io/docs/provisioners/connection.html) to the new virtual machine to do their jobs. To simplify things, the example uses password authentication. In practice, you are more likely to use SSH keys or WinRM connections.

## Task 2: Running Provisioners

### Step 10.2.1

Provisioners run when a resource is created, or a resource is destroyed. Provisioners do not run during update operations. The example configuration for this section defines two provisioners that run only when a new virtual machine instance is created. If the virtual machine instance is later modified or destroyed, the provisioners will not run.

Although we don't show it in the example configuration, there is a way to define provisioners that run when a resource is destroyed.

To run the example configuration with provisioners:
1.  Create a folder under modules called `my_linux_vm`
1.  Create a `main.tf` in the `my_linux_vm` directory.
1.  Update the `main.tf` in the `my_linux_vm` directory with the following configuration, including the `remote-exec` provisioner.

```
variable "prefix" {}
variable "vcpus" {}
variable "memory" {}
variable "tag_tier" {}
variable "tag_release" {}
variable "datacenter" {
  default = "Datacenter"
}
variable "cluster" {
  default = "East"
}
variable "datastore" {
  default = "380SSDDatastore2"
}
variable "network" {
  default = "VM Network"
}
variable "disk_size" {
  default = "20"
}
variable "linux_template" {}
variable "linux_admin_password" {}

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

resource "vsphere_virtual_machine" "linux_vm" {
  name             = "${var.prefix}-CentOS"
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
        host_name = "${var.prefix}-CentOS"
        domain    = "test.internal"
        time_zone = "US/Eastern"
      }
      network_interface {}
    }
  }

  tags       = ["${vsphere_tag.tag_tier.id}", "${vsphere_tag.tag_release.id}"]
  annotation = "Server built with Terraform - ${formatdate("DD MMM YYYY hh:mm ZZZ", timestamp())}"

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "root"
      password = var.linux_admin_password
      host     = vsphere_virtual_machine.linux_vm.default_ip_address
    }

    inline = [
      "yum -y update"
    ]

  }
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

1. Update the `main.tf` in the root directory to remove all modules.
1. Update the `main.tf` in the root directory to remove all windows variables and add:

```hcl
variable "linux_template" {}
variable "linux_admin_password" {}
```

1. Update the `main.tf` in the root directory to add the following module:

```hcl
module "myawesomelinuxvm" {
  source               = "./modules/my_linux_vm"
  prefix               = "${var.prefix}-linux"
  vcpus                = var.vcpus
  memory               = var.memory
  datastore            = var.datastore
  linux_template       = var.linux_template
  linux_admin_password = var.linux_admin_password
  tag_tier             = "Bronze"
  tag_release          = "CentOS7 - FY2020 Q1 Release - IIS"
}
```
1. In the root directory edit the `terraform.tfvars` file to remove any references of Windows variables, and add
```hcl
linux_template       = "CentOS7"
linux_admin_password = "P@ssw0rd01"
```
1.  Save all files.
1.  Run `terraform init`
1.  Run `terraform plan`
1.  Run `terraform apply`. When prompted to continue, answer `yes`.

The following sample output has been truncated to show only the end of the output added by the provisioners (your actual output may differ slightly):

```
...

module.myawesomelinuxvm.vsphere_virtual_machine.linux_vm (remote-exec):   systemd.x86_64 0:219-67.el7_7.4
module.myawesomelinuxvm.vsphere_virtual_machine.linux_vm (remote-exec):   systemd-libs.x86_64 0:219-67.el7_7.4
module.myawesomelinuxvm.vsphere_virtual_machine.linux_vm (remote-exec):   systemd-sysv.x86_64 0:219-67.el7_7.4

module.myawesomelinuxvm.vsphere_virtual_machine.linux_vm (remote-exec): Complete!
module.myawesomelinuxvm.vsphere_virtual_machine.linux_vm: Creation complete after 4m12s [id=42085c01-fee7-dc04-178e-7dac6a8aead1]

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

```

## Task 3: Clean up

### Step 10.3.1

When you are done, run `terraform destroy` to remove everything we created

## Task 4:  Failed provisioners and tainted resources
### Step 10.4.1

Provisioners sometimes fail to run properly. By the time the provisioner is run, the resource has already been physically created. If the provisioner fails, the resource will be left in an unknown state. When this happens, Terraform will generate an error and mark the resource as "tainted." A resource that is tainted isn't considered safe to use.

When you generate your next execution plan, Terraform will not attempt to restart provisioning on the tainted resource because it isn't guaranteed to be safe. Instead, Terraform will remove any tainted resources and create new resources, attempting to provision them again after creation.

You might wonder why Terraform doesn't destroy the tainted resource during apply, to avoid leaving a resource in an unknown state. Terraform doesn't roll back tainted resources because that action was not in the execution plan. The execution plan says that a resource will be created, but not that it might be deleted. If you create an execution plan with a tainted resource, however, the plan will clearly state that the resource will be destroyed because it is tainted.


## Task 5: Destroy Provisoners

Provisioners can also be defined that run only during a destroy operation. These are known as [destroy-time provisioners](https://www.terraform.io/docs/provisioners/index.html#destroy-time-provisioners). Destroy provisioners are useful for performing system cleanup, extracting data, etc.

The following code snippet shows how a destroy provisioner is defined:

```
provisioner "remote-exec" {
    when = "destroy"

    <...snip...>

```