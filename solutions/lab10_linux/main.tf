variable "vsphere_ip" {}
variable "username" {}
variable "password" {}
variable "prefix" {}
variable "vcpus" {}
variable "memory" {}
variable "datastore" {}
variable "tag_tier" {}
variable "tag_release" {}
variable "linux_template" {}
variable "linux_admin_password" {}

provider "vsphere" {
  user           = var.username
  password       = var.password
  vsphere_server = var.vsphere_ip

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

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

output "server_name" {
  value = "${module.myawesomelinuxvm.server_name}"
}

output "server_ip" {
  value = "${module.myawesomelinuxvm.server_ip}"
}
