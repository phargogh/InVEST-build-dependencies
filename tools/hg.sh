#!/usr/bin/env bash

DESTDIR=hg-4.5

if [ -d $DESTDIR ]
then
    rm -r $DESTDIR
fi
mkdir -p $DESTDIR

wget https://www.mercurial-scm.org/release/windows/Mercurial-4.5-x64.exe

innoextract -d $DESTDIR Mercurial-4.5-x64.exe
mv $DESTDIR/app/* $DESTDIR
rmdir $DESTDIR/app

zip -r $DESTDIR.zip $DESTDIR


