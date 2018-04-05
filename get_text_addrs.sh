#!/bin/sh

# Time-stamp: <2009-07-28 18:17:07 hcz>
# written by H. C. Zimmerer

# This is somewhat tricky: for devices without a boot section, the
# bootloader is linked directly at the endof flash so no space is
# wasted.  The original bootloader achieves this by using a fixed
# number and subtracting offsets for the sections which are not
# included.  The approach used here is fully automatic: it extracts
# the size of the bootloader from the relocatable object file,
# calculates the load addresses, and passes them to the linker script.
# This way the size of the bootloader may change, but no need arises
# to fiddle around with fixed numbers until they match.

# So: Use bootload.o to get the size of the bootloader's text section
# (without the final jmp stub).  Output a line containing shell
# assignments to LOADER_START (byte start address of the bootloader)
# and STUB_OFFSET (Offset from the beginning of the bootloader to the
# final api_call jmp) so that the bootloader exactly fits at the end of
# flash without any gap.

# Expects in $1 the word address of the higest flash cell
# (e.g. '0x1fff' for 16 kByte devices) (#define FLASHEND in the Atmel
# def file).

[ $# -ne 1 ] && {
    echo "\
Syntax: ${0##*/} higest_flash_word_address"
    exit 1
}

avr-objdump -h bootload.o \
| gawk -v end_wordaddr="$1" '
    $2 == ".text" {
      len = strtonum("0x" $3)
      end = (strtonum(end_wordaddr) + 1) * 2
      printf("# loader starts at %#x\n", end - len - 2):
      printf("LOADER_START=\"(%#x - %d)\"\n", end, len+2)
      printf("STUB_OFFSET=%d\n", len)
    }
  '
