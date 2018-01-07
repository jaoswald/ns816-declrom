/* Gnu AS macros for Classic Macintosh NuBus Declaration ROMs */
	
	/* Macros for sResourceEntries */
	.macro OSLstEntry entry_type, label
	.long (\entry_type<<24) + ((\label-.) & 0xffffff)
	.endm
	.macro DatLstEntry entry_type, word_data
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

/* Definition of seBlock: SlotEntry block */
/* On entry to PrimaryInit, A0 points to an seBlock */
	.struct 0
seBlock:
seSlot: .space 1
seRsrcID: .space 1
seStatus: .space 2
seFlags: .space 1
seFiller0:	.space 1
seFiller1:	.space 1
seFiller2:	.space 1
seResult:	.space 4 /* 8 */
seIOFileName:	.space 4 /* 12 */
seDevice:	.space 1 /* 16 */
sePartition:	.space 1
seOSType:	.space 1
seReserved:	.space 1
seRefNum:	.space 1 /* 20 */
seNumDevices:	.space 1
seBootState:	.space 1
sePBlockLen=.-seBlock

/* Slot Manager Parameter Block */
/* Used for calls to the device driver routines */
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

/* _HOpen takes a pointer to a hierarchical file system parameter
   block */
	.struct 0
HParamBlockRec:
qLink:	.space 4 /* next queue link */
qType:	.space 2 /* 4: Integer queue type */
ioTrap:	.space 2 /* 6: Integer routine trap */
ioCmdAddr: .space 4 /* 8: routine address */
ioCompletion:	.space 4 /* 12: ProcPtr to completion routine */
ioResult:	.space 2 /* 16: OSErr: result code */
ioNamePtr:	.space 4 /* 18: pointer to path name */
ioVRefNum:	.space 2 /* 22: volume specification */
	/* variant record portion */
ioRefNum: /* 24 */
ioFRefNum:
filler2:
filler3:
filler7:
ioDstVRefNum:
filler9:
filler14:
ioMatchPtr:
filler21:
	.space 2
ioVersNum: /* 26 */
ioFVersNum:
ioDenyModes:
ioObjType:
filler8:
ioWDIndex:
	.space 1
ioPermssn: /* 27 */
filler1:
	.space 1
ioMisc: /* 28 */
	.space 4
ioBuffer: /* 32 */
	.space 4
ioReqCount: /* 36 */
	.space 4
ioActCount: /* 40 */
	.space 4
ioPosMode: /* 44 */
	.space 2
ioPosOffset: /* 46 */
	.space 4
HParamBlockRecSize=.-HParamBlockRec

/* Operating System Queue Header Type */
	.struct 0
QHdr:
qFlags:	.space 2 /* Integer: queue flags */
qHead:	.space 4 /* QElemPtr first queue entry */
qTail:	.space 4 /* QElemPtr last queue entry */
QHdrSize=.-QHdr

/* Queue Element: variant type
   QElem = RECORD
     CASE QTypes OF
       vType (vblQElem: VBLTask);
       ioQType: (ioQElem: ParamBlockRec);
       drvQType: (drvQElem: DrvQEl);
       evType: (evQElem: EvQEl);
       fsQType: (vcbQElem: VCB)
     END; */

	.struct 0
/* DrvQEl type */
DrvQEl:
qLink:	.space 4 /* QElemPtr next queue entry */
qType:	.space 2 /* queue type */
dQDrive:	.space 2 /* drive number */
dQRefNum:	.space 2 /* driver reference number */
dQFSID:	.space 2 /* file-system identifier */
dQDrvSize:	.space 2 /* number of logical blocks */
DrvQElSize=.-DrvQEl

/* ParamBlockRec for Device Drivers */
/*
    typedef union ParamBlockRec {
      IOParam        ioParam ;
      FileParam      fileParam ;
      VolumeParam    volumeParam ;
      CntrlParam     cntrlParam ;
      SlotDevParam   slotDevParam ;
      MultiDevParam  multiDevParam ;
    } ParamBlockRec		     ;
    typedef ParamBlockRec *ParmBlkPtr ;
*/
/* IOParam used for open, close, read, write */
	.struct 0
IOParam:
qLink:	.space 4 /* next queue entry */
qType:	.space 2 /* 4: queue type */
	aRdCmd=2
	aWrCmd=3
ioTrap:	.space 2 /* 6: routine trap */
ioCmdAddr:	.space 4 /* 8: routine address */
ioCompletion:	.space 4 /* 12: completion routine address */
ioResult:	.space 2 /* 16: result code */
ioNamePtr:	.space 4 /* 18: pointer to driver name */
ioVRefNum:	.space 2 /* 22: volume reference or drive number */
ioRefNum:	.space 2 /* 24: driver reference number */
ioVersNum:	.space 1 /* 26: not used by the Device Manager */
ioPermssn:	.space 1 /* 27: read/write permission */
ioMisc:		.space 4 /* 28: not used by the Device Manager */
ioBuffer:	.space 4 /* 32: pointer to data buffer */
ioReqCount:	.space 4 /* 36: requested number of bytes */
ioActCount:	.space 4 /* 40: actual number of bytes completed */
ioPosMode:	.space 2 /* 44: positioning mode */
ioPosOffset:	.space 4 /* 46: positioning offset */
IOParamLen=.-IOParam

/* CntrlParam used for control and status */
	.struct 0
CntlParam:
qLink:	  .space 4 /* next queue entry */
qType:	  .space 2 /* 4: queue type */
ioTrap:	 .space 2 /* 6: routine trap */
ioCmdAddr:	      .space 4 /* 8: routine address */
ioCompletion:	   .space 4 /* 12: completion routine address */
ioResult:	       .space 2 /* 16: result code */
ioNamePtr:	      .space 4 /* 18: pointer to driver name */
ioVRefNum:	      .space 2 /* 22: volume reference or drive number */
ioCRefNum:	       .space 2 /* 24: driver reference number */
csCode:	.space 2 /* 26: word, type of control or status request */

	goodbye=-1 /* heap being reinitialized */
	/* Disk Driver csCode fr control call DiskEject */
	ejectCode=7
csParam: .space 22 /* control or status information */
CntlParamLen=.-CntlParam

	/* control result codes */
	controlErr=-17 /* Driver does not respond to this control request */
	/* status result codes */
	statusErr=-18 /* Driver does not respond to this status request */

	.struct 0
AuxDCE:
dCtlDriver:	.space 4 /* pointer or handle to driver */
dCtlFlags:	.space 2 /* flags */
	/* high order byte from drvrFlags word of driver resource */
	/* low order byte contains following run-time flags */
	dOpened=4
	dOpenedMask=0x20
	dRAMBased=6
	dRAMBasedMask=0x40
	drvrActive=7
	drvrActiveMask=0x80
dCtlQHdr:	.space QHdrSize /* I/O Queue Header */
dCtlPosition:	.space 4 /* 16: current R/W byte position */
dCtlStorage:	.space 4 /* 20: Handle to private storage */
dCtlRefNum:	.space 2 /* 24: driver reference number */
dCtlCurTicks:	.space 4 /* 26 used internally */
dCtlWindow:	.space 4 /* 30: GrafPtr: to driver's window */
dCtlDelay:	.space 2 /* 34: ticks between periodic actions */
dCtlEMask:	.space 2 /* desk accessory event mask */
dCtlMenu:	.space 2 /* desk accessory menu ID */
dCtlSlot:	.space 1 /* slot */
dCtlSlotId:	.space 1 /* sResource directory ID */
dCtlDevBase:	.space 4 /* slot device base address */
dCtlOwner:	.space 4 /* Ptr, reserved; must be 0 */
dCtlExtDev:	.space 1 /* external device ID */
fillByte:	.space 1 /* reserved */
AuxDCELen=.-AuxDCE
	.text
