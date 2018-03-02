
DESTDIR=git-2.16.2

if [ -d $DESTDIR ]
then
    rm -r $DESTDIR
fi
mkdir -p $DESTDIR


wget https://github.com/git-for-windows/git/releases/download/v2.16.2.windows.1/PortableGit-2.16.2-64-bit.7z.exe

7z x -o$DESTDIR PortableGit-2.16.2-64-bit.7z.exe

zip -r $DESTDIR.zip $DESTDIR
