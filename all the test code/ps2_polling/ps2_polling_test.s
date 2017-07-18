/* This program is used as a unit section to test PS2 mouse with polling.
 *
 * Initializes all settings and attempts to read from PS2 data register.
 * In order to remove backlog, it reads until there are no more data in the buffer
 * and then waits for the next valid bytes. it then reads 3 bytes from the PS2
 * data register and storing a copy in memory as well as displaying the result
 * of all 3 bytes on 6 hex displays.
 */

.equ STACK_START,             0x03FFFFFF

.equ PS2_BASE,                0xFF200100

.data
mouse_data:
.byte 0
.byte 0
.byte 0

.text
.global _start
_start:

/* fuck me all my datas gone */

/* alright here we go again, this time read until */
movia     sp, STACK_START     # initialize stack pointer
movia     r6, PS2_BASE        # initialize PS2 address
movia     r7, mouse_data      # initialize mouse_data address
movi      r8, 0xF4            # enable data reporting
stwio     r8, 0(r6)

/* read until buffer is clear, to remove backlog from delay */
/* clear:
ldwio     r8, 0(r6)           # read from PS2 data register
andi      r8, r8, 0x0080      # mask read data to isolate valid bit
bne       r8, r0, clear       # if read data is valid, continue reading */

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

/* display previous readings onto the hex display */
movi      r9, 0               # reinitialize iterator i = 0
display_data:
beq       r8, r9, display_end # after displaying 3 bytes of data onto 6 hex, exit
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
br        display_data        # loop and check end condition
display_end:

/* delay so values displayed can be seen on the hex */
movi      r4, 1000            # initialize argument for delay to 1000ms (1s)
call      delay               # delay 1000ms

br        _start              # loop infinitely
