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