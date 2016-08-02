# PCF Diego On Windows

Setting up Diego on windows is a fairly simple task, and only takes a few steps. That said, many times a single (instead of the several) is more handy, repeatable and less error prone then the existing process. This script was developed to make the process even easier and faster. Furthermore, this script allows for quick and efficient deployment on a larger more complex environment then the one described in the original pivotal process.

Pivotal documentation can be found [here](https://docs.pivotal.io/pivotalcf/1-7/opsguide/deploying-diego.html).

The Diego install scripts can be found [here](https://network.pivotal.io/products/elastic-runtime). As of this writing, this script only supports versions 1.7.7 and above.

## Common usages

The following are common usages for this script.

### Basic install

###### Command Line
```DOS
> .\InstallDiego.ps1
```

Calling the script as such will cause the system to prompt the user for all non defaulted fields (`ip`, `password`).

### Prompting install

###### Command Line
```DOS
> .\InstallDiego.ps1 -prompt
```

Much like the **Basic Install** except this will prompt the user for all fields. A default value may be provided.

### File based installation

###### Properties file definition
```DOS
password=<password>
ip=<BOSH Server>
```

###### Command Line
```DOS
> .\InstallDiego.ps1 -properties <path to a properties file>
```

This installation allows the user to provide a file which holds the known field values. This usage is nice for installing multiple Diego servers.

### Using unzipped Diego Install.

###### Command Line
```DOS
> .\InstallDiego.ps1 -contents <path to the diego files>
```

If the Diego install archive is already unzipped. This flag will allow the user to do use the contents without needing to rezip the files.

## Fields
The following are the set of parameters and their details.

#### diego
   * Type: `Version`
   * Default: `1.7.7`
   * Will prompt: *Never*
   * Ignored when `contents` is set
   * Properties file label: **diego**

Set the Diego version. This does nothing except help out with the zip file identification.

#### properties
   * Type: `File Path`
   * Default: `""`
   * Will prompt: *Never*

Set the properties file to use.

The following are the avaiable properties defines:

| Label        | Default    |
| ------------:|:---------- |
| **diego**    | `1.7.7`    |
| **user**     | `director` |
| **password** | *None*     |
| **ip**       | *None*     |
| **port**     | `25555`    |

#### user
   * Type: `String`
   * Default: `director`
   * Will prompt: *When* `prompt` *flag is set*
   * Properties file label: `user`

Set the BOSH Administrator name.

#### password
   * Type: `String`
   * Default: *None*
   * Will prompt: *When no value is specified in the command line or properties file*
   * Properties file label: `password`

Set the BOSH Administrator password.

#### ip
   * Type: `IP Address` *or* `Machine Name`
   * Default: *None*
   * Will prompt: *When no value is specified in the command line or properties file*
   * Properties file label: `ip`

Set the BOSH Manager server IP.

**NOTE:** The machine name versions of this field was not tested, but should work.

#### port
   * Type: `Integer` *between 1 and 65535*
   * Default: `25555`
   * Will prompt: *When* `prompt` *flag is set*
   * Properties file label: `port`

Set the BOSH Manager server port.
#### contents
   * Type: `Folder Path`
   * Default: *None*
   * Will prompt: *Yes*
   * Properties file label: `contents`

Defines the location of the folder where the diego installation contents reside. Without this defines the script will ask for the location of a zip file where the files are located, it will then automatically extract the contents, locate and run the scripts contained.
 
#### mode
   * Type: `Enumeration` *As described below*
   * Default: `Install`
   * Will prompt: `Never`

Set the installation mode. The following is the possible options for this property.

| Setting Name | Description |
| ------------:| ----------- |
| `Install`    | Install the Diego installation. If this is run multiple times, the script will just re-run the standard sequence. |
| `Reinstall`  | Perform the uninstall sequence then the install sequence. |
| `Uninstall`  | Remove the applications that were added in the install sequence. If this is run without a previous install, no work will be done. |

**Note:** These values are case sensitive.

#### ignoreoscheck
   * Type: `Flag`
   * Default: *Unset*
   * Will prompt: `Never`.

If set, ignore any OS checks, this is for testing purposes only.

#### ignoreipcheck
   * Type: `Flag`
   * Default: *Unset*
   * Will prompt: *If test fails*.

If set, ignore the BOSH IP Address and do not test to see if the machine is reachable. If this is not set and the BOSH server is unreachable, then a prompt will ask if you would like to continue.

#### prompt
   * Type: `Flag`
   * Default: *Unset*
   * Will prompt: `Never`.

Show all promptable items when they are requested by the script. This will allow the user to override the defaults when they are not specified on the command line or properties file.

#### cleanup
   * Type: `Flag`
   * Default: *Unset*
   * Will prompt: `Never`.

Cleanup any created files.

#### help
   * Type: `Flag`
   * Default: *Unset*
   * Will prompt: `Never`.

Show the help screen and exit out.

#### skiptest
   * Type: `Flag`
   * Default: *Unset*
   * Will prompt: `Never`.

Skip the installation test sequence. This only applies to the `Install` and `Reinstall` modes.
