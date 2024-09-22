# Environment variables
# $env:cwd      => current working directory
# $env:core     => current core configuration
# $env:config   => current proxy configuration
# $env:mmdb     => current mmdb configuration

$env:cwd = Split-Path -Path $MyInvocation.MyCommand.Path
$env:cwd_root = $env:cwd + "/../"
$env:cwd_data = $env:cwd_root + "data/"



function Show-Menu {
    Clear-Host
    echo "Choose operation:"
    echo "1. update/download core 🚀"
    echo "2. update/download mmdb 🗄️"
    echo "3: update subscription 🔄"
    echo "4: setting uwp ⚙️"
    echo "5: run 🐱"
    echo "0: quit 🔚"

    $key = [System.Console]::ReadKey($true) # Read-Host "input your instruct"

    switch ($key.KeyChar) {

        '1' {
            Clear-Host
            echo "Start update/download core 🚀"

            Update-Core

            Pause
            Show-Menu
        }

        '2' {
            Clear-Host
            echo "Start update/download mmdb 🗄️"

            Update-MMDB

            Pause
            Show-Menu
        }
        '3' {
            Clear-Host
            echo "Start update subscription 🔄"


            Update-Subscription

            Pause
            Show-Menu
        }

        '4' {
            Clear-Host
            echo "Start setting uwp ⚙️"

            Open-UWP-Settings

            Pause
            Show-Menu
        }

        '5' {
            Clear-Host
            echo "Start running 🐱"

            Running-Cat

            Pause
            Show-Menu

        }


        '0' {
            Clear-Host
            exit
        }


        default {
            echo "`n invaild choose, try again"
            Pause
            Show-Menu
        }
    }
}

function Pause {
    echo "Type anything plz..."
    [System.Console]::ReadKey($true)
}


function Init() {
    # We wish environment variables have set
    $env_file = $env:cwd_root + ".env.ps1"
    if (Test-Path -Path $env_file) {
        echo "load envenvironment variables."
    }
    else {
        echo "envenvironment file does not exist. refer readme first!"
    }

    . $env_file

    $env:core       = $env:cwd_data + "core.exe"
    $env:mmdb       = $env:cwd_data + "Country.mmdb"
    $env:config     = $env:cwd_data + "config.yaml"
    $env:uwp        = $env:cwd_data + "uwp.exe"

    return $env
}


# Update Subscription
function Update-Subscription() {
    $bak = $env:config + ".bak"

    curl -L $env:download_address -o $env:config # --noproxy "*"

    (type $env:config)  -replace "allow-lan: false", "allow-lan: true"      > $bak
    (type $bak)         -replace "mixed-port: 7890", "mixed-port: 10800"    > $env:config

    rm $bak
}


function Update-Core() {
    $address = "https://github.com/MetaCubeX/mihomo/releases/download/v1.18.8/mihomo-windows-amd64-v1.18.8.zip" 
    $origin_path = $env:cwd_data + "core.zip"

    fetch $address $origin_path

    Expand-Archive -Path $origin_path -DestinationPath $env:cwd_data -Force

    if (Test-Path -Path $env:core) {
        rm $env:core
    }

    $extracted_files = Get-ChildItem -Path $env:cwd_data
    foreach ($file in $extracted_files) {
        if ($file.Name -match "^mihomo-windows") {
            Rename-Item -Path $file.FullName -NewName "core.exe"
        }
    }
}


function Update-MMDB() {
    $address = "https://github.com/Loyalsoldier/geoip/releases/download/202409190112/Country.mmdb"

    fetch $address $env:mmdb
}

function fetch($url, $target) {
    if (Test-Path -Path $target) {
        echo "Target file have existed. Skip updating temporarily."
    }
    else {
        curl -L $url -o $target
    }
}


function Open-UWP-Settings() {
    $softwareName = "Enable Loopback Utility"
    $installedSoftware = winget list | Select-String -Pattern $softwareName

    if ($installedSoftware) {
        echo "$softwareName has installed, skipping installation"
        $softwarePath = "C:\Program Files (x86)\EnableLoopback\EnableLoopback.exe"
        if (Test-Path $softwarePath) {
            Start-Process $softwarePath
        } else {
            echo "cannot found executable file, please confirm correct path"
        }
    }
    else {
        echo "start installation"
        
        $uwp_address = "https://telerik-fiddler.s3.amazonaws.com/fiddler/addons/enableloopbackutility.exe"

        fetch $uwp_address $env:uwp

        if (Test-Path $env:uwp) {
            Start-Process $env:uwp
        } else {
            echo "cannot found executable file, please confirm correct path"
        }
    }

}


function Running-Cat () {
    if (-not (Test-Path $env:core)) {
        echo "cannot found core, please confirm have running 1"
        return
    }
    if (-not (Test-Path $env:mmdb)) {
        echo "cannot found mmdb, please confirm have running 2"
        return
    }
    if (-not (Test-Path $env:config)) {
        echo "cannot found config, please confirm have running 3"
        return
    }

    Start-Process -FilePath $env:core -ArgumentList "-d", $env:cwd_data
}

Init
# TODO: Wait-User
Show-Menu
