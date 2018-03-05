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
    cmd.exe /C "start /wait msiexec.exe /i $filename /quiet"
}

function InstallNSIS
{
    param([string]$filename [string]$installdir)
    FetchFromBucket $filename
    cmd.exe /C "start /wait $filename /S /D=$installdir"
}

function InstallInnoSetup
{
    param([string]$filename [string]$installdir)
    FetchFromBucket $filename
    cmd.exe /C "start /wait $filename /SILENT"
}
