# Lab 15: Template Creation using Packer

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

Below is an example of a basic builder from a vmware-iso
```

 "builders": [
    {
        "type": "vmware-iso",
        "iso_url": "http://old-releases.ubuntu.com/releases/precise/ubuntu-12.04.2-server-amd64.iso",
        "iso_checksum": "af5f788aee1b32c4b2634734309cc9e9",
        "iso_checksum_type": "md5",
        "ssh_username": "packer",
        "ssh_password": "packer",
        "shutdown_command": "shutdown -P now"
    }
],

```
##### [Variables](https://www.packer.io/docs/templates/user-variables.html)
* User variables allow your templates to be further configured with variables from the command-line, environment variables, Vault, or files.
    * **Note**: these can be definied within the main JSON file and also be passed from an additional variable file, we will cover how to pass those variables further below

Below is an example of a variable section that would be in a main file for a Packer build
```
{
  "variables": {
    "ssh_user": "",
    "ssh_password": "",
    "network": "VLAN_28",
    "template_name": "DSM_Update",
    "iso_path": "iso",
    "vmname": "dsm",
    "storenumber": "{{ env `storenumber`}}",
    "islab": "y",
    "ks_file": "ks.cfg",
    "cpu_cores": "4",
    "ram_mb": "4096",
    "disk_size": "82240",
    "vmtype":   "centos7_64Guest"  
},

```

Below is an example of a stand alone variable file *The main difference is variables is **NOT** specified at the top as in the previous example*

```

{
      "vcenter_host": "example",
      "vcenter_user": "example",
      "vcenter_password": "example",
      "dc": "Labs",
      "cluster": "Lab015",
      "storage": "Data-10015",
      "vmfolder": "Lab015/Templates"
}

```

##### [Provsioners](https://www.packer.io/docs/provisioners/index.html)
* use builtin and third-party software to install and configure the machine image after booting. Provisioners prepare the system for use, so common use cases for provisioners include:
    * installing packages 
    * patching the kernel 
    * creating users 
    * downloading application code
        

Below is an example of a provisioner section that would be in the main json file
```

"provisioners": [
{
  "type": "file",
  "source": "./scripts/dsm_config.sh",
  "destination": "/tmp/dsm_config.sh"
},
{
  "type": "shell",
  "inline": ["chmod +x /tmp/dsm_config.sh",
	     "/tmp/dsm_config.sh {{ user `storenumber` }} {{ user `islab` }}"
            ]
}
  ],

```
##### [Post-Processors](https://www.packer.io/docs/post-processors/index.html)
* run after the image is built by the builder and provisioned by the provisioner(s). Post-processors are optional, and they can be used to upload artifacts, re-package, or more.

Example of a post processor
```

{
  "post-processors": [
    {
      "type": "compress",
      "format": "tar.gz"
    }
  ]
}

```


##### Organizing a complete file
* As best practice the file should follow the format shown below

```

{
  "variables": {
      
},
  "builders": [
	{
      "type": "vsphere-iso",
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
