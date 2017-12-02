Code for a NuBus declaration ROM for the National Semiconductor 8/16 RAM
expansion board.

# Background

The Symbolics MacIvory I and II models used dedicated NuBus memory boards as
system memory. The Rev. D board is incompatible with 68040 Quadra Macintosh
CPUs, causing them to freeze on boot, unless populated with a daugterboard
that brings it to full 16 MB capacity. The Rev. F board apparently avoids this
problem. But I have two Rev. D boards, and no solid idea whether then can be
upgraded to Rev. F at this date.

Luckily, it appears the problem is primarily that the ROM on the Rev. D
makes assumptions that it is running on a 68020. I hope to develop a
68040-compatible declaration ROM, burn it onto a replacement EPROM, and be
able to run my 8 MB boards in my Quadra computer.

# Prerequisites

This code is Motorola 68k assembly in Gnu AS syntax. The default Makefile
assumes /usr/m68k-linux-gnu/bin/ contains a working 'as' and 'objcopy' for the
68k. `apt-get install binutils-m68k-linux-gnu` will provide that on Ubuntu.

# Technical information

The chip on the board is a 32Kx8 NMC27C256Q-200 device. The address lines,
however, are active low, meaning addresses are ones-complement: the
programmed ROM contents are address-reversed. The upper two bits of the address
(A13 and A14) are controlled by the 16V8 GAL U14 pin 11 and jumper W1 (U14 pin
3) respectively.

That is used to select one of 4 8K pages in the ROM. The production Rev D ROM
contains 4 identical copies of the content, but the contents could differ

# Files

* \*.srec are Motorola S-record format with 32-bit addresses
* \*.hex are Intel HEX format
* \*.bin are raw binary

* Nubus_NS8_16_Memory_Board_RevD.ROM contains a raw image as seen by the
  Macintosh: 1 8K image, in proper order, as observed on a Macintosh IIfx
  with the W1 jumper absent and no daughter board.

* ns816prom.* hold the Rev D image as seen by an EPROM programmer; 4 copies of
  the ROM, address-reversed.

* ns816_quadra.* hold 
* ns816_quadra_prom.* hold the modified Quadra-compatible EPROM (address-
  reversed, duplicated)