# Start the current script in a new shell, authenticated as admin.
# Needed because some installers REQUIRE that we're running as admin.
# From https://stackoverflow.com/a/11440595/299084
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}

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
    cmd.exe /C "start /wait $filename /SILENT /NOCANCEL /NORESTART /SUPPRESSMSGBOXES /VERYSILENT"
}

function InstallNSISPluginFromZipfile
{
    param([string]$archivename, $pluginpath)
    FetchFromBucket $archivename
    cmd.exe /C "C:\Program^ Files\7-Zip\7z.exe e $archivename -oC:\NSIS\Plugins $pluginpath"
}

# work out of C:\natcap-setup
echo "Setting up working directory C:\natcap-setup"
New-Item -ItemType directory -Path C:\natcap-setup
Set-Location -Path C:\natcap-setup


# Install known dependencies
echo "Installing dependencies from installers"
InstallMSI 7z1801-x64.msi
InstallMSI Setup-Subversion-1.8.17.msi
InstallNSIS Miniconda2-4.4.10-Windows-x86.exe C:\Miniconda2_x32
InstallNSIS Miniconda2-4.4.10-Windows-x86_64.exe C:\Miniconda2_x64
InstallNSIS nsis-2.51-setup.exe C:\NSIS
InstallInnoSetup make-3.81.exe
InstallInnoSetup Mercurial-4.5-x64.exe
InstallInnoSetup Git-2.16.2-64-bit.exe

# Install python2.7 to both conda installations
echo "Installing python to conda environments"
C:\Miniconda2_x32\Scripts\conda install -y python=2.7
C:\Miniconda2_x64\Scripts\conda install -y python=2.7

# install NSIS plugins from zipfiles
echo "Installing NSIS plugins"
InstallNSISPluginFromZipfile Nsisunz.zip nsisunz\Release\nsisunz.dll
InstallNSISPluginFromZipfile Inetc.zip Plugins\x86-ansi\INetC.dll
InstallNSISPluginFromZipfile NsProcess.zip Plugin\nsProcess.dll

# Update PATH environment variable
echo "Updating PATH"
$env:Path += ";C:\NSIS;C:\NSIS\bin"
$env:Path += ";C:\Program Files\7-Zip;"
$env:Path += ";C:\Program Files (x86)\Subversion\bin"
$env:Path += ";C:\Program Files (x86)\GnuWin32\bin"
$env:Path += ";C:\Program Files\Mercurial"
$env:Path += ";C:\Program Files (x86)\Git\bin"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)

# Install chocolatey
echo "Installing latest Chocolatey"
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
