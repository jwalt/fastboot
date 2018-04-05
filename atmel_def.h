#define  SIGNATURE_000 0x1e
#define  SIGNATURE_001 0x94
#define  SIGNATURE_002 0x06
#define  BOOTRST 0	// Select reset vector
#define  BOOTSZ0 1	// Select boot size
#define  BOOTSZ1 2	// Select boot size
#define  FLASHEND 0x1fff	// Note: Word address
#define  SRAM_START 0x0100
#define  SRAM_SIZE 1024
; ***** BOOTLOADER DECLARATIONS ******************************************
#define  FIRSTBOOTSTART 0x1f80
#define  SECONDBOOTSTART 0x1f00
#define  THIRDBOOTSTART 0x1e00
#define  FOURTHBOOTSTART 0x1c00
#define  SMALLBOOTSTART FIRSTBOOTSTART
#define  LARGEBOOTSTART FOURTHBOOTSTART
