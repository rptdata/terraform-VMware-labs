# Lab 20: Template Creation using Packer

Duration: 30 minutes

### Getting Started

Download Packer binary files [Hashicorp](https://www.packer.io/downloads.html)
* [Install](https://packer.io/downloads.html) Packer by unzipping the downloaded package into a directory where Packer will be installed. 

    * On Unix systems, ~/packer or /usr/local/packer. If you intend to access it from the command-line, make sure to place it somewhere on your PATH before /usr/sbin. On Windows systems, you can put it wherever you'd like. The packer (or packer.exe for Windows) binary inside is all that is necessary to run Packer. Any additional files aren't required to run Packer.

    * After unzipping the package, the directory should contain a single binary program called packer. The final step to installation is to make sure the directory you installed Packer to is on the PATH. See [this page](https://stackoverflow.com/questions/14637979/how-to-permanently-set-path-on-linux-unix) for instructions on setting the PATH on Linux and Mac. [This page](https://stackoverflow.com/questions/1618280/where-can-i-set-path-to-make-exe-on-windows) contains instructions for setting the PATH on Windows

### Creating a Packer Image

Once all the necessary components are downloaded and installed for Packer, in this particular use-case for VMWare, we can begin to put the files together to create an image using [vmware-iso](https://www.packer.io/docs/builders/vmware-iso.html) to build from scratch or use the [vmware-clone](https://github.com/jetbrains-infra/packer-builder-vsphere/blob/master/README.md) plugin to build from an existing template.

To build an image packer utilizes a JSON file with the following sections...

##### [Builders](https://www.packer.io/docs/builders/index.html) (required)
* responsible for creating machines and generating images from them for various platforms.
* You can have multiple builder types in one file.

Below is an example of a basic builder from a vsphere-clone
Create a json file with the following builder.

```json

"builders": [
    {
      "type": "vsphere-clone",
      "vcenter_server": "192.168.169.11",
      "username": "<USERNAME>",
      "password": "<PASSWORD>",
      "datacenter": "Datacenter",
      "cluster": "East",
      "insecure_connection": true,
      "datastore": "380SSDDatastoreRAID1",
      "communicator": "winrm",
      "winrm_username": "Administrator",
      "winrm_password": "P@ssw0rd01",
      "template": "Win2019a",
      "vm_name": "Win2019-{{isotime \"2006-01-02 03:04:05\"}}",
      "convert_to_template": true
    }
  ]
}

```
Validate your configuration.

```shell
>packer validate win2019.json
```

##### [Variables](https://www.packer.io/docs/templates/user-variables.html)
* User variables allow your templates to be further configured with variables from the command-line, environment variables, Vault, or files.
    * **Note**: these can be definied within the main JSON file and also be passed from an additional variable file, we will cover how to pass those variables further below

Below is an example of a variable section that would be in a main file for a Packer build along with using environment variables for the username and password.
```json
{
  "variables": {
      "datacenter": "Datacenter",
      "cluster": "East",
      "insecure_connection": true,
      "datastore": "380SSDDatastoreRAID1",
      "communicator": "winrm",
      "winrm_username": "Administrator",
      "winrm_password": "P@ssw0rd01",
      "template": "Win2019a",
      "vm_name": "Win2019",
      "convert_to_template": true
},

"builders": [
    {
      "type": "vsphere-clone",
      "vcenter_server": "192.168.169.11",
      "username": "{{ env `vcenter_username`}}",
      "password": "{{env `vcenter_password`}}",
      "datacenter": "{{ user `datacenter` }}",
      "cluster": "{{ user `cluster` }}",
      "insecure_connection": true,
      "datastore": "{{ user `datastore` }}",
      "communicator": "{{ user `communicator` }}",
      "winrm_username": "{{ user `winrm_username` }}",
      "winrm_password": "{{ user `winrm_password` }}",
      "template": "{{ user `template` }}",
      "vm_name": "{{user `vm_name`}}-{{isotime \"2006-01-02 03:04:05\"}}",
      "convert_to_template": true
    }
  ]
}

```
Here we can follow enter the same cli commands to validate and build since the variables are within the same json.

Below is an example of a standalone variable file *The main difference is variables is **NOT** specified at the top as in the previous example*

You can choose to create a separate variables file for this lab or continue with using the variable stanza at the top of your configuration file.

```json

{
      "datacenter": "Datacenter",
      "cluster": "East",
      "insecure_connection": true,
      "datastore": "380SSDDatastoreRAID1",
      "communicator": "winrm",
      "winrm_username": "Administrator",
      "winrm_password": "P@ssw0rd01",
      "template": "Win2019a",
      "vm_name": "Win2019",
      "convert_to_template": true
}

```

In order to validate and build we need to specify the var file to use.

```shell
>packer validate -var-file=win-vars.json win2019.json 
```


##### [Provsioners](https://www.packer.io/docs/provisioners/index.html)
* use builtin and third-party software to install and configure the machine image after booting. Provisioners prepare the system for use, so common use cases for provisioners include:
    * installing packages 
    * patching 
    * creating users 
    * downloading application code
        

Below is an example of a provisioner section that would be in the main json file

Create a folder called `scripts` with a file called `example.txt`

```json

"provisioners": [
{
  "type": "file",
  "source": "./scripts/example.txt",
  "destination": "/tmp/example.txt"
},
{
  "type": "shell",
  "inline": "powershell.exe -executionpolicy bypass Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature"
}
]

```
##### [Post-Processors](https://www.packer.io/docs/post-processors/index.html)
* run after the image is built by the builder and provisioned by the provisioner(s). Post-processors are optional, and they can be used to upload artifacts, re-package, or more.

Example of a post processor
```json

{
  "post-processors": [
    {
      "type": "compress",
      "output": "build.zip"
    }
  ]
}

```


##### Organizing a complete file
* As best practice the file should follow the format shown below

```json

{
  "variables": {
      
},
  "builders": [
	{
      "type": "vsphere-clone",
    },
  ],
  "provisioners": [
    {

    },
  ],
  "post-processors": [
    ]
}

```

##### Running Packer
Once the file is ready we will need to dothe following steps...

1. **packer validate file-name-example.json** - If properly formatted the file will successfully validate
    * This command will work just fine if all the variables are within the main packer file, but if you want to pass user variables from a different file the command will have an additional flag **packer validate -var-file=example-var.json file-name-example.json**
    * Also if you have multiple builders an additional flag will need to be added in order to utilize a specific one **packer validate -only=vmware-iso file-name-example.json** 
    * The flags can be combined for example **packer validate -var-file=example-var.json -only=wmware-iso file-name-example.json**
2. **packer build file-name-example.json** - Again if you have an external variable file you need to reference you will need to add the **-var-file=** flag or if you have multiple builders to specify using one youe will need the **-only=** flag as well
    * **packer build -var-file=example-var.json -only=wmware-iso file-name-example.json**

##### Resources
* Packer [Docs](https://www.packer.io/docs/index.html)
* Packer [CLI](https://www.packer.io/docs/commands/index.html)
