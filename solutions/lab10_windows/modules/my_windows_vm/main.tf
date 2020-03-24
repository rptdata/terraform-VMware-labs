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
  default = "380SSDDatastore2"
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
