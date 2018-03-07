#!/usr/bin/env sh

# How to install the appropriate files from cmd.exe:
#
# innosetup exe files (like make and mercurial):
#   > start /wait make-3.81.exe /SILENT
#
# NSIS self-contained installers (like Miniconda):
#   > start /wait Miniconda2-4.4.10-Windows-x86.exe /S /D=C:\Miniconda2-x32
#
# MSI self-contained installers:
#   > start /wait Setup-Subversion-1.8.17.msi /quiet

TOOLSDIR=tools

if [ ! -d $TOOLSDIR ]
then
    mkdir $TOOLSDIR
fi

# only download files if they don't already exist
alias wget="wget --no-clobber -P $TOOLSDIR"

wget http://www.7-zip.org/a/7z1801-x64.msi
wget https://svwh.dl.sourceforge.net/project/win32svn/1.8.17/Setup-Subversion-1.8.17.msi
wget https://github.com/git-for-windows/git/releases/download/v2.16.2.windows.1/Git-2.16.2-64-bit.exe
wget https://www.mercurial-scm.org/release/windows/Mercurial-4.5-x64.exe
wget https://repo.continuum.io/miniconda/Miniconda2-4.4.10-Windows-x86.exe
wget https://repo.continuum.io/miniconda/Miniconda2-4.4.10-Windows-x86_64.exe
wget http://nsis.sourceforge.net/mediawiki/images/1/1c/Nsisunz.zip
wget http://nsis.sourceforge.net/mediawiki/images/c/c9/Inetc.zip
wget http://nsis.sourceforge.net/mediawiki/images/1/18/NsProcess.zip
wget https://astuteinternet.dl.sourceforge.net/project/nsis/NSIS%202/2.51/nsis-2.51-setup.exe
wget https://astuteinternet.dl.sourceforge.net/project/gnuwin32/make/3.81/make-3.81.exe
wget https://download.microsoft.com/download/7/9/6/796EF2E4-801B-4FC4-AB28-B59FBF6D907B/VCForPython27.msi



