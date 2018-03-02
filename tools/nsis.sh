#!/usr/bin/env bash -e

DROPBOX="$HOME/Dropbox/installers-for-natcap-build-processes"
DESTDIR=NSIS-2.51

if [ -d $DESTDIR ]
then
    rm -r $DESTDIR
fi
mkdir -p $DESTDIR

cp $DROPBOX/NSIS/* .

7z x -o$DESTDIR nsis-2.51-setup.exe

for zipfile in `Inetc.zip Nsisunz.zip`
do
    unzip -d $DESTDIR $zipfile
done;

7z x -o$DESTDIR NsProcess.zip

zip -r $DESTDIR.zip $DESTDIR
