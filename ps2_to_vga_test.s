/* This program is used as the main driver for displaying mouse location on the
 * VGA display.
 *
 * Initializes all settings and waits for an interrupt. When an interrupt happens,
 * handler checks if PS2 is requesting and interrupt and services it. Servicing
 * involves reading 3 bytes from the PS2 data register and storing a copy in memory
 * as well as displaying the result of all 3 bytes on 6 hex displays.
 */

.equ STACK_START,             0x03FFFFFF

.equ PS2_BASE,                0xFF200100

.equ VGA_BASE,                0xFF203020
.equ VGA_BUFFER,              0x08000000
.equ VGA_BACK_BUFFER,         0x08040000

.align 2
.section .exceptions, "ax"
ISR:

/* store all used registers into stack */
subi      sp, sp, 12          # allocate space on stack for 2 initial registers
stw       r4, 0(sp)           # store registers onto stack
stw       r5, 4(sp)
stw       r6, 8(sp)

rdctl     r4, ctl4            # read ipending register to find pending interrupt
andi      r4, r4, 0x80        # check if PS2 requested servicing
bne       r4, r0, service_ps2 # if PS2 requesting, service PS2
br        end_handler         # if not, then for now exit

service_ps2:
subi      sp, sp, 20          # allocate space on stack for needed registers
stw       r8, 0(sp)           # store registers onto stack
stw       r9, 4(sp)
stw       r10, 8(sp)
stw       r11, 12(sp)
stw       r12, 16(sp)

/* read 3 bytes from PS2 corresponding 1 data packet */
movi      r8, 3               # end condition take 3 reads
movi      r9, 0               # iterator, i = 0
read_data:
beq       r8, r9, read_end    # after reading 3 bytes, exit, i == 3
ldwio     r10, 0(r6)          # read from PS2 data register
mov       r11, r10            # move copy into r11
andi      r11, r11, 0x8000    # mask reading to isolate valid bit
beq       r11, r0, read_data  # if reading not valid, try again
mov       r11, r10            # valid, mov copy into r11 again
andi      r11, r11, 0xFF      # mask reading to isolate data
add       r12, r7, r9         # set correct byte to store in
stb       r11, 0(r12)         # store value into memory
addi      r9, r9, 1           # increment counter, i++
br        read_data           # loop and check end condition
read_end:

/* read until buffer is clear, to remove backlog from delay */
/* do not clear for now in case it stop reading in the middle of a packet (3 bytes) */
/* maybe it'll read faster than the mouse sends data and this won't be a problem */
/* clear:
ldwio     r8, 0(r6)           # read from PS2 data register
andi      r8, r8, 0x0080      # mask read data to isolate valid bit
bne       r8, r0, clear       # if read data is valid, continue reading */

movi      r9, 0               # reinitialize iterator i = 0
display_data_hex:
beq       r8, r9, display_data_vga # after displaying 3 bytes of data onto 6 hex, exit
add       r10, r9, r7         # initialize address to read data from
ldb       r11, 0(r10)         # read data from memory
mov       r4, r11             # load argument register
andi      r4, r4, 0xF         # mask for 1 hex value
mov       r12, r9             # move value of counter in to calculate hex display
slli      r12, r12, 1         # multiply by 2
mov       r5, r12             # move calculated hex display number to argument register
call      display_hex         # display value onto base hex
mov       r4, r11             # move read data into argument register
srli      r4, r4, 4           # take top bits of data
andi      r4, r4, 0xF         # mask to be safe
addi      r5, r12, 1          # move hex display number to argument register
call      display_hex         # display value onto base hex +1
addi      r9, r9, 1           # increment counter, i++
br        display_data_hex    # loop and check end condition

display_data_vga:
movia     r4, mouse_data      # move mouse_data address into r4 to prep for function call
movia     r5, mouse_pos       # move mouse_pos into r5
# call      calc_pos            # calculate the mouse position on VGA

movia     r4, mouse_data      # move mouse_data address into r4 to prep for function call
movia     r5, mouse_pos       # move mouse_pos into r5

# call      copy_buffer         # copy front buffer into back buffer

ldb       r11, 0(r4)          # load overflow/button data

mov       r12, r11            # check if right mouse button clicked => clear screen
andi      r12, r12, 4
bne       r12, r0, display_clear # if right mouse button is pressed, clear screen

mov       r12, r11            # check if left mouse button clicked => draw on screen
andi      r12, r12, 1
beq       r12, r0, display_data_end # if left mouse button is not pressed, skip drawing

ldb       r4, 0(r5)           # grab X and Y positions
ldb       r5, 1(r5)
subi      sp, sp, 4
stw       r6, 0(sp)
movui     r6, 0xFFFF          # draw in white
call      draw_vga
ldw       r6, 0(sp)
addi      sp, sp, 4
br        display_data_end

display_clear:
movi      r4, 0
call      clear_vga

/* restore and deallocate used registers and memory */
display_data_end:
movi      r11, 1            # swap buffers
stwio     r11, 0(r6)
ldwio     r11, 12(r6)       # read VGA status register
andi      r11, r11, 0x1     # mask to isolate S bit
bne       r11, r0, display_data_end # if S is 1, swap has not occurred, poll again

ldw       r8, 0(sp)           # restore all used registers used besides initial r4, r5
ldw       r9, 4(sp)
ldw       r10, 8(sp)
ldw       r11, 12(sp)
ldw       r12, 16(sp)
addi      sp, sp, 20          # deallocate stack space

end_handler:
ldw       r4, 0(sp)           # restore initial registers used
ldw       r5, 4(sp)
ldw       r6, 8(sp)
addi      sp, sp, 12          # deallocate stack space

subi      ea, ea, 4           # restore pc to correct instruction
eret                          # exit handler

.data
mouse_data:
.byte 0   # overflow data
.byte 0   # delta X
.byte 0   # delta Y

mouse_pos:
.byte 0   # X position
.byte 0   # Y position

.text
.global _start
_start:

movia     sp, STACK_START     # initialize stack pointer

/* Set up VGA front and back buffer addresses */
movia     r6, VGA_BASE      # address for VGA registers
movia     r8, VGA_BACK_BUFFER # address for back buffer
stwio     r8, 4(r6)         # set back buffer to address 0x08040000

/* Set up mouse settings */
movia     r6, PS2_BASE        # initialize PS2 address
movia     r7, mouse_data      # initialize mouse_data address
movi      r8, 0xF4            # enable data reporting
stwio     r8, 0(r6)

movi      r4, 0               # clear screen to black
call      clear_vga

mouse_ack:
ldwio     r8, 0(r6)           # check for ack byte (0xFA) after sending command
mov	      r4, r8
andi      r4, r4, 0xF
movi      r5, 0
call      display_hex
mov       r4, r8
srli      r4, r4, 4
movi      r5, 1
call      display_hex
andi      r8, r8, 0x8000      # gets rid of ack byte so mouse data is correctly aligned
beq       r8, r0, mouse_ack   # if reading not valid, try again

mouse_interrupt:
movi      r8, 1               # enable read interrupts for PS2
stwio     r8, 4(r6)
movi      r8, 0x80            # enable IRQ line 7 (PS2)
wrctl     ctl3, r8
movi      r8, 1               # global interrupt enable
wrctl     ctl0, r8

wait:
br        wait                # loop and wait for an interrupt
