# define a custom unzip function for when we need it later.
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

function FetchFromBucket
{
    param([string]$filename)
    gsutil copy gs://natcap-build-dependencies/windows/$filename $filename
}

function InstallMSI
{
    param([string]$filename)
    FetchFromBucket $filename
    echo "Installing MSI $filename"
    cmd.exe /C "start /wait msiexec.exe /i $filename /quiet"
}

function InstallNSIS
{
    param([string]$filename, [string]$installdir)
    FetchFromBucket $filename
    echo "Installing NSIS $filename"
    cmd.exe /C "start /wait $filename /S /D=$installdir"
}

function InstallInnoSetup
{
    param([string]$filename)
    FetchFromBucket $filename
    echo "Installing InnoSetup $filename"
    cmd.exe /C "start /wait $filename /SILENT"
}

# Install known dependencies
InstallMSI 7z1801-x64.msi
InstallMSI Setup-Subversion-1.8.17.msi
InstallInnoSetup make-3.81.exe
InstallInnoSetup Mercurial-4.5-x64.exe
InstallInnoSetup PortableGit-2.16.2-64-bit.7z.exe
InstallNSIS Miniconda2-4.4.10-Windows-x86.exe C:\Miniconda2_x32
InstallNSIS Miniconda2-4.4.10-Windows-x86_64.exe C:\Miniconda2_x64
InstallNSIS nsis-2.51-setup.exe
# TODO: install NSIS plugins from zipfiles

# Update PATH environment variable
$env:Path += ";C:\"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)

# Install chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
