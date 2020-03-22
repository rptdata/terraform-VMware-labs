# Lab 5: Cloning and Customization - Linux

Duration: 20 minutes

Now that we have succesfully provisioned an empty VM within vSphere we want to now clone a VM from a template.

- Task 1: Create a Linux VM from a clone template
- Task 2: Clone Linux VM
- Task 3: Customize Linux VM
- Task 4: Create variables in a configuration block

## Task 1: Clone a Linux VM from template

### Step 5.1.1

Edit the `main.tf` to build a VMware VM from a CentOS7 template.

Add the following data and resources to your `main.tf` file.  This will create a new resource called `linux_vm` and will include a clone stanza to clone from a CentOS 7 template.

```hcl

data "vsphere_virtual_machine" "linux_template" {
  name          = "CentOS7"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "linux_vm" {
  name             = "${var.server_name}-CentOS"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = var.vcpus
  memory   = var.memory
  firmware  = "bios"
  guest_id = data.vsphere_virtual_machine.linux_template.guest_id
  scsi_type = data.vsphere_virtual_machine.linux_template.scsi_type

  network_interface {
    network_id = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.linux_template.network_interface_types[0]
 }

  disk {
    label = "disk0"
    size = data.vsphere_virtual_machine.linux_template.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.linux_template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.linux_template.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.linux_template.id
  }

}
```
Don't forget to give your VM a unique name and save the file before moving on!

## Task 2: Clone VM
~> **NOTE:** Cloning requires vCenter and is not supported on direct ESXi
connections.

### Step 5.2.1

Validate Terraform configuration
```shell
terraform validate
```

```text
Success! The configuration is valid.
...

```shell
terraform plan
```

Run the `terraform apply` command to generate real resources in VMware

```shell
terraform apply
```

You will be prompted to confirm the changes before they're applied. Respond with
`yes`.

### Step 5.2.2

Create two new output variables named "linux_server_name" and "linux_server_memory" to output the instance's guest_name and memsize attributes

```hcl
output "linux_server_name" {
  value = vsphere_virtual_machine.linux_vm.name
}

output "linux_server_memory" {
  value = vsphere_virtual_machine.linux_vm.memory
}

output "linux_ip_address" {
  value = vsphere_virtual_machine.linux_vm.default_ip_address
}
```

Run the refresh command to pick up the new output for the Linux VM:

```shell
terraform refresh
```
```text
Outputs:

server_memory = 2048
server_name = vmtest
linux_ip_address = 192.168.169.135
linux_server_memory = 2048
linux_server_name = vmtest-Linux
```

### Step 5.2.3 Wrap an output query to ping the IP Address

```shell
ping $(terraform output linux_ip_address)
```

## Task 3: Customize Linux VM via SysPrep
Customize the Linux VM.  Add the `customize` block with the respective customization options, nested within the `clone` block.

~> **NOTE:** Changing any option in `clone` after creation forces a new
resource.

### Step 5.3.1

```hcl
  ...
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
  ... 
```
Run the `terraform apply` command to generate real resources in VMware

```shell
terraform fmt
```

```shell
terraform apply
```

You will be prompted to confirm the changes before they're applied. Notice that your VM will need to replaced.

```shell
# vsphere_virtual_machine.linux_vm must be replaced
```
This is because customization of the VM requires that it be rebuilt.  This is why running a plan before an apply is so important because your intention might not to be to destroy and rebuild your Linux server.

```hcl
 + customize { # forces replacement
              + timeout = 10 # forces replacement

              + linux_options { # forces replacement
                  + admin_password    = (sensitive value)
                  + auto_logon_count  = 1 # forces replacement
                  + computer_name     = "vmtest" # forces replacement
                  + full_name         = "Administrator" # forces replacement
                  + organization_name = "Managed by Terraform" # forces replacement
                  + time_zone         = 40 # forces replacement
                  + workgroup         = "Workgroup" # forces replacement
                }
            }
        }
```

Respond with
`yes`.


## Task 4: Create variables in a configuration block

### Step 5.4.1 Add Linux VM variables
Add variables for Linux server at the top of your `main.tf`  file:

```hcl
variable "linux_template" {}
variable "linux_domain" {}
variable "linux_timezone" {}
```

### Step 5.4.2 Variablize Linux VM data and resource blocks
```hcl
data "vsphere_virtual_machine" "linux_template" {
  name          = var.linux_template
  datacenter_id = data.vsphere_datacenter.dc.id
}

...
customize {
      linux_options {
        host_name = "${var.server_name}-CentOS"
        domain    = var.linux_domain
        time_zone = var.linux_timezone
      }
...
```
### Step 5.4.3 Update variables file for Linux VM
Add the rest of your lines in your terraform.tfvars file and rerun terraform apply.

```hcl
linux_template = "CentOS7"
linux_domain   = "test.internal"
linux_timezone = "America/New_York"
```

### Step 5.4.4 Run Plan
```shell
terraform plan
```

```text
terraform plan
```

### Note:
For a full list of VMware VM customization options please review the vSphere Terraform Provider documentation.

* [Windows Customization Options - vSphere VM](https://www.terraform.io/docs/providers/vsphere/r/virtual_machine.html#windows-customization-options)

* [Linux Customization Options - vSphere VM](https://www.terraform.io/docs/providers/vsphere/r/virtual_machine.html#linux-customization-options)

* [Time Zone Reference](https://docs.microsoft.com/en-us/previous-versions/windows/embedded/ms912391(v=winembedded.11)?redirectedfrom=MSDN)