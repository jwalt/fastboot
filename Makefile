# 
# Makefile for Peter Dannegger's bootloader, to be used with the GNU
# toolchest (as opposed to Atmel's Assembler).
#
# Time-stamp: <2009-08-07 14:29:55 hcz>


####### user presets ##########################
# adjust the following definitions to match your target:
##############################################

# MCU name
# One of:
# - at90s2313, at90s2323,
#     attiny22, attiny26, at90s2333, at90s2343, at90s4414, at90s4433,
#     at90s4434, at90s8515, at90c8534, at90s8535, at86rf401, attiny13,
#     attiny2313, attiny261, attiny461, attiny861, attiny24, attiny44,
#     attiny84, attiny25, attiny45, attiny85
# - atmega103, atmega603, at43usb320,
#     at43usb355, at76c711
# - atmega48, atmega8, atmega83,
#     atmega85, atmega88, atmega8515, atmega8535, atmega8hva, at90pwm1,
#     at90pwm2, at90pwm3
# - atmega16, atmega161, atmega162,
#     atmega163, atmega164p, atmega165, atmega165p, atmega168,
#     atmega169, atmega169p, atmega32, atmega323, atmega324p, atmega325,
#     atmega325p, atmega329, atmega329p, atmega3250, atmega3250p,
#     atmega3290, atmega3290p, atmega406, atmega64, atmega640,
#     atmega644, atmega644p, atmega128, atmega1280, atmega1281,
#     atmega645, atmega649, atmega6450, atmega6490, atmega16hva,
#     at90can32, at90can64, at90can128, at90usb82, at90usb162,
#     at90usb646, at90usb647, at90usb1286, at90usb1287, at94k
# - atmega2560, atmega2561
#
MCU = atmega168

# Name of the Atmel defs file for the actual MCU.
#
# The are part of AVR Studio (located in Windows at
# \Programs\Atmel\AVR Tools\AvrAssembler2\Appnotes\xxx.inc).  You
# may choose to download AVR000.zip at http://attiny.com/definitions.htm
# instead.
ATMEL_INC = m168def.inc

# Processor frequency.  The value is not critical:
#F_CPU = 14745600
F_CPU = 8000000

#     AVR Studio 4.10 requires dwarf-2.
#     gdb runs better with stabs
#DEBUG = dwarf-2
DEBUG = stabs+


####### End user presets ######################

SHELL=/bin/bash

CFLAGS = -mmcu=$(MCU) -DF_CPU=$(F_CPU) 
CFLAGS += -I . -I ./added -I ./converted -I/usr/local/avr/include 
CFLAGS += -ffreestanding
CFLAGS += -g$(DEBUG)
CFLAGS += -Wa,-adhlns=bootload.lst,-L,-g$(DEBUG)
CFLAGS += -DRAM_START=$(SRAM_START) -DSRAM_SIZE=$(SRAM_SIZE)

# The following files were imported by a gawk script without user
# intervention (in order to ease keeping up with future releases of
# the original bootloader):
AUTO_CONVERTED_FILES = \
  converted/progtiny.inc \
  converted/uart.inc \
  converted/password.inc \
  converted/progmega.inc \
  converted/watchdog.inc \
  converted/bootload.asm \
  converted/abaud.inc \
  converted/command.inc \
  converted/protocol.h \
  converted/apicall.inc \
  converted/verify.inc \
  converted/message.inc

# The following files must be worked on manually:
MANUALLY_ADDED_FILES = \
  added/fastload.inc \
  added/fastload.h \
  added/mangled_case.h \
  added/bootload.S \
  added/compat.h \
  added/fastload.h

ADDITIONAL_DEPENDENCIES = atmel_def.h

ASMSRC = $(AUTO_CONVERTED_FILES) $(MANUALLY_ADDED_FILES)

include atmel_def.mak

ifdef BOOTRST
STUB_OFFSET = 510 
LOADER_START = ( $(FLASHEND) * 2 ) - 510 # -"-
endif


bootload.hex: bootload.elf

bootload.elf : bootload.o stub.o
ifndef BOOTRST
	vars="$$(./get_text_addrs.sh $(FLASHEND))"; \
	echo "$$vars"; \
	eval "$$vars"; \
	sed -e "s/@LOADER_START@/$$LOADER_START/g" \
	    -e s'/@RAM_START@/$(SRAM_START)/g' \
	    -e s'/@RAM_SIZE@/$(SRAM_SIZE)/g' \
	    -e "s/@STUB_OFFSET@/$$STUB_OFFSET/g" \
	    bootload.template.x > bootload.x
else
	sed -e s'/@LOADER_START@/$(LOADER_START)/g' \
	    -e s'/@RAM_START@/$(SRAM_START)/g' \
	    -e s'/@RAM_SIZE@/$(SRAM_SIZE)/g' \
	    -e s'/@STUB_OFFSET@/$(STUB_OFFSET)/g' \
	    bootload.template.x > bootload.x
endif
	avr-ld -N -E -T bootload.x -Map=$(patsubst %.elf,%,$@).map --cref $+ -o $@
	#avr-gcc -Wl,-Map=display.map,--cref -nodefaultlibs -nostdlib $+ -o $@

atmel_def.h: $(ATMEL_INC) Makefile
#        We use gawk instead of egrep here due to problems with
#        WinAVR's egrep (which I didn't dive into):
	./_conv.awk $< | gawk '/SIGNATURE_|SRAM_|FLASHEND|BOOT/' > $@

atmel_def.mak: atmel_def.h
	gawk '{ printf "%s = %s\n", $$2, $$3 }' $< > $@


bootload.o: $(ASMSRC) $(ADDITIONAL_DEPENDENCIES)
	avr-gcc -c $(CFLAGS) added/bootload.S -o $@

stub.o: added/stub.S
	avr-gcc -c $(CFLAGS) $< -o $@

%.hex: %.elf
	avr-objcopy -O ihex $< $@

.PHONY: clean dbg

clean: 
	rm -f atmel_def.h bootload.x *.defs *.o *.gas *.mak *.lst *.02x *.map

###
# generate a dump of the definitions available to the assembler
# (bootload.defs, (sorted) bootload.sdefs) and the result of
# preprocessing the asm files (bootload.gas) for debugging:
dbg:
	avr-cpp $(CFLAGS) -dD -E added/bootload.S > bootload.defs
	sort bootload.defs | gawk '/^#define/' > bootload.sdefs
	avr-gcc -E $(CFLAGS) added/bootload.S -o bootload.gas



###
# For testing purposes (binary comparison of the output with Atmel
# ASM's output) a binary image gets generated and compared against
# Atmel's output in BOOTLOAD.hex.
#
# Use AVR Studio (or the like) to generate the BOOTLOAD.hex file from
# the original sources and put it into the current (resident-gnu/)
# directory.  Then run 'make cmp'.  You'll get a listing which depicts
# the differences.
#
# We convert the two files into raw binaries, change them into text
# (two bytes (4 chars) per line) using hexdump, then run the result
# through diff, and finally add address information (taken from the
# line number, displaying word addresses in (), byte addresses
# without).

cmp: bootload.02x BOOTLOAD.02x
	@if ! diff -q BOOTLOAD.02x bootload.02x; then \
	  echo "Files differ" ; \
	  diff BOOTLOAD.02x bootload.02x \
	  | ./diff2addr.sh ;\
	  echo "'<' means original data, '>' new, '()' word address."; \
	else \
	  echo "Files match. OK."; \
	fi

%.bin: %.hex
	avr-objcopy -I ihex -O binary $< $@

%.02x: %.bin
	hexdump -e '1/2 "%04x" "\n"' $< > $@


### 
# Create distribution .tar.gz
#
DISTFILES = $(AUTO_CONVERTED_FILES) $(MANUALLY_ADDED_FILES)
DISTFILES += $(ADDITIONAL_DEPENDENCIES)
DISTFILES += bootload.template.x diff2addr.sh README Makefile _conv.awk build_no
DISTFILES += get_text_addrs.sh added/stub.S

dist:
	tar --directory .. -czf \
	fastboot_build$(shell \
	  build_no=$$(($$(cat build_no 2>/dev/null)+1)); \
	  echo $$build_no | tee build_no).tar.gz \
	$(patsubst %, fastboot/%, $(DISTFILES))
	echo "build$$(< build_no) - $$(date -Isec) ($${USER:-unknown})" >> build_no-timestamps

### Debug
bincmp: 
	objcopy -I ihex -O binary bootload.hex bootload.bin
	cmp BOOTLOAD.bin bootload.bin

checkdist:
	rm -rf fastboot.test
	set -- fastboot_build*.tar.gz; \
	tar xvzf $$_ 
	mv fastboot fastboot.test
	cd fastboot.test; \
	cp ../m168def.inc .; \
	make

