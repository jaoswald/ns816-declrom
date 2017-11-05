AS=/usr/m68k-linux-gnu/bin/as
OBJCOPY=/usr/m68k-linux-gnu/bin/objcopy

all: ns816rom.bin ns816rom.srec

ns816rom.o: ns816rom.s
	${AS}  -m68020 ns816rom.s -o ns816rom.o -a > ns816rom.l

ns816rom.srec: ns816rom.o
	${OBJCOPY} ns816rom.o ns816rom.srec --input-target=elf32-m68k \
	--output-target=srec	

ns816rom.bin: ns816rom.o
	${OBJCOPY} ns816rom.o ns816rom.bin --input-target=elf32-m68k \
	--output-target=binary

