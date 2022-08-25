# First parameter: WSL distro name
# Second parameter: Ubuntu code name

# ./wsl-ubuntu-vm.ps1 Ubuntu jammy

if ($args[0]) {
    $distroName = $args[0]
} else {
    $distroName = "Ubuntu"
}

if ($args[1]) {
    $ubuntuCodeName = $args[1]
} else {
    $ubuntuCodeName = "jammy"
}


$tarFileDownloadLocation = "$env:TEMP\ubuntu"
$wslInstallationPath = "$env:USERPROFILE\wsl\$distroName\"

if (-not(Test-Path -Path "$tarFileDownloadLocation.tar.gz" -PathType Leaf | Out-null)) {
    echo "Downloading Ubuntu $ubuntuCodeName"
    curl.exe -L -o "$tarFileDownloadLocation.tar.gz" "https://cloud-images.ubuntu.com/$ubuntuCodeName/current/$ubuntuCodeName-server-cloudimg-amd64-wsl.rootfs.tar.gz"
}


echo "Importing WSL distro"
New-Item -Path "$env:USERPROFILE\wsl" -Name "$distroName" -Force -ItemType Directory | Out-Null
wsl --import "$distroName" --version 2 $wslInstallationPath "$tarFileDownloadLocation.tar.gz"