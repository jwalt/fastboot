#!/bin/sh

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


# Time-stamp: <2010-02-01 12:19:18 hcz>
# written by H. C. Zimmerer

# This is somewhat tricky: for devices without a boot section, the
# bootloader is linked directly at the end of flash so no space is
# wasted.  The original bootloader achieves this by using a fixed
# number and subtracting offsets for the sections which are not
# included.  The approach used here is fully automatic: it extracts
# the size of the bootloader from the relocatable object file,
# calculates the load addresses, and passes them to the linker script.
# This way the size of the bootloader may change, but no need arises
# to fiddle around with fixed numbers until they match.

# What happens is: Use bootload.o to get the size of the bootloader's
# text section (without the final jmp stub).  Output a line containing
# shell assignments to LOADER_START (byte start address of the
# bootloader) and STUB_OFFSET (Offset from the beginning of the
# bootloader to the final api_call jmp) so that the bootloader exactly
# fits at the end of flash without any gap.

# Invocation: Expects in $1 the word address of the higest flash cell
# (e.g. '0x1fff' for 16 kByte devices) (#define FLASHEND in the Atmel
# def file).

[ $# -ne 3 ] && {
    echo "\
Syntax: ${0##*/} object_file higest_flash_word_address page_size
Function: compute linker parameters for peda's bootloader"
    exit 1
}


end_wordaddr=$(($2))
flash_end=$(printf "%#x\n" $(($2 * 2 + 1)))

boot_map=$(avr-objdump -h $1) || exit
boot_bytes=$(echo "$boot_map" | gawk '/.text/ {print "0x" $3}')
boot_bytes=$((boot_bytes + 2))  # add stub size
boot_words=$((boot_bytes / 2))

boot_bytes="$(( ((boot_bytes-1) | ($3-1)) + 1 ))"

printf >&2 "\n*** Last available byte address for user program: %#x, max program size: %i\n\n" \
 $((flash_end + 1 - boot_bytes - 3)) $((flash_end - boot_bytes - 1))
printf "LOADER_START=%#x\n" $((flash_end + 1 - boot_bytes))
printf "STUB_OFFSET=%#x\n" $((boot_bytes - 2))
