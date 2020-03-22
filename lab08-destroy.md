# Lab 8: Destroy

Duration: 5 minutes

You've now learned about all of the key features of Terraform, and how to use it
to manage your infrastructure. The last command we'll use is `terraform
destroy`. As you might guess from the name, this will destroy all of the
infrastructure managed by this configuration.

- Task 1: Destroy your infrastructure

## Task 1: Destroy your infrastructure

### Step 10.1.1

Run the command `terraform destroy`:

```shell
terraform destroy
```

```text
# ...


Destroy complete! Resources: 4 destroyed.
```

You'll need to confirm the action by responding with `yes`. You could achieve
the same effect by removing all of your configuration and running `terraform
apply`, but you often will want to keep the configuration, but not the
infrastructure created by the configuration.
