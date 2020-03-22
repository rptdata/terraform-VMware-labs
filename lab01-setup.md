# Lab 1: Lab Setup

Duration: 20 minutes

- Task 1: Install Terraform
- Task 2: Verify Terraform installation
- Task 3: Generate your first Terraform Configuration
- Task 4: Use the Terraform CLI to Get Help
- Task 5: Apply and Update your Configuration

## Task 1: Install Terraform

**Learn Link** https://learn.hashicorp.com/terraform/getting-started/install.html

Linux

```shell
wget https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip

unzip terraform_0.12.24_linux_amd64.zip

sudo mv terraform /example/file/path

export PATH=$PATH:/example/file/path
```
MacOS

```shell
wget https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_darwin_amd64.zip

unzip terraform_0.12.24_darwin_amd64.zip

sudo mv terraform /example/file/path

export PATH=$PATH:/example/file/path
```
Windows

1. Download the correct Terraform Binary 
2. Unzip and Move it your desired folder ex. `C:\terraform`

3. Search for and Open **View Advanced System Settings**

4. Edit environment variables, then under system variables find PATH then click, Edit.

5. Add the terraform directory to **PATH** by appending `;C:\terraform\`


## Task 2: Verify Terraform installation

### Step 1.2.1

Run the following command to check the Terraform version:

```shell
terraform -version
```

You should see:

```text
Terraform v0.12.16
```

## Task 3: Generate your first Terraform Configuration

### Step 1.3.1

Create a new `TerraformClass` directory.  For example: `C:\TerraformClass` or `/workstation/terraform` 
In the new directory, create a file titled `main.tf` to create a VMware VM.

Copy and Paste the Terraform code below into your `main.tf` and save the file.  You will need to substitute vaules provided by your instructor in the "< >" portions of the configuration.

```hcl
provider "vsphere" {
  user           = "<VSPHERE_USERNAME>"
  password       = "<VSPHERE_PASSWORD>"
  vsphere_server = "<VSPHERE_SERVER>"

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "Datacenter"
}

data "vsphere_compute_cluster" "cluster" {
  name          = "East"
  datacenter_id = data.vsphere_datacenter.dc.id

}

data "vsphere_datastore" "datastore" {
  name          = "<DATASTORE_NAME>"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = "VM Network"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "vm" {
  name             = "<VM_NAME>"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = 2
  memory   = 1024
  guest_id = "other3xLinux64Guest"

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  wait_for_guest_net_timeout = 0

  disk {
    label = "disk0"
    size  = 20
  }
}
```
The `wait_for_guest_net_timeout` is set to `0` because our VM will not yet have an Operating System assigned, therefore an IP address will not yet be assigned.

Don't forget to give your VM a unique name and save the file before moving on!

## Task 4: Use the Terraform CLI to Get Help

### Step 1.4.1

Execute the following command to display available commands:

```shell
terraform -help
```

```text
Usage: terraform [-version] [-help] <command> [args]

The available commands for execution are listed below.
The most common, useful commands are shown first, followed by
less common or more advanced commands. If you're just getting
started with Terraform, stick with the common commands. For the
other commands, please read the help and docs before usage.

Common commands:
    apply              Builds or changes infrastructure
    console            Interactive console for Terraform interpolations
    destroy            Destroy Terraform-managed infrastructure
    env                Workspace management
    fmt                Rewrites config files to canonical format
    get                Download and install modules for the configuration
    graph              Create a visual graph of Terraform resources
    import             Import existing infrastructure into Terraform
    init               Initialize a Terraform working directory
    output             Read an output from a state file
    plan               Generate and show an execution plan

    ...
```
* (full output truncated for sake of brevity in this guide)


Or, you can use short-hand:

```shell
terraform -h
```

### Step 1.4.2

Navigate to the Terraform directory and initialize Terraform
```shell
cd /workstation/terraform
```

Validate Terraform configuration
```shell
terraform validate
```

```text
Success! The configuration is valid.
...

```shell
terraform init
```

```text
Initializing provider plugins...
...

Terraform has been successfully initialized!
```

### Step 1.4.3

Get help on the `plan` command and then run it:

```shell
terraform -h plan
```

```shell
terraform plan
```

## Task 5: Apply and Update your Configuration

### Step 1.5.1

Run the `terraform apply` command to generate real resources in vSphere

```shell
terraform apply
```

You will be prompted to confirm the changes before they're applied. Respond with
`yes`.

### Step 1.5.2

Use the `terraform show` command to view the resources created.

### Step 1.5.3

Terraform can perform in-place updates on your instances after changes are made to the `main.tf` configuration file.

Increase memory to the VMware VM by updating the memory value from `1024` to `2048`.   

```hcl
 resource "vsphere_virtual_machine" "vm" {
  name             = "gabe_vm"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = 2
  memory   = 2048
  guest_id = "other3xLinux64Guest"

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  wait_for_guest_net_timeout = 0

  disk {
    label = "disk0"
    size  = 20
  }
}
```
Don't forget to save the file before moving on!

### Step 1.5.4

Plan and apply the changes you just made and note the output differences for additions, deletions, and in-place changes.

```shell
terraform plan
```

```shell
terraform apply
```

You should see output indicating that vsphere_virtual_machine will be modified:

```text
...

# vsphere_virtual_machine.vm will be updated in-place
~ resource "vsphere_virtual_machine" "vm" {
   ~ memory  = 1024 -> 2048
...
```

When prompted to apply the changes, respond with `yes`.
