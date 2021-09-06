param(
    [switch]$help,
    [switch]$forceRecreateBuildScripts,
    [switch]$build,
    [switch]$run,
    [switch]$runDedicated
)

$ErrorActionPreference = 'Stop'

# Catering to windows powershell.  Prefer using powershell core, but if you don't have that, we'll do our best
if(-not $IsLinux -and -not $IsMacOS -and -not $IsWindows) {
    $IsWindows = $true
}

if($help) {
    write-host ''
    write-host -ForegroundColor Green -BackgroundColor Black 'Welcome to SRB2Kart developer shell'
    write-host ''
    write-host 'This is a PowerShell where you can run ./setup-dev-environment.ps1'
    write-host './setup-dev-environment.ps1 is a script to automatically compile srb2kart on Windows.'
    write-host 'It will automatically download and configure the necessary compiler tools and SRB2Kart assets.'
    write-host 'To setup compiler tools and assets:'
    write-host '    ./setup-dev-environment.ps1'
    write-host 'To also build and run the game:'
    write-host '    ./setup-dev-environment.ps1 -build -run'
    write-host 'To force a cmake re-generate:'
    write-host '    ./setup-dev-environment.ps1 -forceRecreateBuildScripts'
    write-host ''
}

$buildDir = "$PSScriptRoot/build"
$cmakeToolchain = "MinGW Makefiles"
$binName = "srb2kart.exe"
if($IsLinux) {
    $buildDir = "$PSScriptRoot/build-linux"
    $cmakeToolchain = "Unix Makefiles"
    $binName = "srb2kart"
}

$toolchainBaseDir = "$PSScriptRoot/toolchain"
$toolchainDownloadsDir = "$toolchainBaseDir/downloads"

if($IsWindows) {
    $cmakeZipDownload = "$toolchainDownloadsDir/cmake.zip"
    $cmakeExtractDir = "$toolchainBaseDir/cmake"
    $cmakeZipUri = 'https://github.com/Kitware/CMake/releases/download/v3.21.2/cmake-3.21.2-windows-x86_64.zip'
    $cmakeBinDir = "$cmakeExtractDir/cmake-3.21.2-windows-x86_64/bin"
    $cmakeCommand = "$cmakeBinDir/cmake.exe"
    if(-not (test-path $cmakeCommand)) {
        if (-not (test-path $cmakeZipDownload)) {
            Invoke-WebRequest -uri $cmakeZipUri -OutFile $cmakeZipDownload
        }
        Expand-Archive $cmakeZipDownload $cmakeExtractDir
    }
}

$installerPath = "$PSScriptRoot/assets/srb2kart-v13-Installer.exe"
$installerZipUri = 'https://github.com/STJr/Kart-Public/releases/download/v1.3/srb2kart-v13-Installer.exe'
$installerExtractedPath = "$PSScriptRoot/assets/installer"
if (-not (Test-Path $installerExtractedPath)) {
    echo "Assets from the SRB2Kart installer not found.  Attempting to extract..."
    if (-not (Test-Path $installerPath)) {
        echo "Installer not found.  Downloading..."
        Invoke-WebRequest -uri $installerZipUri -OutFile $installerPath
    }
    Expand-Archive -Path $installerPath -DestinationPath $installerExtractedPath
    echo "Extracted installer $installerPath into $installerExtractedPath"
}

if($IsWindows) {
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
}

if($IsWindows) {
    # TODO avoid adding these every time; after the first invocation in a shell, they're already there
    $env:Path = "$mingwBinDir;$cmakeBinDir;$($env:Path)"
}

if($forceRecreateBuildScripts) {
    remove-item -Recurse $buildDir
    new-item -ItemType Directory $buildDir/bin
}

if(-not (test-path $buildDir/bin/chars.kart)) {
    Expand-Archive -Path $installerPath -DestinationPath $buildDir/bin
    remove-item $buildDir/bin/srb2kart.exe
}

if(-not (test-path $buildDir/CMakeCache.txt)) {
    cmake -B $buildDir -G $cmakeToolchain
}

if($build) {
    cmake --build $buildDir --config Debug -j 10 --
}
if($run -or $runDedicated) {
    $extraArgs = @()
    if($runDedicated) {
        $extraArgs = @('-dedicated')
    }
    $beforePwd = $PWD.Path
    try {
        cd $buildDir/bin
        echo $PWD.Path
        & ./$binName @extraArgs
    } finally {
        cd $beforePwd
    }
}
