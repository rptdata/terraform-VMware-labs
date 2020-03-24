# Lab 12: Reading State

Duration: 15 minutes

This lab demonstrates how to read state from another Terraform project. It uses the simplest possible example: a project on the same local disk.

- Task 1:  Create a Terraform configuration that defines an output
- Task 2:  Read an output value from that project's state

## Prerequisites

This lab only requires a copy of [Terraform](https://www.terraform.io/downloads.html). It doesn't require any cloud provider credentials.

## Task 1: Create a Terraform configuration that defines an output

For this task, you'll create two Terraform configurations in two separate directories. One will read from the other (using state files).  

1. Create a new directory called `read_state_demo`
1. Create two subdirectories `primary` and `secondary` each with their own `main.tf` file.

```sh
└── primary
    └── main.tf
└── secondary
    └── main.tf
```

### Step 1.1.1

In this step, you'll create a Terraform project on disk that does nothing but emit an output. It should emit `public_ip` which can be a hard-coded value (for simplicity).

Update the `main.tf` within the `primary` directory with a single output for `public_ip`. This is the entire contents of the file.

```bash
# primary/main.tf
output "public_ip" {
  value = "8.8.8.8"
}
```

### Step 1.1.2

Generate a state file for the project. Within that project, run `terraform init` and `apply`. You should see a `terraform.tfstate` file after running these commands.

Run the standard `terraform` commands within the `primary` project.

```shell
terraform init
```

```shell
terraform apply
```

## Task 2: Read an output value from that project's state

### Step 1.2.1

Create a new Terraform configuration that uses a data source to read the configuration from the `primary` project.

In the `secondary` directory edit the `main.tf` to define a `terraform_remote_state` data source that uses a `local` backend which points to the primary project.

```bash
# secondary/main.tf
# Read state from another Terraform config’s state
data "terraform_remote_state" "primary" {
  backend = "local"
  config = {
    path = "../primary/terraform.tfstate"
  }
}
```

Initialize the secondary project with `init`.

```shell
terraform init
```

### Step 1.2.2

Declare the `public_ip` as an `output`.

Within `read_state_demo/secondary/main.tf`, define an output whose value is the `public_ip` from the data source you just defined.

```bash
output "primary_public_ip" {
  value = data.terraform_remote_state.primary.outputs.public_ip
}
```

Finally, run `apply`. You should see the IP address you defined in the `primary` configuration.

```shell
terraform apply
```

```
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

primary_public_ip = 8.8.8.8
```