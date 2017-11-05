/* Macintosh Classic OS A-trap definitions */
/* Also incudes a few parameter definitions */

	SDeleteSRTRec=49
	.macro _SlotManager
	.short 0xA06E
	.endm

	true32b=1
	false32b=0
	.macro _SwapMMUMode
	.short 0xA05D
	.endm
	
	.macro _StripAddress
	.short 0xA055
	.endm

	fsRdWrPerm=3
	openErr=-23
	.macro _HOpen
	.short 0xA200
	.endm

	.macro _PostEvent
	.short 0xA02F
	.endm

	.macro _GetOSTrapAddress
	.short 0xA346
	.endm
	
	.macro  _SetOSTrapAddress
        .short 0xA247
	.endm
	
	.macro _NewPtrSys
	.short 0xA51E
	.endm

	.macro _BlockMove
	.short 0xA02E
	.endm
