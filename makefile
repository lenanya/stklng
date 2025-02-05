all: stklng stklng.exe

stklng: stklng.c3
	c3c compile stklng.c3
	llvm-strip stklng

stklng.exe: stklng.c3
	c3c compile stklng.c3 --target windows-x64 --winsdk /home/lena/other-code/c3c/msvc_sdk/x64
	rm stklng.lib
	rm stklng.pdb

install: stklng
	sudo rm /usr/bin/stklng
	sudo ln ./stklng /usr/bin/stklng
