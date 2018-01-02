AS=/usr/m68k-linux-gnu/bin/as
OBJCOPY=/usr/m68k-linux-gnu/bin/objcopy

all: ns816rom.bin ns816rom.srec nubus_checksum

ns816rom.o: ns816rom.s atrap.inc declrom.inc globals.inc
	${AS}  -m68020 ns816rom.s -o ns816rom.o -a > ns816rom.l

ns816rom.srec: ns816rom.o
	${OBJCOPY} ns816rom.o ns816rom.srec --input-target=elf32-m68k \
	--output-target=srec	

ns816rom.bin: ns816rom.o
	${OBJCOPY} ns816rom.o ns816rom.bin --input-target=elf32-m68k \
	--output-target=binary

verify:	ns816rom.bin
	diff --report-identical-files ns816rom.bin \
	Nubus_NS8_16_Memory_Board_RevD.ROM

nubus_crc.o: nubus_crc.h nubus_crc.cc
	g++ -std=c++11 -c nubus_crc.cc

nubus_checksum: nubus_checksum.cc nubus_crc.o
	g++ -std=c++11 nubus_checksum.cc nubus_crc.o -o nubus_checksum
