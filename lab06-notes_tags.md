# Lab 6: Notes and Tags

Duration: 20 minutes

Notes and Tags are a useful way to track information about your VMs within vSphere.  

- Task 1: Update Note and Tag on VM 
- Task 2: Utilize the Terraform Template data resource to update VM Note. (Optional)

## Task 1: Update Tag on VM
### Step 6.1.1

Edit the `main.tf` to add a Tag for the VM.  Add the following tag resources to your `main.tf` file replacing your initials within the category name.

```hcl
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

resource "vsphere_tag" "tag_windows" {
  name        = "Windows 2019"
  category_id = vsphere_tag_category.category.id
  description = "Windows 2019 Server - Managed by Terraform"
}
```
Run the `terraform apply` command to generate real resources in VMware

```shell
terraform apply
```

### Step 6.1.2

Update the `vsphere_virtual_machine` resource to included the new created tags.

```hcl
resource "vsphere_virtual_machine" "windows_vm"" {
  ...

  tags = ["${vsphere_tag.tag_prod.id}", "${vsphere_tag.tag_windows.id}"]
}
```
```

## Task 2: Update Notes on VM using Annotation
### Step 6.2.1

Update the `vsphere_virtual_machine` resource to included the annotation.

```hcl
resource "vsphere_virtual_machine" "windows_vm"" {
  ...

annotation = "Server built with Terraform - ${formatdate("DD MMM YYYY hh:mm ZZZ", timestamp())}"

```

Run the `terraform apply` command to generate real resources in VMware

```shell
terraform apply
```

## (Optional) Task 2: Update Notes on VM using Annotation and Terraform Template
Long strings can be managed using templates. Templates are data-sources defined by a string with interpolation tokens (usually loaded from a file) and some variables to use during interpolation. They have a computed rendered attribute containing the result.

### Step 6.2.1
Create a templates directory and save the `serverbuild.tpl`

### Step 6.2.2
Create a data resource that refers to the template

```hcl
data "template_file" "server_note" {
  template = "${file("templates/serverbuild.tpl")}"
  vars {
    hello = "goodnight"
    world = "moon"
  }
}
```