# Start the current script in a new shell, authenticated as admin.
# Needed because some installers REQUIRE that we're running as admin.
# From https://stackoverflow.com/a/11440595/299084
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}

function FetchFromBucket
{
    param([string]$filename)
    gsutil copy gs://natcap-build-cluster-dependencies/windows/$filename $filename
}

function InstallMSI
{
    param([string]$filename, [string]$installdir)
    FetchFromBucket $filename
    echo "Installing MSI $filename"
    cmd.exe /C "start /wait msiexec.exe /i $filename INSTALLDIR=$installdir /quiet"
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
    param([string]$filename, [string]$installdir)
    FetchFromBucket $filename
    echo "Installing InnoSetup $filename"
    cmd.exe /C "start /wait $filename /DIR=$installdir /SILENT /NOCANCEL /NORESTART /SUPPRESSMSGBOXES /VERYSILENT"
}

function InstallNSISPluginFromZipfile
{
    param([string]$archivename, [string]$pluginpath)
    FetchFromBucket $archivename
    cmd.exe /C "C:\7zip\7z.exe" e $archivename -oC:\NSIS\Plugins $pluginpath
}

function InstallAnticipatedCondaPackages
{
    param([string]$condainstall)
    cmd.exe /C "$condainstall\Scripts\conda" install -y python=2.7 "gdal>=2" matplotlib rtree shapely qtpy
    cmd.exe /C "$condainstall\Scripts\conda" update -n base conda
}

# work out of C:\natcap-setup
echo "Setting up working directory C:\natcap-setup"
New-Item -ItemType directory -Path C:\natcap-setup
Set-Location -Path C:\natcap-setup


# Install known dependencies
echo "Installing dependencies from installers"
InstallMSI 7z1801-x64.msi C:\7zip
InstallMSI Setup-Subversion-1.8.17.msi C:\subversion
InstallNSIS Miniconda2-4.4.10-Windows-x86.exe C:\Miniconda2_x32
InstallNSIS Miniconda2-4.4.10-Windows-x86_64.exe C:\Miniconda2_x64
InstallNSIS nsis-2.51-setup.exe C:\NSIS
InstallInnoSetup make-3.81.exe C:\make
InstallInnoSetup Mercurial-4.5-x64.exe C:\mercurial
InstallInnoSetup Git-2.16.2-64-bit.exe C:\git

echo "Installing VC for Python27"
FetchFromBucket VCForPython27.msi
cmd.exe /C "start /wait msiexec.exe /i VCForPython27.msi /quiet"

# Install python2.7 to both conda installations
echo "Installing packages to conda environments"
InstallAnticipatedCondaPackages C:\Miniconda2_x32
InstallAnticipatedCondaPackages C:\Miniconda2_x64

# install NSIS plugins from zipfiles
echo "Installing NSIS plugins"
InstallNSISPluginFromZipfile Nsisunz.zip nsisunz\Release\nsisunz.dll
InstallNSISPluginFromZipfile Inetc.zip Plugins\x86-ansi\INetC.dll
InstallNSISPluginFromZipfile NsProcess.zip Plugin\nsProcess.dll

echo "Setting execution policy for OpenSSH and Chocolatey installation"
Set-ExecutionPolicy Bypass -Scope Process -Force

echo "Installing OpenSSH"
FetchFromBucket openssh-7.6.0.1.zip
cmd.exe /C "C:\7zip\7z.exe" e openssh-7.6.0.1.zip -oopenssh
powershell.exe -c "C:\natcap-setup\openssh\barebonesinstaller.ps1 -SSHServerFeature"


# Update PATH environment variable
echo "Updating PATH"
$env:Path += ";C:\NSIS;C:\NSIS\bin"
$env:Path += ";C:\7zip"
$env:Path += ";C:\subversion\bin"
$env:Path += ";C:\make\bin"
$env:Path += ";C:\mercurial"
$env:Path += ";C:\git\bin"
$env:Path += ";C:\Program Files\OpenSSH-Win64"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)

# Set up jenkins user and SSH key from project metadata
$Password = "Jenkins"+([char[]]([char]33..[char]95) + ([char[]]([char]97..[char]126)) + 0..9 | sort {Get-Random})[0..8] -join ''
cmd.exe /C "net user /add /homedir:C:\Users\jenkins jenkins $Password"
New-Item C:\Users\jenkins\.ssh -ItemType Directory
FetchFromBucket project-authorized_keys
Move-Item -Path project-authorized_keys -Destination C:\Users\jenkins\.ssh\authorized_keys

$authorizedKeyPath = "C:\Users\jenkins\.ssh\authorized_keys"
$acl = Get-Acl $authorizedKeyPath
$ar = New-Object System.Security.AccessControl.FileSystemAccessRule("NT Service\sshd", "Read", "Allow")
$acl.SetAccessRule($ar)
Set-Acl $authorizedKeyPath $acl


# Install chocolatey
echo "Installing latest Chocolatey"
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
refreshenv
