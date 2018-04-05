/*

   stub.i

   Put a jmp stub at the end of flash.  This is moved from APICALL.INC
   into this file which is assembled separately so the linker can take
   care of poitioning it unto the last flash word.

 */

#include <avr/io.h>
              .section .text
              .global stub          ; so it shows up in the symbol table
stub:         rjmp  api_call
              .end
