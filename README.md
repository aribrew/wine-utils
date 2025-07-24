# [WIP] WINE Utils
A bunch of scripts that helps setting up WINE (Wine Is Not an Emulator).

You really only need the one that install the WINE repository, but, if you plan
using WINE in a environment like Box86 in ARM with Termux, you cannot rely on
your proot's package manager, because it will install WINE for the host's
architecture and in this case you need the x86 version.

So, with these utils you will be able to download and "install" WINE without
really installing it (with the package manager).



