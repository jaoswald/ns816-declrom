Code for a NuBus declaration ROM for the National Semiconductor 8/16 RAM
expansion board.

# Background

The [Symbolics](https://en.wikipedia.org/wiki/Symbolics) MacIvory I and II
models used dedicated NuBus memory boards as system memory. The [National
Semiconductor NS 8/16](https://books.google.com/books?id=xjAEAAAAMBAJ&lpg=PA21&dq=national%20semiconductor%20steps%20into%20add-on%20mart%20with%20card&pg=PA21#v=onepage&q=national%20semiconductor%20steps%20into%20add-on%20mart%20with%20card&f=false) was one such board. These boards were also used in the
wider Macintosh market as RAM disks. The NS 8/16 Rev. D board is incompatible
with 68040 Quadra Macintosh CPUs, causing them to freeze on boot, [unless the
board includes the daughterboard](http://www.typewritten.org/Projects/Symbolics/463.html#15]
that brings it to its maximum 16 MB capacity. The Rev. F version of this board
apparently avoids this problem, but reportedly has major hardware changes from
the Rev. D. I have two Rev. D boards, without daughterboards, and no solid idea
whether they can be upgraded somehow to Rev. F at this date. National
Semiconductor long ago lost all institutional knowledge about these boards.

Luckily, my investigation suggests that the problem is primarily that the ROM
on the Rev. D makes assumptions that it is running on a 68020. I hope to
develop a 68040-compatible declaration ROM, burn it onto a replacement EPROM,
and be able to use my 8 MB boards in my Quadra computer.

# Prerequisites

This code is Motorola 68k assembly in Gnu AS syntax. The default Makefile
assumes /usr/m68k-linux-gnu/bin/ contains a working 'as' and 'objcopy' for the
68k. `apt-get install binutils-m68k-linux-gnu` will provide that on Ubuntu.

# Technical information

## Hardware Addressing

The chip on the board is a 32Kx8 NMC27C256Q-200 device. The address lines,
however, are active low, meaning addresses are ones-complement: the
programmed ROM contents are address-reversed. The upper two bits of the address
(A13 and A14) are controlled by the 16V8 GAL U14 pin 11 and jumper W1 (U14 pin
3) respectively.

Those bits are used to select one of 4 8K pages in the ROM to be visible to the
Macintosh. The production Rev. D ROM fills each of the pages with identical
content, but the contents could differ in principle. The actual declaration
ROM data and code is just under 2K bytes in size.

The data bits appear to be in the expected arrangement, D0 low-order to D7
high-order.

I have yet to reverse engineer the hardware completely. My guess is that the
W1 jumper and a possible jumper on the daughterboard control the logic so as to
trigger a NuBus error for an address outside the installed RAM and ROM
Error messages in the Symbolics code giving instructions to adjust these
jumpers supports my theory, as well as the problem that simple DRAM don't
provide any handshake that would confirm their presence. Trying to write an
empty RAM will not store data, but it will also not cause any behavior in
the write process that could be converted into a NuBus error.

## The software bug

The root of the incompatibility is that the declaration ROM at boot runs a
PrimaryInit routine as part of NuBus initialization. This routine includes a
step which changes the "Access Fault" vector to its own handler and probes the
memory of the board, watching for a NuBus Bus Error to occur to determine how
much RAM is installed.

However, that bus error handler assumes the format of the exception stack is
for the Motorola 68020 Long Bus Fault (format $B). It sets the D6 register and
clears the data fault bit of that format to prevent the processor from
re-trying the failed read cycle. But for a 68040, the exception stack frame is
(I guess) format $7, an Access Error Stack frame, and this procedure does not
clear the fault, but twiddles the Effective Address recorded in the stack
uselessly. I presume the processor gets stuck retrying the NuBus read and
getting sent to the same defective handler until the system is reset.
Unfortunately, the PrimaryInit execution occurs before the MacsBug debugger is
available.

## Macintosh NuBus Declaration ROM references

The NuBus behavior of the 68k Macintosh series is described in
[Designing Cards and Drivers for the Macintosh Family](http://dec8.info/Apple/Designing_Cards_and_Drivers_for_the_Macintosh_Family_2ed_May90.pdf).

## Motorola 680x0 references

The exception handling process of the 68020 is described in the (formerly
Motorola) MC68020 Microprocessor User's Manual

https://www.nxp.com/docs/en/data-sheet/MC68020UM.pdf
https://www.nxp.com/docs/en/reference-manual/MC68040UM.pdf
https://www.nxp.com/docs/en/reference-manual/MC68040UMAD.pd

68000--68040 instructions and exception frame formats are documented in the
68000 Programmer's Reference Manual.
https://www.nxp.com/docs/en/reference-manual/M68000PRM.pdf

# Files

* \*.s are 68k assembly code in GNU as syntax.
* \*.inc are various include files for the assembly code.
* \*.srec are Motorola S-record format with 32-bit addresses
* \*.hex are Intel HEX format
* \*.bin are raw binary

* Nubus_NS8_16_Memory_Board_RevD.ROM contains a raw image as seen by the
  Macintosh: one 8K image, in proper order, as observed on a Macintosh IIfx
  with the W1 jumper absent and no daughter board.

* ns816prom.* hold the Rev D image as seen by an EPROM programmer; 4 copies of
  the declaration ROM contents, address-reversed.

* ns816_quadra.* will hold the modified Quadra-compatible image as seen by
  the Macintosh.

* ns816_quadra_prom.* hold the modified Quadra-compatible EPROM (address-
  reversed, duplicated) image generated from ns816_quadra.bin
