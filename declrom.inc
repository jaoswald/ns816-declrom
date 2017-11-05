/* Gnu AS macros for Classic Macintosh NuBus Declaration ROMs */
	
	/* Macros for sResourceEntries */
	.macro sRsrcOffsetEntry entry_type, label
	.long (\entry_type<<24) + ((\label-.) & 0xffffff)
	.endm
	.macro sRsrcWordEntry entry_type, word_data
	.word \entry_type<<8
	.word \word_data & 0xffff
	.endm

	
EndOfList=0xff000000

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

/* VendorInfo ID Numbers */
VendorID=1
SerialNum=2
RevLevel=3
PartNum=4
Date=5

cpu68020=2
