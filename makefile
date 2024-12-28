all: stklng

stklng: stklng.c3
	c3c compile stklng.c3 -O1
	llvm-strip stklng

install: stklng
	sudo rm /usr/bin/stklng
	sudo ln ./stklng /usr/bin/stklng