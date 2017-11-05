/* Macintosh Classic OS global variable definitions */

BusErrVector=8 /* MC68000 "Access Fault" vector */

UnitNtryCnt=0x1d2 /* word  count of entries in unit table */
UTableBase=0x011C  /* long ptr to unit I/O table */
EvtBufCnt=0x154 /* word  maximum #of events in SysEvtBuf minus 1 */
DrvQHdr=0x308 /* 10 bytes, queue header of drives in system */
MMU32Bit=0xcb2 /* byte containing current MMU mode */
JIODone=0x08FC  /* long  ptr to IODone routine for drivers */

_MaskBC=0x031A  /* long  Memory Manager byte count mask */
_MaskHandle=0x031A /* long  Memory Manager handle mask */
_MaskPtr=0x031A  /* long  Memory Manager pointer mask */
Lo3Bytes=0x031A /* long  holds the constant $00FFFFFF */

KeyMap=0x0174  /* 8 bytes: bitmap of the keyboard */
KeypadMap=0x017C /* long  bitmap for numeric keypad (uses 18 bits) */
