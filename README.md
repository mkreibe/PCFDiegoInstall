## Parameters
The following are the set of parameters, their affect and any constraints.
##### diego [Optional]
   * Default: `1.7.7`.
   * Will prompt: Never.
   * Ignored when `contents` is set.
   * Properties file label: **diego**.

Set the Diego version. This does nothing except help out with the zip file identification.

##### properties [Optional]
   * Default: `""`
   * Will prompt: `Never`.

Set the properties file to use.

The following are the avaiable properties defines:

| Label        | Default    |
| ------------:|:---------- |
| **diego**    | `1.7.7`    |
| **user**     | `director` |
| **password** | *None*     |
| **ip**       | *None*     |
| **port**     | `25555`    |

##### user
   * Default: `director`
   * Will prompt: When `prompt` flag is set.
   * Properties file label: `user`.

Set the BOSH Administrator name.

##### password
   * Default: *None*
   * Will prompt: When no value is specified in the command line or properties file.
   * Properties file label: `password`.

Set the BOSH Administrator password.

##### ip
   * Default: *None*
   * Will prompt: When no value is specified in the command line or properties file.
   * Properties file label: `ip`.

Set the BOSH Manager server IP.

##### port
   * Default: `25555`
   * Will prompt: When `prompt` flag is set.
   * Properties file label: `port`.

Set the BOSH Manager server port.
##### contents

##### mode
##### ignoreoscheck
##### ignoreipcheck
##### prompt
##### cleanup
Cleanup all 
##### help
Show the help screen. This overrides all over inputs.
##### skiptest
Skip the installation test sequence.
