Param (
[Parameter(Mandatory=$True)][ValidateNotNull()][string]$wslName,
[Parameter(Mandatory=$True)][ValidateNotNull()][string]$wslInstallationPath,
[Parameter(Mandatory=$True)][ValidateNotNull()][string]$username,
[Parameter(Mandatory=$True)][ValidateNotNull()][string]$installAllSoftware
)
write-host $env:Path

Set-Location $PSScriptRoot

wsl --update
wsl --shutdown
wsl --set-default-version 2

# create staging directory if it does not exists

Expand-Archive .\staging\$wslName.zip .\staging\$wslName

if (-Not (Test-Path -Path $wslInstallationPath)) {
    mkdir $wslInstallationPath
}
wsl --import $wslName $wslInstallationPath .\staging\$wslName\install.tar.gz

#Remove-Item $PSScriptRoot\staging\$wslName.zip
#Remove-Item -r $PSScriptRoot\staging\$wslName\

# Update the system
wsl -d $wslName -u root bash -ic "apt update; apt upgrade -y"

# create your user and add it to sudoers
wsl -d $wslName -u root bash -ic "./scripts/config/system/createUser.sh $username ubuntu"

# ensure WSL Distro is restarted when first used with user account
wsl -t $wslName

if ($installAllSoftware -ieq $true) {
    wsl -d $wslName -u root bash -ic "./scripts/config/system/sudoNoPasswd.sh $username"
    wsl -d $wslName -u root bash -ic ./scripts/install/installBasePackages.sh
    wsl -d $wslName -u $username bash -ic ./scripts/install/installAllSoftware.sh
    wsl -d $wslName -u root bash -ic "./scripts/config/system/sudoWithPasswd.sh $username"
}
