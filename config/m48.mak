####### user presets ##########################
# adjust the following definitions to match your target:
##############################################

# MCU name
# One of:
# - at90s2313, at90s2323,
#     at90s2333, at90s2343, at90s4414, at90s4433,
#     at90s4434, at90c8534, at90s8535, at86rf401,
#     attiny2313, attiny24, attiny44,
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
# - atmega328, atmega328p
#
# Examples (select one of them or add your own):
# MCU = atmega64
# MCU = attiny85
# MCU = atmega2560
# MCU = atmega1281
MCU = atmega48

# Name of the Atmel defs file for the actual MCU.
#
# They are part of AVR Studio (located in Windows at
# \Programs\Atmel\AVR Tools\AvrAssembler2\Appnotes\*.inc).
#
# The license agreement of AVR Studio prohibits the distribution of the
# .inc files you need. You therefore have to download the whole AVR Studio
# suite (several hundred MB, need to register at atmel.com) and install it
# on a Windows system (getting version 6 to run under wine seems not to be
# trivial) to get these files. You can try searching on the web, but
# hostings of these files tend to disappear regularly. All .inc files go
# into subdirectory "atmel".
#
# Examples (select one of them or add your own):
# ATMEL_INC = m168def.inc
# ATMEL_INC=m64def.inc
# ATMEL_INC=tn85def.inc
# ATMEL_INC = m2560def.inc
# ATMEL_INC = m1281def.inc
ATMEL_INC = m48def.inc

# Processor frequency.  The value is not critical:
#F_CPU = 14745600
F_CPU = 8000000

# Boot dealy. How many cycles after boot to wait for bootload request
# In seconds: Boot_Delay/F_CPU
Boot_Delay = 2000000

#     AVR Studio 4.10 requires dwarf-2.
#     gdb runs better with stabs
#DEBUG = dwarf-2
DEBUG = stabs+

# Define the Tx and Rx lines here.  Set both groups to the same for
# one wire mode:
STX_PORT = PORTD
STX = PD1

SRX_PORT = PORTD
SRX = PD0

# Uncomment these to disable support for CRCs, byte-by-byte verify, or watchdog triggers
#CFLAGS += -DCRC=0
#CFLAGS += -DVERIFY=0
#CFLAGS += -DWDTRIGGER=0
