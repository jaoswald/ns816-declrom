/*
	ns816rom.s 68020 code to reproduce National Semiconductor NS8/16
	NuBus Memory card declaration ROM.
*/


	.macro sRsrcOffsetEntry entry_type, label
	.long (\entry_type<<24) + ((\label-.) & 0xffffff)
	.endm
	.macro sRsrcWordEntry entry_type, word_data
	.word \entry_type<<8
	.word \word_data & 0xffff
	.endm

	SDeleteSRTRec=49
	.macro _SlotManager
	.short 0xA06E
	.endm

	true32b=1
	false32b=0
	.macro _SwapMMUMode
	.short 0xA05D
	.endm
	
	MMU32Bit=0xcb2 /* byte containing current MMU mode */
	.macro _StripAddress
	.short 0xA055
	.endm

	
	
EndOfList=0xff000000

	/* sResource Directory */
	.org 0x7dc
sRsrcDir:
	sRsrcOffsetEntry 1, sRsrc1
	sRsrcOffsetEntry 128, sRsrc128
	sRsrcOffsetEntry 129, sRsrc129
	sRsrcOffsetEntry 130, sRsrc130
	sRsrcOffsetEntry 131, sRsrc131	
	.long EndOfList

	sRsrcType=1
	sRsrcName=2
	sRsrcIcon=3
	sRsrcDrvrDir=4
	sRsrcLoadRec=5
	sRsrcBootRec=6
	sRsrcFlags=7
	sRsrcHWDevId=8
	MinorBaseOS=10
	MinorLength=11
	MajorBaseOS=12
	MajorLength=13
	sRsrcCicn=15
	sRsrcIcl8=16
	sRsrcIcl4=17
	sGammaDir=64

	/* Board sResource ID numbers */
	BoardId=32
	PRAMInitData=33
	PrimaryInit=34
	STimeOut=35
	VendorInfo=36
	SecondaryInit=38
	sRsrcVidNames=65
	
sRsrc1:	sRsrcOffsetEntry sRsrcType,RsrcType1
	sRsrcOffsetEntry sRsrcName,RsrcName
	sRsrcWordEntry BoardId, 0x10f
	sRsrcOffsetEntry PRAMInitData,PRamInit
	sRsrcOffsetEntry PrimaryInit,PrimaryInit_
	sRsrcOffsetEntry VendorInfo,VendorInfoRecord
	.long EndOfList

	/* VendorInfo ID Numbers */
	VendorID=1
	SerialNum=2
	RevLevel=3
	PartNum=4
	Date=5
	
RsrcType1:	.long 0x00010000
		.long 0x0
RsrcName:	.string "NS8/16 Memory Expansion Card\0\0\0"
PRamInit:	.long 12 /* data length */
	.byte 0,0,1,0
	.byte 2,0,0,0	
PrimaryInit_:	.long PrimaryInitEnd-.
	.byte 2 /* Revision 2 */

cpu68020=2
	
	.byte cpu68020
	.byte 0,0 /* reserved */
	.long PrimaryInitCode-.

	/* On entry to Primary Init, A0 points to an seBlock */
	.struct 0
seBlock:
seSlot: .space 1
sesRsrcID: .space 1
seStatus: .space 2
seFlags: .space 1
seFiller0:	.space 1
seFiller1:	.space 1
seFiller2:	.space 1
seResult:	.space 4
seIOFileName:	.space 4
seDevice:	.space 1
sePartition:	.space 1
seOSType:	.space 1
seReserved:	.space 1
seRefNum:	.space 1
seNumDevices:	.space 1
seBootState:	.space 1
sePBlockLen=.-seBlock

	/* Slot Manager Parameter Block */
	.struct 0
smParamBlock:
spResult:	.space 4
spsPointer:	.space 4
spSize:		.space 4
SpOffsetData:	.space 4
spIOFileName:	.space 4
spsExecPBlk:	.space 4
spParamData:	.space 4
spMisc:		.space 4
spReserved:	.space 4
spIOReserved:	.space 2
spRefNum:	.space 2
spCategory:	.space 2
spCType:	.space 2
spDrvrSW:	.space 2
spDrvrHW:	.space 2
spTBMask:	.space 1
spSlot:		.space 1
spID:		.space 1
spExtDev:	.space 1
spHwDev:	.space 1
spByteLanes:	.space 1
spFlags:	.space 1
spKey:		.space 1
smParamBlockSize=.-smParamBlock
	.text

	/* On entry, A0 points at a seBlock, containing the slot and
	   sRsrcId, to return an seStatus. */
PrimaryInitCode:
	moveml %d2-%d7/%a3-%a4,%sp@-
	moveal %a0,%a3 /* a3 points at seBlock */
	movew #0x504d,%a3@(seStatus)
	clrw %d0
	moveb %a3@(seSlot),%d0
	/* d0 contains slot byte, a3 & a0 point as the seBlock */
	bsrs L89E
	beqs exit
	moveb %d0,%d7
	lsrb #2,%d7
	addib #0x7f,%d7
	subaw #smParamBlockSize,%sp
	moveal %sp,%a0
	moveb %a3@(seSlot),%a0@(spSlot)
	clrb %a0@(spExtDev)
	moveb #128,%d1
.L1:	cmpb %d7,%d1
	beqs .L2
	moveb %d1,%a0@(spID)

	movel #SDeleteSRTRec,%d0
	_SlotManager
.L2:	addb #1,%d1
	cmpib #131,%d1
	bles .L1
	addaw #smParamBlockSize,%sp
exit:	moveal %a3,%a0
	moveml %sp@+,%d2-%d7/%a3-%a4
	rts

L89E:
	/* d0 contains slot byte, a3 & a0 point at the seBlock */
	moveml %d2-%d7/%a3-%a4,%sp@-
	clrw %d7
	movew %d0,%d7  /* d7 word contains slot byte */

	moveb #true32b,%d0
	_SwapMMUMode
	moveb %d0,%d6
	/* d0, d6 contain previous MMUMode, d7 slot byte, a3&a0 at seblock */
	bsrs L8CC
	moveb %d6,%d0
	_SwapMMUMode
	movew %d7,%d0  /* d0 word contains slot byte */
	moveml %sp@+,%d2-%d7/%a3-%a4
	rts

	MMU32Bit=0xcb2 /* byte containing current MMU mode */
	
L8BC:	movel %sp@+,%d0
	cmpib #0,MMU32Bit
	bnes .LNoStrip
	_StripAddress
.LNoStrip:	moveal %d0,%a0
	jmp %a0@
	
	BusErrVector=8 /* MC68000 "Access Fault" vector */

	/* d0, d6 contain previous MMUMode, d7 slot byte, a3&a0 at seblock */
L8CC:	movew %sr,%sp@-  /* save interrupt mask */
	oriw #0x700,%sr  /* disable interrupts */
	lea %pc@(BusErrRtn),%a0
	movel BusErrVector,%sp@-
	movel %a0,BusErrVector
	rorw #4,%d7
	swap %d7
	clrw %d7
	clrw %d1
	movew #3,%d0
	lea %pc@(BankAddresses),%a0
	clrw %d6
.L3:	moveal %a0@+,%a1
	addal %d7,%a1
	movel %a1@,%d5 /* read from card RAM */
	tstw %d6  /* d6 munged to indicate bus error? */
	bnes L900
	addqw #4,%d1
	dbra %d0,.L3
L900:	movel %sp@+,BusErrVector
	movew %sp@+,%sr /* restore interrupt mask */
	movew %d1,%d7
	rts

	/* Declaration byte lane means $E1 must be at FsFF FFFC */
	/* Does that mean PrimaryInit is executing from RAM? */
	/* PC of the read from card: 84f byte in the rom counting by bytes
	   but not words...how is byte lane 0 only executable?, */
	/* Handler for bus error: 68000 format
	  SP-> 16-bit special status word
	            0000 0000 000r ixxx
	            r=1 for read, 0 write
	            i=0 for instruction, 1 for not
	            xxx "function code"
	       32 bit access address [+2 bytes]
	       16 bit instruction    [+6 bytes]
	       16 bit status reg     [+8 bytes]
	       32 bit program counter [+10 bytes]
*/
	.struct 0
ExceptFrame:
ExcInfo:	.space 2
ExcAddr:	.space 4
ExcInst:	.space 2
ExcSReg:	.space 2
ExcPC:		.space 4
ExceptFrameSize=.-ExceptFrame
	.text
	
BusErrRtn: /* sets %d6 word to -1 */
	/* what is this doing to the PC on the stack?
	   Fsxx xxxx -> F(s & 0b1110)xx xxxx? */
	moveb %sp@(ExcPC),%d6
	bclr #0,%d6
	moveb %d6,%sp@(ExcPC)
	movew #-1,%d6
	rte

BankAddresses: .long 0
	.long 0x400000
	.long 0x800000
	.long 0xc00000
PrimaryInitEnd:

	/* In NS 8/16 ROM, this is $92c */
	
VendorInfoRecord:
	sRsrcOffsetEntry VendorID,VendorID_
	sRsrcOffsetEntry RevLevel,RevLevel_
	sRsrcOffsetEntry PartNum,PartNum_
	.long EndOfList
VendorID_:	.string "National Semiconductor\0"
RevLevel_:	.string "Rev. 2.21\0\0"
PartNum_:	.string "NS8/16\0"

	/* In NS 8/16 ROM $968 */
sRsrc128:	sRsrcOffsetEntry sRsrcType, RsrcType128
	sRsrcOffsetEntry sRsrcName, DrvrName
	sRsrcOffsetEntry sRsrcDrvrDir, DrvrDir128
	sRsrcOffsetEntry sRsrcBootRec, BootRec
	sRsrcWordEntry sRsrcHWDevId, 1
	sRsrcOffsetEntry MinorBaseOS, MinorBase128
	sRsrcOffsetEntry MinorLength, MinorLength128
	sRsrcOffsetEntry MajorBaseOS, MajorBase128
	sRsrcOffsetEntry MajorLength, MajorLength128
	.long EndOfList

sRsrc129:	sRsrcOffsetEntry sRsrcType, RsrcType128
	sRsrcOffsetEntry sRsrcName, DrvrName
	sRsrcOffsetEntry sRsrcDrvrDir, DrvrDir128
	sRsrcOffsetEntry sRsrcBootRec, BootRec
	sRsrcWordEntry sRsrcHWDevId, 1
	sRsrcOffsetEntry MinorBaseOS, MinorBase128
	sRsrcOffsetEntry MinorLength, MinorLength129
	sRsrcOffsetEntry MajorBaseOS, MajorBase128
	sRsrcOffsetEntry MajorLength, MajorLength129
	.long EndOfList

sRsrc130:	sRsrcOffsetEntry sRsrcType, RsrcType128
	sRsrcOffsetEntry sRsrcName, DrvrName
	sRsrcOffsetEntry sRsrcDrvrDir, DrvrDir128
	sRsrcOffsetEntry sRsrcBootRec, BootRec
	sRsrcWordEntry sRsrcHWDevId, 1
	sRsrcOffsetEntry MinorBaseOS, MinorBase128
	sRsrcOffsetEntry MinorLength, MinorLength130
	sRsrcOffsetEntry MajorBaseOS, MajorBase128
	sRsrcOffsetEntry MajorLength, MajorLength130
	.long EndOfList

sRsrc131:	sRsrcOffsetEntry sRsrcType, RsrcType128
	sRsrcOffsetEntry sRsrcName, DrvrName
	sRsrcOffsetEntry sRsrcDrvrDir, DrvrDir128
	sRsrcOffsetEntry sRsrcBootRec, BootRec
	sRsrcWordEntry sRsrcHWDevId, 1
	sRsrcOffsetEntry MinorBaseOS, MinorBase128
	sRsrcOffsetEntry MinorLength, MinorLength131
	sRsrcOffsetEntry MajorBaseOS, MajorBase128
	sRsrcOffsetEntry MajorLength, MajorLength131
	.long EndOfList

	/* NS 8/16 ROM $a08 */
RsrcType128:	.long 0x000f000f
	.long 0x000f0003
DrvrName:	.string "Memory_RAM_NatSemi_NS816\0\0\0"

	/* NS 8/16 ROM $a2c */
BootRec:	.long 0xa3
LA30:	.long 0x02020000
LA34:	.long 0x00000004
	
LA38:	moveml %d1-%fp,%sp@-
	moveal %a0, %a2
	subaw #50,%sp
	moveal %sp,%a0
        btst #2,0x0000017b
        bnes LA96
	clrl %a0@(12)
	lea %pc@(LAC0),%a1
	movel %a1,%a0@(18)
	moveb #3,%a0@(27)
	clrl %a0@(28)
	clrw %a0@(32)
	moveb %a2@,%a0@(34)
	moveb %a2@(1),%a0@(35)
	.short 0xa200
	bnes LA96
	movew %a0@(24),%d0
	bsrs LA9C
	beqs LA88
	tstw 0x00000154
	bles LA88
	moveaw #7,%a0
	.short 0xa02f
LA88:	addaw #50,%sp
	moveml %sp@+,%d1-%fp
	movew %d0,%a0@(2)
	rts
LA96:	movew #-23,%d0
	bras LA88
LA9C:	lea 0x00000308,%a0
	moveal %a0@(6),%a1
	moveal %a0@(2),%a0
LAA8:	cmpw %a0@(8),%d0
	beqs LAB6
	cmpal %a0,%a1
	beqs LABC
	moveal %a0@,%a0
	bras LAA8
LAB6:	movew %a0@(6),%d0
	rts
LABC:	clrw %d0
	rts
	/* $ac0 */
LAC0:	.byte DrvrDir128-.-1  /* 0x19 string length */
	.ascii ".Memory_RAM_NatSemi_NS816"
	/* NS 8/16 ROM $ada */
DrvrDir128:
	sRsrcOffsetEntry cpu68020, DrvrSBlock
	.long EndOfList
DrvrSBlock:	.long DrvrSBlockEnd-.	/* $4e2 */

	 /* flags used in the driver header and device control entry */
	dNeedLockMask = 0x4000 /* set if driver must be locked in
                                   memory as soon as it's opened */
	dNeedTimeMask = 0x2000 /* set if driver needs time for performing
                                   periodic tasks */ 
	dNeedGoodByeMask = 0x1000 /* set if driver needs to be called before
	                             the application heap is initialized */ 
	dStatEnableMask = 0x0800 /* set if driver responds to status requests*/
	dCtlEnableMask = 0x0400 /* set if driver responds to control requests*/ 
	dWritEnableMask = 0x0200 /* set if driver responds to write requests*/ 
	dReadEnableMask = 0x0100 /* set if driver responds to read requests*/

DrvrFlags:	.word dNeedLockMask + dNeedGoodByeMask + dCtlEnableMask + dWritEnableMask + dReadEnableMask
	.word 0 /* drvrDelay */
	.word 0 /* drvrEMask */
	.word 0 /* drvrMenu */
	.word DrvrOpen - DrvrFlags /* $2e */
	.word DrvrPrime - DrvrFlags /* $276 */
	.word DrvrCtl - DrvrFlags /* $380 */
	.word DrvrStatus - DrvrFlags /* $3b2 */
	.word DrvrClose - DrvrFlags /* $3bc */
	/* $af8 name */
DrvrPName:	.byte LB12-.-1  /* 0x19 string length */
	.ascii ".Memory_RAM_NatSemi_NS816"
LB12:	 .word 0

	/* A0 pointer to parameter block */
	/* A1 pointer to driver device control entry */
DrvrOpen:
	moveal %a0,%a3
	moveal %a1,%a4
	bsrw LC60
	bnes LB26
	clrw %d0
LB20:	movew %d0,%a3@(16)
	rts
LB26:	movew #-23,%d0
	bras LB20
LB2C:	moveq #0,%d2
LB2E:	moveal %a4@(20),%a0
	moveal %a0@,%a0
	moveal %a0@(10),%a1
	moveq #1,%d0
	_SwapMMUMode
	moveb %d0,%sp@-
	cmpiw #16964,%a1@(1024)
	beqs LB66
	movel #1048576,%d1
	movel %a1,%d0
	andil #268435455,%d0
	beqs LB5A
	movel %d0,%d1
	negl %d1
LB5A:	addal %d1,%a1
	cmpiw #16964,%a1@(1024)
	bnes LB66
	movel %d1,%d2
LB66:	moveb %sp@+,%d0
	_SwapMMUMode
/* dCtlStorage = Device Control Entry offset 20 */
	moveal %a4@(20),%a0
	moveal %a0@,%a0
	subl %d2,%a0@
	subl %d2,%a0@(6)
	addl %d2,%a0@(10)
	rts
LB7C:	moveq #126,%d0

	.macro _NewHandleSysClear
	.short 0xA722
	.endm
	
	_NewHandleSysClear

	bnes LB9E
/* dCtlStorage = Device Control Entry offset 20 */
	movel %a0,%a4@(20)
	bsrs LBA4
	moveal %a4@(20),%a0
	moveal %a0@,%a0
	tstl %a0@
	beqs LB98
	bsrs LB2C
	clrw %d0
LB96:	rts

/* dCtlStorage = Device Control Entry offset 20 */
LB98:	moveal %a4@(20),%a0
	
	.macro _DisposeHandle
	.short 0xa023
	.endm

	_DisposeHandle

LB9E:	movew #-1,%d0
	bras LB96
LBA4:	moveal %a4@(20),%a0

	.macro _HLock
	.short 0xa029
	.endm

	 _HLock
	moveal %a0@,%a0
	lea %a0@,%a1
	lea %a0@(6),%a2
	subaw #56,%sp
	moveal %sp,%a0
	moveb #255,%a0@(49)
LBBE:	addqb #1,%a0@(49)
	moveb #127,%a0@(50)
	clrb %a0@(51)
	 clrb %a0@(48)
	 movew #15,%a0@(40)
	 movew #15,%a0@(42)
	 movew #15,%a0@(44)
	 movew #3,%a0@(46)
	 clrb %a0@(52)
/* sNextTypesRsrc = #21 */
	moveq #21,%d0
	_SlotManager

	beqs LBFE
/* dCtlStorage = Device Control Entry offset 20 */
	moveal %a4@(20),%a0
	
	.macro _HUnlock
	.short 0xa02a
	.endm

	_HUnlock
	addaw #56,%sp
	rts

LBFE:	subqw #8,%sp
	movel %sp,%a0@
	moveq #17,%d0
	_SlotManager
	bnes LC5A
	moveb %sp@(2),%d0
	cmpib #2,%d0
	beqs LC5A
	moveq #0,%d2
	moveb %sp@(3),%d2
	/* mulu unsigned multiply
	   0100 1100 00mm mrrr  mmm = EA mode rrr = EA reg
	   0ddd 0s00 0000 0hhh  ddd = reg DI s = size hhh = reg DH
	   3c = 0011 1100: mmm = 111, r=100 #data
	   2002 = 0010 0000 0000 0010: ddd = 010, s = 0, hhh = 010
	   2000 emitted for hhh=000. For size=0, hhh is ignored, so
	   hhh = 010 encoded in the ROM has no effect. */
	/* mulu.l #65536,%d2 */ /* FIXME: should be 4c3c 2002 0001 0000 */
	.long 0x4c3c2002
	.long 0x00010000
	moveb %sp@(4),%d0
	movel %a0,%sp@-
	moveal %a4@(20),%a0
	moveal %a0@,%a0
	moveb %d0,%a0@(4)
	moveal %sp@+,%a0
	addqw #8,%sp
	moveq #0,%d0
	moveb %a0@(50),%d0
	subib #127,%d0
	lslw #6,%d0
	swap %d0
	moveq #0,%d1
	moveb %a0@(49),%d1
	rorw #4,%d1
	swap %d1
	subl %d2,%d0
	addl %d2,%d1
	addl %d0,%a1@
	movel %d0,%a2@+
	movel %d1,%a2@+
	braw LBBE
LC5A:	addqw #8,%sp
	braw LBBE

LC60:	bsrs LC78
	bnes LC72
	bsrw LB7C
	bnes LC72
	bsrs LCC8
	bmis LC72
	clrw %d0
LC70:	rts

LC72:	movew #-23,%d0
	bras LC70

 /*  0x11c: UTableBase */
LC78: 	moveal 0x0000011c,%a2
/* 0x1d2: UnitNtryCnt */
	movew 0x000001d2,%d3
	subqw #1,%d3
LC82:	movel %a2@,%d0
	beqs LCBE
	moveal %d0,%a0
	moveal %a0@+,%a0
	moveq #0,%d0
	moveal %a0@,%a1
/* %a0@(5): dCtlFlags, bit #6 is “dRAMBased” */
	btst #6,%a0@(5)
	beqs LC98
	moveal %a1@,%a1
/* offset 18 in IOParam = ioNamePtr */
LC98:	lea %a1@(18),%a0
	moveb %a0@+,%d0
/* af8: DrvrPName */
	lea %pc@(DrvrPName),%a1
	swap %d0
	moveb %a1@+,%d0

	.macro _CmpStringCase
	.short 0xa43c
	.endm

	_CmpStringCase
	bnes LCBE
	moveal %a2@,%a0
	moveal %a0@,%a0
	moveb %a0@(40),%d0
	cmpb %a3@(34),%d0
	beqs LCBE
	movew %a0@(24),%d0
	bras LCC6

LCBE:	addql #4,%a2
	dbf %d3,LC82
	clrw %d0
LCC6:	rts

/* DCE offset 20 = dCtlStorage */
LCC8:	moveal %a4@(20),%a0
	moveal %a0@,%a0
	movel %a0@,%d0
	beqs LCE4
	clrw %sp@-
	lsrl #8,%d0
	lsrl #1,%d0
	movel %d0,%sp@-
	movew %a4@(24),%sp@-
	bsrs LCEA
	movew %sp@+,%d0
	rts

LCE4:	movew #-1,%d0
	rts

LCEA:	linkw %fp,#-50
	moveml %d3-%d4/%a2-%a3,%sp@-
	lea 0x00000308,%a2
	moveal %a2@(6),%a3
	moveal %a2@(2),%a1
	moveq #4,%d0
LD00:	cmpw %a1@(6),%d0
	beqs LD0E
	cmpal %a1,%a3
	beqs LD16
	moveal %a1@,%a1
	bras LD00

LD0E:	moveal %a2@(2),%a1
	addqw #1,%d0
	bras LD00

LD16:	movew %d0,%fp@(14)
	movew %d0,%d3
	moveq #40,%d0
	
	.macro _NewPtrSysClear
	.short 0xa71e
	.endm

	_NewPtrSysClear
	beqs LD28
	movew %d0,%fp@(14)
	bras LD50

LD28:	movel #524288,%a0@+
	clrw %a0@(10)
	movel %fp@(10),%d0
	swap %d0
	movel %d0,%a0@(12)
	tstw %d0
	beqs LD42
	moveq #1,%d0
LD42:	movew %d0,%a0@(4)
	movew %d3,%d0
	swap %d0
	movew %fp@(8),%d0

	.macro _AddDrive
	.short 0xa04e
	.endm

	_AddDrive
LD50:	moveml %sp@+,%d3-%d4/%a2-%a3
	unlk %fp
        moveal %sp@+,%a0
	addql #6,%sp
	jmp %a0@

DrvrPrime:	 moveml %d3-%a4,%sp@-
	moveal %a0,%a2
	clrl %a2@(40)
	movel %a2@(32),%d0
	bsrw LDDC
	moveal %d0,%a3
	movel %a2@(36),%d1
	movel %a1@(16),%d2
	moveal %a1@(20),%a4
	moveal %a4@,%a4
	movel %d1,%d3
	addl %d2,%d3
	cmpl %a4@,%d3
	bhis LDD6
	lea %a4@(6),%a4
LD8A:	tstl %d1
	beqs LDCA
	movel %a4@+,%d3
	moveal %a4@+,%a0
	movel %d3,%d4
	subl %d2,%d4
	bcss LDC6
	cmpl %d4,%d1
	bhis LD9E
	movel %d1,%d4
LD9E:	addal %d2,%a0
	moveal %a3,%a1
	cmpib #3,%a2@(7)
	bnes LDAC
	exg %a0,%a1
LDAC:	moveq #1,%d0
	 .short 0xa05d
	 moveb %d0,%d7
	 movel %d4,%d0
	 .short 0xa02e
	 moveb %d7,%d0
	 .short 0xa05d
	 addl %d4,%a2@(40)
	 subl %d4,%d1
	 addal %d4,%a3
	 moveq #0,%d2
	 bras LD8A
LDC6:	subl %d3,%d2
	bras LD8A
LDCA:	clrw %d0
LDCC:	moveml %sp@+,%d3-%a4
	movel 0x000008fc,%sp@-
	rts
LDD6:	movew #-36,%d0
	bras LDCC
LDDC:	andl 0x0000031a,%d0
	 btst #23,%d0
	 bnes LDE8
	 rts
LDE8:	movew %d1,%sp@-
	movew #12,%d1
	roll %d1,%d0
	moveb %d0,%d1
	lsrl #4,%d0
	/* FIXME: df4: 103b 1120 0002 @(df8) */
	/* moveb %pc@(LDFA-4,%d1:w),%d0 /
	/* OnlineDisassembler renders it
	moveb %pc@(0x00000df8,%d1:w),%d0 */
	/* move 00zz dddn nnmm msss: ddd = dest reg nnn=dest mode
	   zz = size, mmm = source mode, sss = source reg.
           103b = 0001 0000 0011 1011 size = 01 (byte)
	   ddd = 000 nnn = 000 mmm = 111 sss 011
	   destination %d0
	   (d8,pc,Xn)
	   full Extension word (d/a)rrr (w/l)ss1 (bs)(is)(2 bit bd size)
	                       (3 bit i/is)
	   1120 = 0001 0001 0010 0000: d/a = 0, rrr = %d1
	   w/l=0 (sign-extend word index size) ss=scale=00=scale factor 1,
	   bs = 0 (base reg added),
	   is = 0 (add index operand),
	   bd size = 10 (word displacement)
	   i/is = 000 = no memory indirect */
	.long 0x103b1120
	.word 0x0002
oLDFA:	movew %sp@+,%d1
	 rorl #8,%d0
	 rts

LE00:	.byte 0x40,0xF9,0xFA,0xFB
	.byte 0xFC,0xFD,0xFE,0x50
LE08:	btst #2,0x0000017b
	beqs LE14
	movel %pc@(LE16),%sp@-
LE14:	rts
LE16:	.long 0
	.long 0x5061756c /* "Paul" */

	
LE1E:	moveml %a0-%a1,%sp@-
	moveal %a1@(20),%a1
	moveal %a1@,%a1
	cmpib #1,%a1@(4)
	bnes LE60
	movew #-24485,%d0
	.short 0xa346
	movel %a0@(18),%d0
	cmpil #1348564332,%d0
	beqs LE60
	lea %pc@(LE16),%a1
	movel %a0,%a1@
	moveq #22,%d0
	.short 0xa51e
	bnes LE60
	moveal %a0,%a1
	lea %pc@(LE08),%a0
	moveq #22,%d0
	.short 0xa02e
	moveal %a1,%a0
	movew #-24485,%d0
	.short 0xa247
LE60:	moveml %sp@+,%a0-%a1
	rts

DrvrCtl: movew %a0@(26),%d0
	cmpiw #-1,%d0
	beqs LE7E
	cmpiw #21,%d0
	beqs LE82
	cmpiw #7,%d0
	beqs LE92
	bras LE8A
LE7E:	bsrs LE1E
	bras LE8A
LE82:	lea %pc@(LEB4),%a2
	movel %a2,%a0@(28)
LE8A:	 clrw %d0
LE8C:	 movel 0x000008fc,%sp@-
	 rts
LE92:	 movew #-17,%d0
	bras LE8C
	
DrvrStatus:
	movew #-18,%d0
	movel 0x000008fc,%sp@-
	rts
	
DrvrClose:
	 movel %a1@(20),%d0
	 beqs LEB0
	 moveal %d0,%a0
	 .short 0xa023
	 clrl %a1@(20)
LEB0:	clrw %d0
	rts

LEB4:	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0

	.long 0x3cf3cf3c
	.long 0x24924924
	.long 0xffffffff
	.long 0x86080001
	.long 0x8e180001
	.long 0x98300001
	.long 0xb1600001
LF00:	.long 0xe5c80003
	.long 0xce980002
	.long 0x9a300003
	.long 0xb0600001
LF10:	.long 0xe1c00001
	.long 0xc1800001
	.long 0x80000001
	.long 0xffffffff
LF20:	.long 0x249a4924
	.long 0x3cf3cf3c
	.long 0
	.long 0
LF30:	.long 0
	.long 0
	.long 0
		.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
LF60:	.long 0
	.long 0x3cf3cf3c
	.long 0x3cf3cf3c
	.long 0xffffffff
	.long 0xffffffff
	.long 0xffffffff
	.long 0xffffffff
	.long 0xffffffff
	.long 0xffffffff
	.long 0xffffffff
	.long 0xffffffff
	.long 0xffffffff
	.long 0xffffffff
	.long 0xffffffff
	.long 0xffffffff
	.long 0xffffffff
LFA0:	.long 0x3cfbcf3c
	.long 0x3cf3cf3c
	.long 0
	.long 0
LFB0:	.long 0
LFB4:	.byte 14
	.string "NS8/16 RAMDisk"
DrvrSBlockEnd:
	
	/* NS 8/16 ROM $fc4 */
MinorBase128:	.long 0
MajorBase128:	.long 0
MinorLength128:	.long 0x00400000
MajorLength128:	.long 0x00400000
MinorLength129:	.long 0x00800000
MajorLength129:	.long 0x00800000
MinorLength130:	.long 0x00c00000
MajorLength130:	.long 0x00c00000
MinorLength131:	.long 0x01000000
MajorLength131:	.long 0x01000000

	/* Declaration ROM directory at end */
DeclROMDir:
	sRsrcOffsetEntry 0, sRsrcDir

	.long DeclRomEnd-sRsrcDir /* Length should be 0x824 */
DeclROMCRC:	.long 0x7901e271 /* TODO: calculate this */
	.byte 1			 /* Revision Level */
	.byte 1			 /* Apple Format */
	.long 0x5a932bc7	 /* magic TestPattern */
	.byte 0			 /* reserved */
	.byte 0xe1		 /* byte lane marker */
DeclRomEnd:
	.end
