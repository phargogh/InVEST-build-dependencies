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

wget http://www.7-zip.org/a/7z1801-x64.msi
wget https://svwh.dl.sourceforge.net/project/win32svn/1.8.17/Setup-Subversion-1.8.17.msi
wget https://github.com/git-for-windows/git/releases/download/v2.16.2.windows.1/PortableGit-2.16.2-64-bit.7z.exe
wget https://www.mercurial-scm.org/release/windows/Mercurial-4.5-x64.exe
wget https://repo.continuum.io/miniconda/Miniconda2-4.4.10-Windows-x86.exe
wget https://repo.continuum.io/miniconda/Miniconda2-4.4.10-Windows-x86_64.exe

# still need make for windows, NSIS and plugins.




