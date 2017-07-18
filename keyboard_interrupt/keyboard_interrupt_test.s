/* This file is for testing if I've got the right logic for ps2 keyboard. Let's hope I do.
 */


.equ STACK_START,                 0x03FFFFFF

.equ KEYBOARD_BASE,               0xFF200108

.align 2
.section .exceptions, "ax"
ISR:

/* store all used registers into stack */
subi      sp, sp, 12            # allocate space on stack for initial registers
stw       r4, 0(sp)
stw       r5, 4(sp)
stw       r6, 8(sp)

rdctl     r4, ctl4              # read ipending register to find pending interrupt
movia     r5, 0x800000          # IRQ line 23
and       r4, r4, r5            # check if PS2 line 2 is requesting
bne       r4, r0, service_keyboard # if keyboard PS2 requesting, service keyboard
br        end_handler

service_keyboard:

service_keyboard_prologue:
subi      sp, sp, 16
stw       r7, 0(sp)
stw       r8, 4(sp)
stw       r9, 8(sp)
stw       r10, 12(sp)

service_keyboard_setup:
ldwio     r8, 0(r6)
movi      r9, 0xE0              # if character is E0, extended character incoming
beq       r8, r9, parse_extended
movia     r10, keyboard_extended # else store 0 into keyboard_extended
stw       r0, 0(r10)
movi      r9, 0xF0              # if character is F0, break character incoming
beq       r8, r9, parse_break
movia     r10, keyboard_break   # else store 0 into keyboard_break
stw       r0, 0(r10)
br        parse_make            # if not E0 or F0 check for make character

parse_extended:
movia     r10, keyboard_extended # store E0 into memory
stw       r8, 0(r10)
movi      r9, 0xF0              # if character is F0, extended break character incoming
beq       r8, r9, parse_break
movia     r10, keyboard_break   # else store 0 into keyboard_break
stw       r0, 0(r10)
br        parse_make            # if not F0 check for make character

parse_break:
movia     r10, keyboard_break   # store F0 into memory
stw       r8, 0(r10)
br        parse_make

parse_make:
movi      r9, 0x1D              # check for W => up
beq       r8, r9, parse_into_mem
movi      r9, 0x1C              # check for A => down
beq       r8, r9, parse_into_mem
movi      r9, 0x1B              # check for S => left
beq       r8, r9, parse_into_mem
movi      r9, 0x23              # check for D => right
beq       r8, r9, parse_into_mem

movi      r9, 0x75              # check for U Arrow
beq       r8, r9, parse_into_mem
movi      r9, 0x6B              # check for L Arrow
beq       r8, r9, parse_into_mem
movi      r9, 0x72              # check for D Arrow
beq       r8, r9, parse_into_mem
movi      r9, 0x74              # check for R Arrow
beq       r8, r9, parse_into_mem

parse_into_mem:
movia     r10, keyboard_make
stw       r8, 0(r10)

keyboard_display:
ldw       r4, 0(r10)
movi      r5, 0
call      display_hex
movia     r10, keyboard_break
ldw       r4, 0(r10)
movi      r5, 1
call      display_hex
movia     r10, keyboard_extended
ldw       r4, 0(r10)
movi      r5, 2
call      display_hex

service_keyboard_epilogue:
ldw       r7, 0(sp)
ldw       r8, 4(sp)
ldw       r9, 8(sp)
ldw       r10, 12(sp)
addi      sp, sp, 16

end_handler:
ldw       r4, 0(sp)
ldw       r5, 4(sp)
ldw       r6, 8(sp)
addi      sp, sp, 12

subi      ea, ea, 4
eret

.data
keyboard_extended:
.byte 0
keyboard_break:
.byte 0
keyboard_make:
.byte 0

.text
.global _start
_start:

movia     sp, STACK_START         # initialize stack pointer
movia     r6, KEYBOARD_BASE       # initialize keyboard ps2 address

movi      r8, 1                   # enable ps2 read interrupts
stwio     r8, 4(r6)
movia     r8, 0x800000            # enable IRQ line 23
wrctl     ctl3, r8
movi      r8, 1                   # global interrupt enable
wrctl     ctl0, r8

wait:
br        wait
