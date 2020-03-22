# Lab 7: Meta-Arguments

Duration: 10 minutes

So far, we've already used arguments to configure your resources. These arguments are used by the provider to specify things like the template to use, and the size of the VM to provision. Terraform also supports a number of _Meta-Arguments_, which changes the way Terraform configures the resources. For instance, it's not uncommon to provision multiple copies of the same resource. We can do that with the _count_ argument.

- Task 1: Change the number of Windows VMs with `count`
- Task 2: Modify the rest of the configuration to support multiple instances
- Task 3: Add variable interpolation to the Name tag to count the new instance

## Task 1: Change the number of VMs with `count`

### Step 7.1.1

Add a count argument to the Windows VM instance in `main.tf` with a value of 2:

```hcl
# ...
resource "vsphere_virtual_machine" "windows_vm" {
  count            = 2
  name             = "${var.server_name}-Windows-${count.index}"
# ... leave the rest of the resource block unchanged...
}
```

## Task 2: Modify the rest of the configuration to support multiple instances

### Step 8.2.1

If you run `terraform apply` now, you'll get an error. Since we added _count_ to the aws_instance.web resource, it now refers to multiple resources. Because of this, values like `vsphere_virtual_machine.windows_vm.default_ip_address` no longer refer to the default_ip_address of a single resource. We need to tell terraform which resource we're referring to.

To do so, modify the output blocks in `main.tf` as follows:

```
output "windows_server_name" {
  value = vsphere_virtual_machine.windows_vm[*].name
}

output "windows_server_memory" {
  value = vsphere_virtual_machine.windows_vm[*].memory
}

output "windows_ip_address" {
  value = vsphere_virtual_machine.windows_vm[*].default_ip_address
}
```

The syntax `vsphere_virtual_machine.windows_vm[*]` refers to all of the instances, so this will output a list of all of the VM names, memory size and default IPs.

### Step 8.2.2

Run `terraform apply` to add the new instance. You should see two IP addresses and two Windows server names in the outputs.

## Task 3: Add variable interpolation to the Name tag to count the new instances

### Step 8.3.1

Interpolate the count variable by changing the Name tag to include the current
count over the total count. Update `main.tf` to add a new variable
definition, and use it:

```hcl
# ...
variable windows_count {
  default = "2"
}

resource "vsphere_virtual_machine" "windows_vm" {
  count            = var.windows_count
# ...
```

The solution builds on our previous discussion of variables. We must create a
variable to hold our count so that we can reference that count to determine the number of servers to builds.

### Step 8.3.2

Run `terraform apply` in the terraform directory. You should see a build of servers that matches the count specified.

```shell
terraform apply
```
