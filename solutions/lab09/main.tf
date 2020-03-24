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

provider "vsphere" {
  user           = var.username
  password       = var.password
  vsphere_server = var.vsphere_ip

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

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

output "server_name" {
  value = "${module.myawesomewindowsvm-a.windows_server_name}"
}

output "server_ip" {
  value = "${module.myawesomewindowsvm-a.windows_ip_address}"
}
