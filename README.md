# [WIP] WINE Utils
A bunch of scripts that helps setting up WINE (Wine Is Not an Emulator).

The only really needed ones are those for installing the WINE repository and
the one for install the needed dependencies, because once this is done you
can install wine-stable or wine-staging using your package manager.

However, if you plan using WINE in a environment like Box86 in ARM with Termux, 
you cannot rely on your package manager, because it will install WINE for the
host's architecture and WINE is only for i386 and AMD64 architectures.

So, with these utils you will be able to download and "install" WINE without
really installing it (with the package manager).

The full_setup.sh script includes installing/updating the scripts,
installing the WINE repository and its dependencies.

Then the recommended WINE version will be downloaded and 
installed both for i386 and AMD64, and a default prefix will be created for
each one.
