# Lab 6: Notes and Tags

Duration: 20 minutes

Notes and Tags are a useful way to track information about your VMs within vSphere.  

- Task 1: Update Tag on VM
- Task 2: Update Note on VM
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

## Task 2: Update Notes on VM
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