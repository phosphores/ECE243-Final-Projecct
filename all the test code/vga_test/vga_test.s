/* This program is used as a unit section to test VGA double buffering.
 *
 * Initializes two buffers to switch between. Draws a horizontal line on backlog
 * buffer, checks for the switch to happen and then delays for one second.
 * It then draws a vertical line and does the same as above.
 */

.equ STACK_START,             0x03FFFFFF

.equ VGA_BASE,                0xFF203020
.equ VGA_BACK_BUFFER,         0x00840000

.data

.text
.global _start
_start:

movia     sp, STACK_START   # initialize stack pointer
movia     r6, VGA_BASE      # address for VGA registers
movia     r8, VGA_BACK_BUFFER # address for back buffer
stwio     r8, 4(r6)         # set back buffer to address 0x00840000

movia     r4, 0x23042304
call      clear_vga

/* write stuff to buffers */

/* this portion will draw a horizontal line at the middle of the screen */
draw_horizontal:
movi      r10, 119          # first horizontal index
movi      r11, 120          # second horizontal index
movi      r12, 320          # X counter end condition
movi      r13, 0            # X counter, initialized to 0
ldwio     r9, 4(r6)         # read address of current back buffer
draw_loop1:
beq       r13, r12, load_buffer1 # check end condition, i == 320
mov       r14, r10          # move Y position into r14
slli      r14, r14, 9       # shift to the right position
or        r14, r14, r13     # append X position to r14
slli      r14, r14, 1       # shift to correct format
add       r14, r14, r9      # add base address
movui     r15, 0xFFFF       # set color to white
sthio     r15, 0(r14)       # load to buffer
addi      r14, r14, 0x0200  # increment Y position
sthio     r15, 0(r14)       # load to buffer
addi      r13, r13, 1       # increment X counter
br        draw_loop1
load_buffer1:
call      swap_buffer
movi      r4, 1000          # delay for one second before switching
call      delay

movi      r4, 0x2304
call      clear_vga

/* this portion will draw a vertical line at the middle of the screen */
draw_vertical:
movi      r10, 159          # first horizontal index
movi      r11, 160          # second horizontal index
movi      r12, 240          # Y counter end condition
movi      r13, 0            # Y counter, initialized to 0
ldwio     r9, 4(r6)         # read address of current back buffer
draw_loop2:
beq       r13, r12, load_buffer2 # check end condition, i == 240
mov       r14, r13          # move Y position into r14
slli      r14, r14, 9       # shift to the right position
or        r14, r14, r10     # append X position to r14
slli      r14, r14, 1       # shift to correct format
add       r14, r14, r9      # add base address
movui     r15, 0xFFFF       # set color to white
sthio     r15, 0(r14)       # load to buffer
addi      r14, r14, 0x02    # increment X position
sthio     r15, 0(r14)       # load to buffer
addi      r13, r13, 1       # increment X counter
br        draw_loop2
load_buffer2:
call      swap_buffer
movi      r4, 1000          # delay for one second before switching
call      delay

movi      r4, 0x2304
call      clear_vga

br        draw_horizontal   # loop infinitely
