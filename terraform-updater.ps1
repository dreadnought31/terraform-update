<#
.SYNOPSIS
	Script to auto-update terraform to latest version

.DESCRIPTION: 
	This script will check for the latest verSion of terraform and download it to a local folder that you specify.
        "amd64" in the script will download the 64 bit version but if you need the 32bit one put in 386 instead. 
	It will also add in the environment variable "C:\terraform" as well if not there already.
	 You will need to create the folder to download the script to if not already there and change the path location in the script.
 
.OUTPUT:
       This is the output you should expect.

 Directory: C:\


Mode                 LastWriteTime         Length Name                                                                                                                                                                                                                                                                                                      
----                 -------------         ------ ----                                                                                                                                                                                                                                                                                                      
d-----        22/01/2024     12:49                terraform                                                                                                                                                                                                                                                                                                 
Folder 'C:\terraform' created.
Terraform could not be located in C:\terraform\

Downloading latest version
Installing latest terraform
Remove zip file
The new path (C:\terraform\) has been added to the Path environment variable.

This is the output if you already have the folder and current version installed.

PS C:\WINDOWS\system32> D:\Downloads\tfupdater.ps1
Folder '' already exists.
Latest Terraform already installed.

Current tf version: 1.7.0
Latest tf Version: 1.7.0
The new path (C:\terraform\) already exists in the Path environment variable.
#>

# Set parameters
param(
	# Terraform path
	[string] $tf_path = "C:\terraform",

	# Terraform Arch to be downloaded
	[string] $tf_arch = "amd64"
)

# Function to check if a folder exists and create it if not
function create_folder_if_not_exists($tf_path) {
    if (-not (Test-Path -Path $tf_path -PathType Container)) {
        New-Item -Path $tf_path -ItemType Directory
        Write-Host "Folder '$tf_path' created."
    } else {
        Write-Host "Folder '$folder_path' already exists."
    }
}

# Check and create the Terraform folder
create_folder_if_not_exists $tf_path

$tf_release_url = "https://api.github.com/repos/hashicorp/terraform/releases/latest"

# Check if last "\" was provided in $tf_path, if it was not, add it
if (-not $tf_path.EndsWith("\")){
	$tf_path = $tf_path+"\"
}

# Get terraform version
function get_cur_tf_version (){
	<#
	.SYNOPSIS
		Function returns current terrafom versions from "terraform version" command.
	#>
	# Regex for version number
	[regex]$regex = '\d+\.\d+\.\d+'
	
	# Build terraform command and run it
	$command = "$tf_path" + "terraform.exe"
	$version = &$command version | Write-Output

	# Match and return versions
	[string]$version -match $regex > $null
	return $Matches[0]
}

function get_latest_tf_version() {
	<#
	.SYNOPSIS
		Function will get latest version number from github page
	.LINK
		https://api.github.com/repos/hashicorp/terraform/releases/latest
	#>

	# Get web content and convert from JSON
	$web_content = Invoke-WebRequest -Uri $tf_release_url -UseBasicParsing |	ConvertFrom-Json

	return $web_content.tag_name.replace("v","")
}

function get_terraform () {
	<#
	.SYNOPSIS
		Function will download and install latest version of terraform
	.LINK
		https://releases.hashicorp.com/terraform/$(get_latest_tf_version)/terraform_$(get_latest_tf_version)_windows_$tf_arch.zip
	#>
	Write-Host "Downloading latest version"

	# Build download URL
	$url = "https://releases.hashicorp.com/terraform/$(get_latest_tf_version)/terraform_$(get_latest_tf_version)_windows_$tf_arch.zip"

	# Output folder (in location provided)
	$download_location = $tf_path + "terraform.zip"

	# Set TLS to 1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Download terraform
	Invoke-WebRequest -Uri $url -OutFile $download_location  > $null

	# Unzip terraform and replace existing terraform file
	Write-Host "Installing latest terraform"
	Expand-Archive -Path $download_location -DestinationPath $tf_path -Force

	# Remove zip file
	Write-Host "Remove zip file"
	Remove-Item $download_location -Force
}


# Check if terraform exists in $tf_path
if (-not (Test-Path ($tf_path + "terraform.exe"))){
	Write-Host "Terraform could not be located in $tf_path"
	Write-Host
	get_terraform
}

# Check if current version is different than latest version
elseif ((get_latest_tf_version) -ne (get_cur_tf_version)) {
	# Write basic info to sceen
	Write-Host "Current tf version: $(get_cur_tf_version)"
	Write-Host "Latest tf Version: $(get_latest_tf_version)"
	Write-Host
	get_terraform
}

# If versions match, display message
else {
	Write-Host "Latest Terraform already installed."
	Write-Host
	Write-Host "Current tf version: $(get_cur_tf_version)"
	Write-Host "Latest tf Version: $(get_latest_tf_version)"
}
# Get the current value of the Path variable
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)

# Check if the new path already exists in the Path variable
if ($currentPath -notlike "*$tf_path*") {
    # Append the new path to the existing value, separated by a semicolon
    $updatedPath = "$currentPath;$tf_path"

    # Set the updated Path variable
    [System.Environment]::SetEnvironmentVariable("Path", $updatedPath, [System.EnvironmentVariableTarget]::Machine)

    Write-Host "The new path ($tf_path) has been added to the Path environment variable."
} else {
    Write-Host "The new path ($tf_path) already exists in the Path environment variable."
}
