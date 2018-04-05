#define  SIGNATURE_000 0x1e
#define  SIGNATURE_001 0x98
#define  SIGNATURE_002 0x01
; ***** BOOT_LOAD ********************
#define  BOOTRST 0	// Select Reset Vector
#define  BOOTSZ0 1	// Select Boot Size
#define  BOOTSZ1 2	// Select Boot Size
#define  FLASHEND 0x1ffff	// Note: Word address
#define  SRAM_START 0x0200
#define  SRAM_SIZE 8192
; ***** BOOTLOADER DECLARATIONS ******************************************
#define  PAGESIZE 128
#define  FIRSTBOOTSTART 0x1fe00
#define  SECONDBOOTSTART 0x1fc00
#define  THIRDBOOTSTART 0x1f800
#define  FOURTHBOOTSTART 0x1f000
#define  SMALLBOOTSTART FIRSTBOOTSTART
#define  LARGEBOOTSTART FOURTHBOOTSTART
