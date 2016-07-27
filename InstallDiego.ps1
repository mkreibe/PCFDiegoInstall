# Install Diego onto a windows machine script.
Param (
    [string] $diego,
    [switch] $debug,
    [switch] $dirty,
    [switch] $help,
    [switch] $usedefaults,
    [string] $folder,
    [string] $user,
    [string] $password,
    [string] $ip,
    [int] $port
)

Clear-Host

$pivotal_url = 'https://network.pivotal.io/products/elastic-runtime'

$input_color = 'Green'
$info_color = 'DarkGray'
$error_color = 'Red'
$action_color = 'DarkYellow'
$debug_color = 'Magenta'

# Show setup.
Write-Host "
 ____  _                _____        _ _ _ _       _               
|    \|_|___ ___ ___   |     |___   | | | |_|___ _| |___ _ _ _ ___ 
|  |  | | -_| . | . |  |  |  |   |  | | | | |   | . | . | | | |_ -|
|____/|_|___|_  |___|  |_____|_|_|  |_____|_|_|_|___|___|_____|___|
            |___|               
"

if($help) {
    Write-Host ".\InstallDiego.ps1 "
    Write-Host "     [-diego <DIEGO_VERSION>]"
    Write-Host "     [-debug]"
    Write-Host "     [-dirty]"
    Write-Host "     [-help]"
    Write-Host "     [-usedefaults]"
    Write-Host "     [-folder <Location of the unzipped Diego files>]"
    Write-Host "     [-user <BOSH Director Administrator Name>]"
    Write-Host "     [-password <BOSH Director Administrator Password>]"
    Write-Host "     [-ip <BOSH Director IP Address>]"
    Write-Host "     [-port <BOSH Director Port>]"
    Write-Host "`n"
    exit(0);
}

# Run the rest of the script.
if($debug -or $dirty -or $usedefaults) {
    Write-Host "   Flags [Debug: $debug] [Cleanup: $(-not $dirty)] [Use Defaults: $usedefaults]`n" -ForegroundColor $debug_color
}

Write-Host "Checking overrides..." -ForegroundColor $info_color 

if($diego -eq $null -or $diego -eq "") {
    $diego = '1.7.7'
} else {
    Write-Host "   Diego Version: $diego" -ForegroundColor $info_color
}

# Check the port
if($port -eq 0) {
    $port = 25555
} else {
    if($port -gt 0 -and $port -lt 65535) {
        Write-Host "   Port: $port" -ForegroundColor $info_color
    } else {
        $shell = New-Object -ComObject Wscript.Shell
        $shell.Popup("Port must be between 0 and 65535.", 5, "Invalid port", 0x30)
        Write-Host "Port must be between 0 and 65535 [value: $port]." -ForegroundColor $error_color
        exit(-1)
    }
}

if($user -eq "") {
    $user = 'director'
} else {
    Write-Host "   User: $user" -ForegroundColor $info_color
}

if($password -ne "") {
    Write-Host "   Password: ********" -ForegroundColor $info_color
}

if($ip -ne "") {
    Write-Host "   IP Address: $ip" -ForegroundColor $info_color
}

if($folder -ne "") {
    Write-Host "   Diego Contents: $folder" -ForegroundColor $info_color
}

# Write the diego version.
Write-Host "Assumed Diego [Version: $diego]" -ForegroundColor $info_color

# Check powershell version.
$psver = $PSVersionTable.PSVersion;
Write-Host "Powershell [Version: $psver]" -ForegroundColor $info_color
if($psver.Major -lt 4) {
    $shell = New-Object -ComObject Wscript.Shell
    $shell.Popup("You must be running Powershell version 4 or greater", 5, "Invalid Powershell version", 0x30)
    Write-Host "You must be running Powershell version 4 or greater" -ForegroundColor $error_color
    exit(-1)
}

$policy = Get-ExecutionPolicy
if($policy -ne "Unrestricted") {
    $shell = New-Object -ComObject Wscript.Shell
    $shell.Popup("The execution policy must be unrestricted!`nCurrent policy: $($policy)", 5, "Invalid execution policy", 0x30)
    Write-Host "The execution policy must be unrestricted!" -ForegroundColor $error_color
    Write-Host "Run: `"Set-ExecutionPolicy Unrestricted -Scope CurrentUser`"" -ForegroundColor $info_color
    exit(-1)
}

#Check OS.
$osver = [System.Environment]::OSVersion.Version
Write-Host "Operating System [Version: $osver] [Platform: $([System.Environment]::OSVersion.Platform)]" -ForegroundColor $info_color

#Check IP address
Write-Host "IP Addresses:" -ForegroundColor $info_color
$assume_bosh = $false
foreach($item in Get-NetIPAddress) {
    if($ip -eq "" -and $item.AddressFamily -eq "IPv4") {
        $ip = "$($item.IPAddress.Substring(0, $item.IPAddress.LastIndexOf('.'))).50"
        $assume_bosh = $true
    }
    Write-Host "`t$($item.IPAddress)" -ForegroundColor $info_color
}

if($assume_bosh) {
    Write-Host "Assumed BOSH Director IP Address: $ip" -ForegroundColor $info_color
}

$was_unzipped = $false
if($folder -eq "") {
    # Get the zip and put it somewhere.
    # TODO: in the future we may want to add a
    #         Invoke-WebRequest $pivotal_url -OutFile $zip_staging
    #       type of construct that would auto download the file.
    $zip_file = "C:\Users\$([Environment]::UserName)\Downloads\DiegoWindows$($diego).zip"
    if(-not $usedefaults) {
        Write-Host "`nDownload the zip from: $pivotal_url" -ForegroundColor $action_color
        Write-Host "Enter the location of the zip file [$($zip_file)]: " -NoNewline -ForegroundColor $input_color
        $prompt = Read-Host
        if (!$prompt -eq "") { $zip_file = $prompt }
    }

    if(Test-Path $folder) {
        Write-Host "Removing remnants for unzip location ($folder)." -ForegroundColor $info_color
        Remove-Item -path $unzip_location -Force -Recurse -Confirm:$false
    }

    Write-Host "Unzipping $($folder) ..." -ForegroundColor $info_color
    if($psver.Major -ge 5) {
        Expand-Archive $zip_file -Dest $folder
    } else {
        New-Item $folder -type directory -Force | Out-Null
        $shell = New-Object -com Shell.Application
        $zip = $shell.Namespace($zip_file)
        foreach($item in $zip.items()) {
            $shell.Namespace($folder).copyhere($item)
        }
    }
    $was_unzipped = $true
}

# Move to the unzip location.
$orig_folder = Get-Location
Write-Host "Changing Folders: [Old: $($orig_folder)] [New: $($folder)] ..." -ForegroundColor $info_color
Set-Location -Path $folder

# Extract the file.
$setup_file_location = ".\setup.ps1"
Write-Host "Executing $($setup_file_location) ..." -ForegroundColor $info_color
if(-not $debug) {
    Unblock-File -Path "$setup_file_location" -Confirm:$false
    Invoke-Expression "$setup_file_location -quiet"
} else {
    Write-Host "   Debugging, Skipping." -ForegroundColor $debug_color
}

# Call the generator.
if(-not $usedefaults) {
    Write-Host "Enter the BOSH Administrator [$($user)]: " -NoNewline -ForegroundColor $input_color
    $prompt = Read-Host
    if (!$prompt -eq "") { $user = $prompt }
}

if(-not $usedefaults -and $password -ne "") {
    Write-Host 'Enter the BOSH Administrator password [********]: ' -NoNewline -ForegroundColor $input_color
    $prompt = Read-Host
    if (!$prompt -eq "") { $password = $prompt }
} elseif($password -eq "") {
    Write-Host 'Enter the BOSH Administrator password: ' -NoNewline -ForegroundColor $input_color
    $password = Read-Host
}

if(-not $usedefaults) {
    Write-Host "Enter the BOSH Director Machine IP address [$($ip)]: " -NoNewline -ForegroundColor $input_color
    $prompt = Read-Host
    if (!$prompt -eq "") { $ip = $prompt }
}

#TODO: ping the director machine.

if(-not $usedefaults) {
    Write-Host "Enter the BOSH Director Machine port [$($port)]: " -NoNewline -ForegroundColor $input_color
    $prompt = Read-Host
    if (!$prompt -eq "") { $port = $prompt }
}

$generate_file_location = ".\generate.exe"

Write-Host "Executing $generate_file_location --boshUrl https://$($user):********@$($ip):$($port) -outputDir . ..." -ForegroundColor $info_color
if(-not $debug) {
    Invoke-Expression "$generate_file_location --boshUrl https://$($user):$($password)@$($ip):$($port) -outputDir ."
} else {
    Write-Host "   Debugging, Skipping." -ForegroundColor $debug_color
}

# Invoke the install
$install_file_location = ".\install.bat"
Write-Host "Looking for $install_file_location ..." -ForegroundColor $info_color
if(Test-Path $install_file_location) {
    Write-Host "Injecting log to installer" -ForegroundColor $info_color
    Add-Content $install_file_location "`necho Complete!"

    Write-Host "Invoking $install_file_location ..." -ForegroundColor $info_color
    if(-not $debug) {
        $batch = Start-Process -FilePath $install_file_location -Wait -RedirectStandardOutput install_log.txt -RedirectStandardError install_err.txt -WorkingDirectory .

        # write the error code, error message and batch file on errors.
        if($batch.ExitCode -ne $null) {
            Write-Host "   Exit Code: $($batch.ExitCode)" -ForegroundColor $error_color
            $batch = NET HELPMSG $($batch.ExitCode)
            Write-Host "   Network Error: $($batch)" -ForegroundColor $error_color
            $file_contents = TYPE install_err.txt
            Write-Host "   Logs:`n$file_contents" -ForegroundColor $info_color
        } else {
            Write-Host "   Batch script completed successfully" -ForegroundColor $info_color
        }
    } else {
        Write-Host "   Debugging, Skipping." -ForegroundColor $debug_color
    }
} else {
    Write-Host "Something went wrong! There is no '$install_file_location' file." -ForegroundColor $error_color
}

# Cleanup!
Write-Host "Changing Folders back to the original [$($orig_folder)] ..." -ForegroundColor $info_color
Set-Location -Path $orig_folder

if(-not $dirty) {
    Write-Host "Cleaning up." -ForegroundColor $info_color
    if($was_unzipped -and $(Test-Path $folder)) {
        Remove-Item -path $folder -Force -Recurse -Confirm:$false
    }
}
