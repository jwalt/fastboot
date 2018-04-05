#  This file is part of fastboot, an AVR serial bootloader.
#  Copyright (C) 2010 Heike C. Zimmerer <hcz@hczim.de>
# 
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
# 
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
# 
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

# 
# Makefile for Peter Dannegger's bootloader, to be used with the GNU
# toolchain (as opposed to Atmel's Assembler).
#

############################################################
# User presets have been moved to the config subdirectory! #
############################################################
#                                                          #
# Either edit config/bootload.mak or copy that file to any #
# other name, e.g. "mega8.mak" and edit that.              #
#                                                          #
# If using a custom config file, call make like            #
#     make mega8                                           #
# (assuming you created config/mega8.mak)                  #
#                                                          #
# Output files will have the config name as basename, so   #
# the above command creates mega8.hex and the default      #
# config creates bootload.hex.                             #
#                                                          #
############################################################

CONFIG = bootload
CFLAGS =
include config/$(CONFIG).mak

SHELL=/bin/bash

CFLAGS += -mmcu=$(MCU) -DF_CPU=$(F_CPU) -DCONFIG_H=\"$(CONFIG).h\"
CFLAGS += -I . -I ./added -I ./converted -I/usr/local/avr/include 
CFLAGS += -ffreestanding
CFLAGS += -g$(DEBUG)
CFLAGS += -L,-g$(DEBUG)
CFLAGS += -DRAM_START=$(SRAM_START) -DSRAM_SIZE=$(SRAM_SIZE)
CFLAGS += -DSTX_PORT=$(STX_PORT) -DSTX=$(STX)
CFLAGS += -DSRX_PORT=$(SRX_PORT) -DSRX=$(SRX)
CFLAGS += -DBootDelay=$(Boot_Delay) -DBOOTDELAY=$(Boot_Delay)

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

ASMSRC = $(AUTO_CONVERTED_FILES) $(MANUALLY_ADDED_FILES)

include $(CONFIG).mak

ifdef BOOTRST
STUB_OFFSET = 510 
LOADER_START = ( $(FLASHEND) * 2 ) - 510
endif

all: $(CONFIG).hex

%.vars: %.o scripts/get_text_addrs.sh scripts/get_avr_arch.sh
ifndef BOOTRST
	scripts/get_text_addrs.sh $< $(FLASHEND) $(PAGESIZE) > $@
else
	scripts/get_bootsection_addrs.sh $< $(FLASHEND) $(FIRSTBOOTSTART) \
                $(SECONDBOOTSTART) $(THIRDBOOTSTART) $(FORTHBOOTSTART) > $@
endif
	echo "arch=$$(scripts/get_avr_arch.sh -mmcu=$(MCU) $<)" >> $@

%.x: %.vars added/bootload.x.template
	source $<; sed -e "s/@LOADER_START@/$$LOADER_START/g" \
	    -e s'/@CONFIG@/$(CONFIG)/g' \
	    -e s"/@ARCH@/$$arch/" \
	    -e s'/@RAM_START@/$(SRAM_START)/g' \
	    -e s'/@RAM_SIZE@/$(SRAM_SIZE)/g' \
	    -e "s/@STUB_OFFSET@/$$STUB_OFFSET/g" \
	    added/bootload.x.template > $@

%.elf : %.x %.vars %.o %-stub.o
ifndef BOOTRST
	source $*.vars; avr-ld -N -E -T $*.x -Map=$(patsubst %.elf,%,$@).map \
	  --cref $*.o $*-stub.o -o $@ --defsym Application="$$LOADER_START-2"
else
	source $*.vars; avr-ld -N -E -T $*.x -Map=$(patsubst %.elf,%,$@).map \
	  --cref $*.o $*-stub.o -o $@ --defsym Application=0
endif

$(CONFIG).h: atmel/$(ATMEL_INC) Makefile config/$(CONFIG).mak
#        We use gawk instead of egrep here due to problems with
#        WinAVR's egrep (which I didn't dive into):
	scripts/conv.awk $< | gawk '/PAGESIZE|SIGNATURE_|SRAM_|FLASHEND|BOOT/' > $@

$(CONFIG).mak: $(CONFIG).h
	gawk '{ printf "%s = %s\n", $$2, $$3 }' $< > $@


$(CONFIG).o: $(ASMSRC) $(CONFIG).h
	avr-gcc -c -Wa,-adhlns=$(CONFIG).lst $(CFLAGS) added/bootload.S -o $@

$(CONFIG)-stub.o: added/stub.S $(CONFIG).h
	avr-gcc -c -Wa,-adhlns=stub.lst $(CFLAGS) $< -o $@

%.hex: %.elf
# avr-objcopy might put a 0x03 record type into the resulting ihex
# file. Atmel Studio and other Windows tools might not like this.
# Circumvent by converting to binary first, then to ihex.
	avr-objcopy -O binary $< $(<:.elf=.bin)
	avr-objcopy -I binary -O ihex $(<:.elf=.bin) $@

%: config/%.mak
	make CONFIG=$*

.PHONY: clean dbg distclean

clean: 
	rm -f *.h *.x *.defs *.o *.gas *.mak *.lst *.02x *.map

distclean: clean
	rm -f *.hex *.bin

###
# generate a dump of the definitions available to the assembler
# (bootload.defs, (sorted) bootload.sdefs) and the result of
# preprocessing the asm files (bootload.gas) for debugging:
dbg:
	avr-cpp $(CFLAGS) -dD -E added/bootload.S > $(CONFIG).defs
	sort $(CONFIG).defs | gawk '/^#define/' > $(CONFIG).sdefs
	avr-gcc -E $(CFLAGS) added/bootload.S -o $(CONFIG).gas



###
# For testing purposes (binary comparison of the output with Atmel
# ASM's output) a binary image gets generated and compared against
# Atmel's output in BOOTLOAD.hex.
#
# Use AVR Studio (or wine or the like) to generate the BOOTLOAD.hex
# file from the original sources and put it into the current
# (resident-gnu/) directory.  The output must be called 'BOOTLOAD.hex"
# (case matters).  Then run 'make cmp'.  You'll get a listing which
# depicts the differences.
#
# We convert the two files into raw binaries, change them into text
# (two bytes (4 chars) per line) using hexdump, then run the result
# through diff, and finally add address information (taken from the
# line number, displaying word addresses in (), byte addresses
# without).
#
# Remove the -c option to 'get_text_addrs.sh' (above) for full
# compatibility with the original bootloader at tiny devices. -c
# packs the code as tight as possible to the end of the flash, making
# a few more bytes available to the user (which the original doesn't).

cmp:  BOOTLOAD.02x bootload.02x
	@if ! diff -q $?; then \
	  echo "Files differ" ; \
	  diff $? \
	  | scripts/diff2addr.sh ;\
	  echo "'<' means original data (avrasm), '>' new (gcc), '()' word address."; \
	  exit 1; \
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
DISTFILES = $(shell git ls-files)

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
	cp ../atmel/* atmel/; \
	make

