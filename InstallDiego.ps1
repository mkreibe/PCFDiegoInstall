# Install Diego onto a windows machine script.
$diego_version = '1.7.7'
$debug = $false
$do_cleanup = $true

Clear-Host

$pivotal_url = 'https://network.pivotal.io/products/elastic-runtime'
$unzip_location = 'C:\diego-installs'
$user = [Environment]::UserName;
$zip_file = "C:\Users\$($user)\Downloads\DiegoWindows$($diego_version).zip"
$zip_structure = 'DiegoWindows'
$port = 25555

$input_color = 'Green'
$info_color = 'Gray'
$action_color = 'DarkYellow'
$debug_color = 'Red'

# Show setup.
Write-Host "
 ____  _                _____        _ _ _ _       _               
|    \|_|___ ___ ___   |     |___   | | | |_|___ _| |___ _ _ _ ___ 
|  |  | | -_| . | . |  |  |  |   |  | | | | |   | . | . | | | |_ -|
|____/|_|___|_  |___|  |_____|_|_|  |_____|_|_|_|___|___|_____|___|
            |___|               
"
if($debug -or -not $do_cleanup) {
    Write-Host "   Flags [Debug: $debug] [Cleanup: $do_cleanup] `n" -ForegroundColor $debug_color
}

# Check powershell version.
$psver = $PSVersionTable.PSVersion;
Write-Host "Powershell [Version: $psver]" -ForegroundColor $info_color
if($psver.Major -lt 4) {
  $shell = New-Object -ComObject Wscript.Shell
  $shell.Popup("You must be running Powershell version 4 or greater", 5, "Invalid Powershell version", 0x30)
  Write-Host "You must be running Powershell version 4 or greater"
  exit(-1)
}

#Check OS.
$osver = [System.Environment]::OSVersion.Version
Write-Host "Operating System [Version: $osver] [Platform: $([System.Environment]::OSVersion.Platform)]" -ForegroundColor $info_color

# Get the zip and put it somewhere.
# TODO: in the future we may want to add a
#         Invoke-WebRequest $pivotal_url -OutFile $zip_staging
#       type of construct that would auto download the file.
Write-Host "`nDownload the zip from: $pivotal_url" -ForegroundColor $action_color
Write-Host "Enter the location of the zip file [$($zip_file)]: " -NoNewline -ForegroundColor $input_color
$prompt = Read-Host
if (!$prompt -eq "") { $zip_file = $prompt }

if(Test-Path $unzip_location) {
    Write-Host "Removing remnants for unzip location." -ForegroundColor $info_color
    Remove-Item -path $unzip_location -Force -Recurse -Confirm:$false
}

Write-Host "Unzipping $($unzip_location) ..." -ForegroundColor $info_color
Expand-Archive $zip_file -Dest $unzip_location

# Extract the file.
$setup_file_location = "$unzip_location\$zip_structure\setup.ps1"
Write-Host "Executing $($setup_file_location) ..." -ForegroundColor $info_color
if(-not $debug) {
    Invoke-Expression "$setup_file_location"
} else {
    Write-Host "   Debugging, Skipping." -ForegroundColor $debug_color
}

# Call the generator.
Write-Host "Enter the user name [$($user)]: " -NoNewline -ForegroundColor $input_color
$prompt = Read-Host
if (!$prompt -eq "") { $user = $prompt }

$password = Read-Host 'Enter the users password' -AsSecureString
Write-Host "Password captured" -ForegroundColor $input_color

Write-Host 'Enter the BOSH Director URL: ' -NoNewline -ForegroundColor $input_color
$url = Read-Host

Write-Host "Enter the port [$($port)]: " -NoNewline -ForegroundColor $input_color
$prompt = Read-Host
if (!$prompt -eq "") { $port = $prompt }

$generate_file_location = "$unzip_location\$zip_structure\generate.exe"

Write-Host "Executing $generate_file_location --boshUrl https://$($user):********@$($url):$($port) -outputDir $unzip_location ..." -ForegroundColor $info_color
if(-not $debug) {
    $unsecure = $password | ConvertFrom-SecureString
    Invoke-Expression "$generate_file_location --boshUrl https://$($user):$($unsecure)@$($url):$($port) -outputDir $unzip_location"
} else {
    Write-Host "   Debugging, Skipping." -ForegroundColor $debug_color
}

# Invoke the install 
$install_file_location = "$unzip_location\$zip_structure\install.bat"
Write-Host "Invoking $install_file_location ..." -ForegroundColor $info_color
if(-not $debug) {
    Invoke-Expression "$install_file_location"
} else {
    Write-Host "   Debugging, Skipping." -ForegroundColor $debug_color
}

# Cleanup!
if($do_cleanup) {
    Write-Host "Cleaning up." -ForegroundColor $info_color
    if(Test-Path $unzip_location) {
        Remove-Item -path $unzip_location -Force -Recurse -Confirm:$false
    }
}