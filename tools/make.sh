#!/usr/bin/env sh


DROPBOX="$HOME/Dropbox/installers-for-natcap-build-processes"
DESTDIR=make-3.81

if [ -d $DESTDIR ]
then
    rm -r $DESTDIR
fi
mkdir -p $DESTDIR

cp $DROPBOX/make-3.81.exe .

innoextract -d $DESTDIR make-3.81.exe
cp -r $DESTDIR/app/* $DESTDIR
rmdir $DESTDIR

zip -r $DESTDIR.zip $DESTDIR


