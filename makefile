all: stklng

stklng: stklng.c3
	c3c compile stklng.c3 -O1
	llvm-strip stklng