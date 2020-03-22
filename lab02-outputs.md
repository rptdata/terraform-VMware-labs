# Lab 2: Outputs

Duration: 10 minutes

Outputs allow us to query for specific values rather than parse metadata in `terraform show`.

- Task 1: Create output variables in your configuration file
- Task 2: Use the output command to find specific variables

## Task 1: Create output variables in your configuration file

### Step 2.1.1

Create two new output variables named "server_name" and "server_memory" to output the instance's guest_name and memsize attributes

```hcl
output "server_name" {
  value = vsphere_virtual_machine.vm.name
}

output "server_memory" {
  value = vsphere_virtual_machine.vm.memory
}
```

### Step 2.1.2

Run the refresh command to pick up the new output

```shell
terraform refresh
```

## Task 2: Use the output command to find specific variables

### Step 2.2.1 Try the terraform output command with no specifications

```shell
terraform output
```

### Step 2.2.2 Query specifically for the public_dns attributes

```shell
terraform output server_name
```

### Step 2.2.3 Wrap an output query to echo the server name

```shell
echo $(terraform output server_name)
```
