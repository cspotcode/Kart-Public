param(
    [switch]$forceRecreateBuildScripts,
    [switch]$build,
    [switch]$run
)

$ErrorActionPreference = 'Stop'

$toolchainBaseDir = "$PSScriptRoot/toolchain"
$toolchainDownloadsDir = "$toolchainBaseDir/downloads"
$cmakeZipDownload = "$toolchainDownloadsDir/cmake.zip"
$cmakeZipUri = 'https://github.com/Kitware/CMake/releases/download/v3.21.2/cmake-3.21.2-windows-x86_64.zip'
$cmakeExtractDir = "$toolchainBaseDir/cmake"
$cmakeBinDir = "$cmakeExtractDir/cmake-3.21.2-windows-x86_64/bin"
$cmakeCommand = "$cmakeBinDir/cmake.exe"

if(-not (test-path $cmakeCommand)) {
    if (-not (test-path $cmakeZipDownload)) {
        Invoke-WebRequest -uri $cmakeZipUri -OutFile $cmakeZipDownload
    }
    Expand-Archive $cmakeZipDownload $cmakeExtractDir
}

$installerPath = "$PSScriptRoot/assets/srb2kart-v13-Installer.exe"
$installerZipUri = 'https://github.com/STJr/Kart-Public/releases/download/v1.3/srb2kart-v13-Installer.exe'
$installerExtractedPath = "$PSScriptRoot/assets/installer"
if (-not (Test-Path $installerExtractedPath)) {
    echo "Assets from the SRB2Kart installer not found.  Attempting to extract..."
    if (-not (Test-Path $installerPath)) {
        echo "Installer not found.  Download the installer to $installerPath.  You do not need to run the installer; this script will extract the assets."
        Invoke-WebRequest -uri $installerZipUri -OutFile $installerPath
    }
    Expand-Archive -Path $installerPath -DestinationPath $installerExtractedPath
    echo "Extracted installer $installerPath into $installerExtractedPath"
}

$mingwInstallDir = "$toolchainBaseDir/mingw"
$mingwBinDir = "$mingwInstallDir/bin"
$mingwGetZip= "$toolchainDownloadsDir/mingw-get.zip"
$mingwGetZipUri = 'https://sourceforge.net/projects/mingw/files/Installer/mingw-get/mingw-get-0.6.2-beta-20131004-1/mingw-get-0.6.2-mingw32-beta-20131004-1-bin.zip/download'
$mingwGetExtractedDir = "$mingwInstallDir"
$mingwGetCommand = "$mingwGetExtractedDir/bin/mingw-get.exe"
$mingwMakeCommand = "$mingwInstallDir/bin/mingw32-make.exe"
if (-not (test-path $mingwMakeCommand)) {
    if (-not (test-path $mingwGetCommand)) {
        if (-not (test-path $mingwGetZip)) {
            if(-not (test-path $toolchainDownloadsDir)) { new-item -ItemType Directory $toolchainDownloadsDir }
            # Invoke-Webrequest does not work, possibly due to user-agent, possibly due to sourceforge server behavior with redirects
            $webclient = New-Object System.Net.WebClient
            $webclient.DownloadFile($mingwGetZipUri, $mingwGetZip)
        }
        Expand-Archive -Path $mingwGetZip -DestinationPath $mingwGetExtractedDir
    }
    & $mingwGetCommand install gcc mingw32-make
}

# TODO avoid adding these every time; after the first invocation in a shell, they're already there
$env:Path = "$mingwBinDir;$cmakeBinDir;$($env:Path)"

$buildDir = "$PSScriptRoot/build"
if($forceRecreateBuildScripts) {
    remove-item -Recurse $buildDir
    new-item -ItemType Directory $buildDir/bin
    Expand-Archive -Path $installerPath -DestinationPath $buildDir/bin
    remove-item $buildDir/bin/srb2kart.exe
}

if(-not (test-path $buildDir/CMakeCache.txt)) {
    cmake -B build -G "MinGW Makefiles"
}

if($build) {
    cmake --build build --config Debug -j 10 --
}
if($run) {
    & "$buildDir/bin/srb2kart.exe"
}