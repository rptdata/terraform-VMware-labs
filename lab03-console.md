# Lab 3: Terraform Console

Duration: 10 minutes

Terraform configurations and commands often use [expressions](https://www.terraform.io/docs/configuration/expressions.html) like `vsphere_virtual_machine.vm.name` to reference Terraform resources and their attributes.

Terraform includes an interactive console for evaluating expressions against the current Terraform state. This is especially useful for checking values while editing configurations.

- Task 1: Use `terraform console` to query specific instance information.

## Task 1: Use `terraform console` to query specific instance information.

### Step 3.1.1

See the details of your VM

```shell
$ terraform console
> vsphere_virtual_machine.vm.name
```
### Step 3.1.2

Find the Memory Size of your instance

```
$ terraform console
> vsphere_virtual_machine.vm.memory
2048
```

Control+C exits the Terraform console

### Step 3.1.3

You can also pipe query information to the stdin of the console for evaluation

```shell
$ echo "vsphere_virtual_machine.vm.memory" | terraform console
2048
```

