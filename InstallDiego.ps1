# Install Diego onto a windows machine script.
Param (
    [string] $diego,

    [string] $properties,

    [string] $user,
    [string] $password,
    [string] $ip,
    [int]    $port,
    [string] $contents,

    [string] $mode,

    [switch] $ignoreoscheck,
    [switch] $ignoreipcheck,
    [switch] $prompt,
    [switch] $cleanup,
    [switch] $help,
    [switch] $skiptest
)

<#
    Notes:
        (1) The '. { <script> } | Out-Null' construct prevents multiple results from being returned. This is a
            strange behaviour if Powershell.
#>

Set-Variable version -option Constant -value '1.0.0'
Set-Variable pivotal_url -option Constant -value 'https://network.pivotal.io/products/elastic-runtime'

Set-Variable input_color -option Constant -value 'Green'
Set-Variable info_color -option Constant -value 'DarkGray'
Set-Variable error_color -option Constant -value 'Red'
Set-Variable action_color -option Constant -value 'DarkYellow'

$program_names = ("DiegoWindows", "GardenWindows")

# Write the banner.
function Write-Banner {
    . {
        Clear-Host
        Write-Host "
         ____  _                _____        _ _ _ _       _               
        |    \|_|___ ___ ___   |     |___   | | | |_|___ _| |___ _ _ _ ___ 
        |  |  | | -_| . | . |  |  |  |   |  | | | | |   | . | . | | | |_ -|
        |____/|_|___|_  |___|  |_____|_|_|  |_____|_|_|_|___|___|_____|___|
                    |___|"

        Write-Host "`n    [Version: $version]`n" -ForegroundColor $info_color
    } | Out-Null
}

#Write the help.
function Write-Help {
    . {
        Write-Host ".\InstallDiego.ps1 "
        Write-Host "     [-diego <version>]      - Override the known Diego Version."

        Write-Host "     [-properties <file>]    - Defines the properties file."

        Write-Host "     [-user <user>]          - Define the BOSH Director Administrator Name."
        Write-Host "     [-password <password>]  - Define the BOSH Director Administrator Password."
        Write-Host "     [-ip <ip>]              - Define the BOSH Director IP Address."
        Write-Host "     [-port <port>]          - BOSH Director Port."
        Write-Host "     [-contents <folder>]    - Location of the unzipped Diego files."

        Write-Host "     [-mode <operation>]     - Change the mode of the script:"
        Write-Host "                                Reinstall - Preform the uninstall, then install steps."
        Write-Host "                                Install   - Install the diego programs."
        Write-Host "                                Uninstall - Remove the diego programs."

        Write-Host "     [-ignoreoscheck]        - Ignore the OS Check."
        Write-Host "     [-ignoreipcheck]        - Ignore the BOSH IP Check."
        Write-Host "     [-prompt]               - Prompt on values that are not explicitly set in the arguments."
        Write-Host "     [-cleanup]              - Cleanup the artifacts once the install is complete."
        Write-Host "     [-help]                 - Just print this help screen."

        Write-Host "`n"
    } | Out-Null
}

# Display an error.
function Display-Error([string][parameter(Mandatory=$true, position=0)] $title, [string][parameter(Mandatory=$true, position=1)] $message) {
    . {
        # TODO: is a popup nessasary?
        $shell = New-Object -ComObject Wscript.Shell
        $shell.Popup($message, 5, $title, 0x30)
        Write-Host $message -ForegroundColor $error_color
    } | Out-Null
}

# Check the mode.
function Get-Mode {
    . {
        if($mode -eq "") {
            $mode = 'Install'
        }

        if($mode -eq "Install" -or $mode -eq "Reinstall" -or $mode -eq "Uninstall") {
            Write-Host "Mode: $mode" -ForegroundColor $info_color
        } else {
            Display-Error "Invalid mode: $mode" "Only the following modes are allowed: Install, Uninstall, Reinstall"
        }
    } | Out-Null

    $mode
}

# Check the PowerShell version.
function Check-PowershellVersion {
    . {
        $result = $true
        Write-Host "Powershell [Version: $($PSVersionTable.PSVersion)]" -ForegroundColor $info_color
        if($PSVersionTable.PSVersion.Major -lt 4) {
            Display-Error "Invalid Powershell version" "You must be running Powershell version 4 or greater"
            $result = $false
        }
    } | Out-Null

    $result
}

# Check the execution policy
function Check-ExecutionPolicy {
    . {
        $result = $true
        $policy = Get-ExecutionPolicy
        Write-Host "Execution Policy: $policy" -ForegroundColor $info_color
        if($policy -ne "Unrestricted") {
            Display-Error "Invalid execution policy" "The execution policy must be unrestricted!`nCurrent policy: $($policy)"
            Write-Host "The execution policy must be unrestricted!" -ForegroundColor $error_color
            Write-Host "Run: `"Set-ExecutionPolicy Unrestricted -Scope CurrentUser`"" -ForegroundColor $info_color
            $result = $false
        }
    } | Out-Null

    $result
}

# Check the OS version
function Check-OperatingSystem {
    . {
        $os = Get-WmiObject -class Win32_OperatingSystem
        $major_minor = $os.Version.Substring(0, $os.Version.IndexOf('.', $os.Version.IndexOf('.') + 1)) # Get the second '.'

        Write-Host "Operating System [Version: $($os.Version) ($major_minor)] [Type: $($os.ProductType)]" -ForegroundColor $info_color
        $result = $true
        if($major_minor -ne '6.3' -or $os.ProductType -ne 3) {
            Display-Error "Invalid operating system" "Only Windows 2012 R2 is supported with this script."
            $result = $false
        }
    } | Out-Null

    $result
}

# Get the diego version
function Get-DiegoVersion([bool] $print = $true) {
    . {

        if($diego -eq $null -or $diego -eq "") {
            if($properties -ne "") {
                $props = ConvertFrom-StringData (Get-Content $properties -Raw)
                if($props -ne $null) {
                    $diego = $props.'diego'
                    Write-Host "Got Diego version from ($properties): $diego" -ForegroundColor $info_color
                }
            }

            if($diego -eq $null -or $diego -eq "") {
                $diego = '1.7.7'
            }
        }

        if($print) {
            Write-Host "Diego Version: $diego" -ForegroundColor $info_color
        }
    } | Out-Null

    $diego
}

# Ge the bosh port value.
function Get-BoshPort {
    . {
        if($port -eq 0) {
            $default = 25555
            if($prompt) {
                Write-Host "Enter the BOSH Director Machine port [$($default)]: " -NoNewline -ForegroundColor $input_color
                $value = Read-Host
                if ($value -eq "") {
                    $port = $default
                } else {
                    $port = $value
                }
            } else {
                if($properties -ne "") {
                    $props = ConvertFrom-StringData (Get-Content $properties -Raw)
                    if($props -ne $null) {
                        $port = $props.'port'
                        Write-Host "Got BOSH Director Machine port ($properties): $port" -ForegroundColor $info_color
                    }
                }

                if($port -eq 0) {
                    $port = $default
                }
            }
        } else {
            if($port -gt 0 -and $port -lt 65535) {
                Write-Host "Port: $port" -ForegroundColor $info_color
            } else {
                Display-Error "Invalid operating system" "Port must be between 0 and 65535 [value: $port]."
                $port = -1
            }
        }
    } | Out-Null

    $port
}

function Get-BoshUser {
    . {
        if($user -ne "") {
            Write-Host "User: $user" -ForegroundColor $info_color
        } else {
            $default = 'director'
            if($prompt) {
                Write-Host "Enter the BOSH Administrator [$($default)]: " -NoNewline -ForegroundColor $input_color
                $value = Read-Host
                if ($value -eq "") {
                    $user = $default
                } else {
                    $user = $value
                }
            } else {
                if($properties -ne "") {
                    $props = ConvertFrom-StringData (Get-Content $properties -Raw)
                    if($props -ne $null) {
                        $user = $props.'user'
                        Write-Host "Got BOSH Administrator ($properties): $user" -ForegroundColor $info_color
                    }
                }

                if($user -eq "") {
                    $user = $default
                }
            }
        }
    } | Out-Null

    $user
}

function Get-BoshPassword {
    . {
        if($password -eq "") {
            if($properties -ne "") {
                $props = ConvertFrom-StringData (Get-Content $properties -Raw)
                if($props -ne $null) {
                    $password = $props.'password'
                    Write-Host "Got BOSH Administrator  password ($properties): $password" -ForegroundColor $info_color
                }
            }

            if($password -eq "") {
                Write-Host 'Enter the BOSH Administrator password: ' -NoNewline -ForegroundColor $input_color
                $password = Read-Host
            }
        }
    } | Out-Null

    $password
}

function Get-BoshIP {
    .{
        if($ip -ne "") {
            Write-Host "BOSH Manager IP Address: $ip" -ForegroundColor $info_color
        } else {

            if($properties -ne "") {
                $props = ConvertFrom-StringData (Get-Content $properties -Raw)
                if($props -ne $null) {
                    $ip = $props.'ip'
                    Write-Host "Got BOSH Manager IP Address ($properties): $ip" -ForegroundColor $info_color
                }
            }

            if($ip -eq "") {
                #Check IP address
                Write-Host "Current machine IP Addresses:" -ForegroundColor $info_color
                $default = ""
                foreach($item in Get-NetIPAddress) {
                    if($default -eq "" -and $item.AddressFamily -eq "IPv4") {
                        $default = "$($item.IPAddress.Substring(0, $item.IPAddress.LastIndexOf('.'))).50"
                    }
                    Write-Host "`t$($item.IPAddress)" -ForegroundColor $info_color
                }

                if($default -ne "") {
                    Write-Host "Enter the BOSH Director Machine IP address [$($default)]: " -NoNewline -ForegroundColor $input_color
                } else {
                    Write-Host "Enter the BOSH Director Machine IP address: " -NoNewline -ForegroundColor $input_color
                }

                $value = Read-Host
                if ($value -eq "") {
                    $ip = $default
                } else {
                    $ip = $value
                }
            }
        }

        if(-not $ignoreipcheck) {
            Write-Host "Testing avalability of BOSH director at: $ip." -ForegroundColor $info_color
            if(-not $(Test-Connection -Quiet -Count 2 -ComputerName $ip)) {
                Write-Host "Unable to reach ($ip). This may not be an error because ping could be disabled." -ForegroundColor $error_color
                Write-Host "  Ignore ping results [N]: " -NoNewline -ForegroundColor $input_color
                $value = Read-Host
                if(-not ($value.ToUpper() -eq "Y" -or $value.ToUpper() -eq "YES")) {
                    $ip = ""
                }
            }
        }

    } | Out-Null

    $ip
}

function Get-ContentFolder {
    . {
        $was_unzipped = $false
        if($contents -ne "") {
            Write-Host "Contents: $contents" -ForegroundColor $info_color
        } else {

            if($properties -ne $null) {
                $props = ConvertFrom-StringData (Get-Content $properties -Raw)
                if($props -ne $null) {
                    $contents = $props.'contents'
                    Write-Host "Got Contents ($properties): $contents" -ForegroundColor $info_color
                }
            }
        
            if($contents -eq "") {
                # Get the zip and put it somewhere.
                # TODO: in the future we may want to add a
                #         Invoke-WebRequest $pivotal_url -OutFile $zip_staging
                #       type of construct that would auto download the file.

                Write-Host "`nDownload the zip from: $pivotal_url" -ForegroundColor $action_color
                $zip_file = "C:\Users\$([Environment]::UserName)\Downloads\DiegoWindows$(Get-DiegoVersion($false)).zip"
                Write-Host "Enter the location of the zip file [$($zip_file)]: " -NoNewline -ForegroundColor $input_color
                $value = Read-Host
                if ($value -ne "") { $zip_file = $value }

                # Create a temp file
                $contents = Join-Path $([System.IO.Path]::GetTempPath()) $([System.Guid]::NewGuid())
                Write-Host "Creating temp folder: $contents" -ForegroundColor $info_color
                New-Item $contents -type directory -Force | Out-Null

                Write-Host "Unzipping $zip_file -> $contents" -ForegroundColor $info_color
                $shell = New-Object -com Shell.Application
                $zip = $shell.Namespace($zip_file)
                foreach($item in $zip.items()) {
                    $shell.Namespace($contents).CopyHere($item)
                }

                $was_unzipped = $true
            }
        }
    } | Out-Null

    ($contents, $was_unzipped)
}

function Find-File($folder, $filename) {
    . {
        $setup_file = Get-ChildItem $folder -Recurse -Filter $filename | Select -First 1
        $full_name = $setup_file.FullName
    } | Out-Null

    $full_name
}

function Call-Executable($folder, $filename, $arguments = "") {
    .{ 
        $full_name = Find-File $folder $filename
        Write-Host "Executing $($full_name) ..." -ForegroundColor $info_color
        Unblock-File -Path "$full_name" -Confirm:$false
        $output = Invoke-Expression "$full_name $arguments"
    } | Out-Null

    $output
}

function Call-Batch($folder, $filename, $working_folder) {
    . {
        $full_name = Find-File $folder $filename
        $batch = Start-Process -FilePath $full_name -Wait -RedirectStandardOutput $(Join-Path $folder 'install_log.txt') -RedirectStandardError $(Join-Path $folder 'install_err.txt') -WorkingDirectory $working_folder
    }

    $batch.ExitCode
}

#cleanup the temp folders.
function Cleanup($folder, $was_unzipped) {
    . {
        if($was_unzipped -and $(Test-Path $folder)) {
            Write-Host "Cleaning up: $folder" -ForegroundColor $info_color
            Remove-Item -path $folder -Force -Recurse -Confirm:$false
        }
    } | Out-Null
}

function Uninstall {
    . {
        Write-Host "Programs to uninstall: $($program_names.Length)" -ForegroundColor $info_color
        foreach($progName in $program_names) {
            $program = Get-WmiObject Win32_Product -Filter "Name = '$progName'"
            Write-Host "Uninstalling [$($program.Name), Version=$($program.Version), Id=$($program.IdentifyingNumber)]" -ForegroundColor $info_color
            $program.Uninstall()
        }
        Write-Host "Completed Uninstall" -ForegroundColor $info_color
    } | Out-Null
}

function Test-Install {
    . {
        foreach($service in Get-WmiObject -Class Win32_Service -Filter "DisplayName LIKE 'CF %'") {
            Write-Host "Service [Name: $($service.Name) '$($service.DisplayName)', Mode:$($service.StartMode)]: Status: $($service.Status) State: $($service.State)" -ForegroundColor $info_color
        }
    } | Out-Null
}

function Install {
    . {
        $boshUser = Get-BoshUser
        $boshPassword = Get-BoshPassword
        $boshIp = Get-BoshIP
        $boshPort = Get-BoshPort

        if($boshUser -ne "" -and $boshPassword -ne "" -and $boshIp -ne "" -and $boshPort -ne -1) {
            ($rootFolder, $was_unzipped) = Get-ContentFolder

            Write-Host "Changing Folders: [Old: $($orig_folder)] [New: $($rootFolder)] ..." -ForegroundColor $info_color
            Set-Location -Path $rootFolder

            $output = Call-Executable $rootFolder "setup.ps1" "-quiet"
            Write-Host "Generated local mof file: $output"

            $working_folder = (Get-ChildItem $rootFolder -Recurse -Filter "*.msi" | Select -First 1).DirectoryName
            Write-Host "Batch script working folder: $working_folder"

            $output = Call-Executable $rootFolder "generate.exe" "--boshUrl https://$($boshUser):$($boshPassword)@$($boshIp):$($boshPort) -outputDir $working_folder"
            Write-Host "Generate output: $output" -ForegroundColor $info_color

            $output =  Call-Batch $rootFolder "install.bat" $working_folder
            if($output -ne $null) {
                Write-Host "   Exit Code: $output" -ForegroundColor $error_color
                $output = NET HELPMSG $output
                Write-Host "   Network Error: $output" -ForegroundColor $error_color
                Write-Host "   Logs:`n$(TYPE install_err.txt)" -ForegroundColor $info_color
            } else {
                Write-Host "   Batch script completed successfully" -ForegroundColor $info_color
            }

            if(-not $skiptest) {
                Test-Install
            }
        }
    } | Out-Null
}

function main {
    . {
        # Startup with the banner.
        Write-Banner

        # if -help was provided, do nothing else other then to print the help.
        if($help) {
            Write-Help
        } else {

            # Check the mode.
            $runtimeMode = Get-Mode
            if(($runtimeMode -ne $null) -and
                $(Check-PowershellVersion) -and
                $(Check-ExecutionPolicy) -and
                $($ignoreoscheck -or $(Check-OperatingSystem))) {

                Get-DiegoVersion

                if($runtimeMode -eq "Reinstall" -or $runtimeMode -eq "Uninstall") {
                    Write-Host "Performing Uninstall" -ForegroundColor $info_color
                    Uninstall
                }

                if($runtimeMode -eq "Reinstall" -or $runtimeMode -eq "Install") {
                    Write-Host "Performing install" -ForegroundColor $info_color
                    $orig_folder = Get-Location
                    Install
                    Write-Host "Changing Folders back to the original [$($orig_folder)] ..." -ForegroundColor $info_color
                    Set-Location -Path $orig_folder

                    if($cleanup) {
                        Cleanup $rootFolder $was_unzipped
                    }
                }
            }
        }
    } | Out-Null
}

main
