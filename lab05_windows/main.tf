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
variable "windows_template" {}
variable "windows_workgroup" {}
variable "windows_admin_password" {}
variable "timezone" {}

provider "vsphere" {
  user           = var.username
  password       = var.password
  vsphere_server = var.vsphere_ip

  # If you have a self-signed cert
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

data "vsphere_virtual_machine" "windows_template" {
  name          = var.windows_template
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "windows_vm" {
  count            = var.windows_count
  name             = "${var.server_name}-Windows-${count.index}"
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
        computer_name  = "${var.server_name}-Windows-${count.index}"
        workgroup      = var.windows_workgroup
        admin_password = var.windows_admin_password
        time_zone      = var.timezone
      }
      network_interface {}
      timeout = 30
    }
  }
}

output "server_name" {
  value = vsphere_virtual_machine.vm.name
}

output "server_memory" {
  value = vsphere_virtual_machine.vm.memory
}

output "windows_server_name" {
  value = vsphere_virtual_machine.windows_vm.name
}

output "windows_server_memory" {
  value = vsphere_virtual_machine.windows_vm.memory
}

output "windows_ip_address" {
  value = vsphere_virtual_machine.windows_vm.default_ip_address
}