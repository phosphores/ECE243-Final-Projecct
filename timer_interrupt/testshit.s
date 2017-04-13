.equ TIMER1_BASE,             0xFF202000

.equ STACK_START,             0x03FFFFFF

.equ PS2_BASE,                0xFF200100

.equ UART_BASE,           	  0xFF201000

.equ VGA_BASE,                0xFF203020
.equ VGA_BUFFER,              0x08000000

/* memory defines */
.equ NUM_PLATFORMS,           5
.equ SCREEN_RES_X,            319
.equ SCREEN_RES_Y,            239

.align 2
.section .exceptions, "ax"
ISR:

/* store all used registers into stack */
subi      sp, sp, 12          # allocate space on stack for 2 initial registers
stw       r4, 0(sp)           # store registers onto stack
stw       r5, 4(sp)
stw       r6, 8(sp)

/* check what sent the request */
rdctl     r4, ctl4            # read ipending register to find pending interrupt
andi      r4, r4, 0x1         # check if timer requested servicing
bne       r4, r0, service     # if timer requesting, service timer
br        end_handler         # if not, then for now exit

service:
subi      sp, sp, 28          # allocate space on stack for needed registers
stw       r7, 0(sp)           # store registers onto stack
stw       r8, 4(sp)
stw       r9, 8(sp)
stw       r10, 12(sp)
stw       r11, 16(sp)
stw       r12, 20(sp)
stw       r13, 24(sp)

/* read shit from UART */
service_uart:
movia     r6, UART_BASE       # read character from input and store into memory
movia     r7, uart_data
movi      r8, 0x20            # ASCII code for space (jump)

movi    r9, 0x1B
movi    r10, 0x5B
movi    r11, 0x32
movi    r12, 0x4B

stwio   r9, 0(r19)
stwio   r10, 0(r19)
stwio   r11, 0(r19)
stwio   r12, 0(r19)

movi	  r11, 0x48

stwio	  r9, 0(r6)
stwio   r10, 0(r6)
stwio   r11, 0(r6)

uart_read:
ldwio     r9, 0(r6)           # read data
andi      r10, r9, 0x8000     # mask for valid bit
beq       r10, r0, uart_data_false # if not valid, uart data is false
andi      r10, r9, 0xFF       # if valid, mask for data
bne       r10, r8, uart_data_false # if not space, go to false

uart_data_true:
movi      r8, 0x31
stb       r8, 0(r7)
br        display_uart

uart_data_false:
movi      r8, 0x30
stb       r8, 0(r7)

display_uart:
ldb       r8, 0(r7)
stwio     r8, 0(r6)

uart_clear:
ldwio     r9, 0(r6)           # read data
andi      r10, r9, 0x8000     # mask for valid bit
bne       r10, r0, uart_clear # if not valid, read again

/* read shit from mouse */
service_mouse:
movia     r6, PS2_BASE        # send Read Data command to mouse
movi      r7, 0xEB
stwio     r7, 0(r6)
movi      r7, 0xFA            # check if acknowledged (FA)
mouse_ack_read:
ldwio     r8, 0(r6)           # check for ack byte (0xFA) after sending command
andi      r9, r8, 0x8000      # gets rid of ack byte so mouse data is correctly aligned
beq       r9, r0, mouse_ack_read # if reading not valid, try again
andi      r9, r8, 0xFF
bne       r9, r7, mouse_ack_read # if doesnt match FA when valid, try again

/* read 3 bytes from PS2 corresponding 1 data packet */
movia     r7, mouse_data      # move memory address into r12
movi      r8, 3               # end condition take 3 reads
movi      r9, 0               # iterator, i = 0
read_data:
beq       r8, r9, read_end    # after reading 3 bytes, exit, i == 3
ldwio     r10, 0(r6)          # read from PS2 data register
andi      r11, r10, 0x8000    # mask reading to isolate valid bit
beq       r11, r0, read_data  # if reading not valid, try again
andi      r11, r10, 0xFF      # mask reading to isolate data
add       r13, r7, r9         # set correct byte to store in
stb       r11, 0(r13)         # store value into memory
addi      r9, r9, 1           # increment counter, i++
br        read_data           # loop and check end condition
read_end:

/*movi      r9, 0             # reinitialize iterator i = 0
display_data_hex:
beq       r8, r9, display_data_vga # after displaying 3 bytes of data onto 6 hex, exit
add       r10, r9, r7         # initialize address to read data from
ldb       r11, 0(r10)         # read data from memory
andi      r4, r11, 0xF        # mask for 1 hex value
slli      r12, r9, 1          # multiply by 2
mov       r5, r12             # move calculated hex display number to argument register
call      display_hex         # display value onto base hex
srli      r4, r11, 4          # take top bits of data
andi      r4, r4, 0xF         # mask to be safe
addi      r5, r12, 1          # move hex display number to argument register
call      display_hex         # display value onto base hex +1
addi      r9, r9, 1           # increment counter, i++
br        display_data_hex    # loop and check end condition*/

display_data_vga:
movia     r4, mouse_data      # move mouse_data address into r4 to prep for function call
movia     r5, mouse_pos       # move mouse_pos into r5
call      calc_pos

/* take the calculated positions and display onto vga */
/*movia     r7, mouse_pos
ldw       r8, 0(r7)           # load X position into r8
andi      r4, r8, 0xF         # mask for lower hex
movi      r5, 0               # select hex display 0
call      display_hex
srli      r4, r8, 4
andi      r4, r4, 0xF
movi      r5, 1
call      display_hex
srli      r4, r8, 8
andi      r4, r4, 0xF
movi      r5, 2
call      display_hex
ldw       r8, 4(r7)           # load Y position into r8
andi      r4, r8, 0xF         # mask for lower hex
movi      r5, 3               # select hex display 0
call      display_hex
srli      r4, r8, 4
andi      r4, r4, 0xF
movi      r5, 4
call      display_hex
srli      r4, r8, 8
andi      r4, r4, 0xF
movi      r5, 5
call      display_hex*/

# call      copy_buffer         # copy the buffer from the current display to back buffer
movia     r4, background
movia     r5, scroll_counter
ldh       r5, 0(r5)
movi      r6, 320
beq       r5, r6, reset_scroll

background_draw:
call      draw_background
movia     r5, scroll_counter
ldh       r6, 0(r5)
addi      r6, r6, 1
sth       r6, 0(r5)
br        platform_draw

reset_scroll:
movia     r5, scroll_counter
sth       r0, 0(r5)
movi      r5, 0
br        background_draw

platform_draw:
movia     r4, platform
movi      r5, 100
movi      r6, 100
movi      r7, 200
call      draw_platform

mouse_draw:
movia     r4, mouse_data
movia     r5, mouse_pos

ldb       r11, 0(r4)          # load overflow/button data

andi      r12, r11, 2         # check if right mouse button clicked => clear screen
bne       r12, r0, display_clear # if right mouse button is pressed, clear screen

andi      r12, r11, 1         # check if left mouse button clicked => draw on screen
beq       r12, r0, display_data_end # if left mouse button is not pressed, skip drawing

ldw       r4, 0(r5)           # grab X and Y positions
ldw       r5, 4(r5)
movui     r6, 0xFFFF          # draw in white
# call      draw_vga
br        display_data_end

display_clear:
movi      r4, 0
# call      clear_vga

display_data_end:
call      swap_buffer

/* restore and deallocate used registers and memory */
ldw       r7, 0(sp)           # restore all used registers used besides initial r4, r5
ldw       r8, 4(sp)
ldw       r9, 8(sp)
ldw       r10, 12(sp)
ldw       r11, 16(sp)
ldw       r12, 20(sp)
ldw       r13, 24(sp)
addi      sp, sp, 28          # deallocate stack space

end_handler:
ldw       r4, 0(sp)           # restore initial registers used
ldw       r5, 4(sp)
ldw       r6, 8(sp)
addi      sp, sp, 12          # deallocate stack space

subi      ea, ea, 4           # restore pc to correct instruction
eret                          # exit handler

.data
.align 1
vga_back_buffer:
.skip 246784

mouse_data:
.byte 0                       # overflow data
.byte 0                       # delta X
.byte 0                       # delta Y

uart_data:
.byte 0                       # character recieved by the uart

.align 2
mouse_pos:
.word 0                       # X position
.word 0                       # Y position

scroll_counter:
.hword 0                      # counter for scroll position

.align 1
background:
.incbin "background.bmp"

.align 1
platform:
.incbin "platform.bmp"

.align 2
drawTerrain:
.skip 600

.align 2
platforms:
.skip 60

.align 2
player:
.skip 20

.text
.global _start
_start:

movia     sp, STACK_START     # initialize stack pointer

/* Set up VGA front and back buffer addresses */
movia     r6, VGA_BASE        # address for VGA registers
movia     r8, vga_back_buffer # address for back buffer
stwio     r8, 4(r6)           # set back buffer to address 0x00800000

movi      r4, 0
call      clear_vga
call      swap_buffer

/* Set up mouse settings */
movia     r6, PS2_BASE        # initialize PS2 address
movi      r7, 0xFA            # move acknowledge comparison byte

movi      r8, 0xF0            # turn on remote mode
stwio     r8, 0(r6)

mouse_ack1:
ldwio     r8, 0(r6)           # check for ack byte (0xFA) after sending command
andi      r9, r8, 0x8000      # gets rid of ack byte so mouse data is correctly aligned
beq       r9, r0, mouse_ack1  # if reading not valid, try again
andi      r9, r8, 0xFF
bne       r9, r7, mouse_ack1  # if doesnt match FA when valid, try again

movi      r8, 0xE8
stwio     r8, 0(r6)

mouse_ack2:
ldwio     r8, 0(r6)           # check for ack byte (0xFA) after sending command
andi      r9, r8, 0x8000      # gets rid of ack byte so mouse data is correctly aligned
beq       r9, r0, mouse_ack2  # if reading not valid, try again
andi      r9, r8, 0xFF
bne       r9, r7, mouse_ack2  # if doesnt match FA when valid, try again

movi      r8, 0x0
stwio     r8, 0(r6)

mouse_ack3:
ldwio     r8, 0(r6)           # check for ack byte (0xFA) after sending command
andi      r9, r8, 0x8000      # gets rid of ack byte so mouse data is correctly aligned
beq       r9, r0, mouse_ack3  # if reading not valid, try again
andi      r9, r8, 0xFF
bne       r9, r7, mouse_ack3  # if doesnt match FA when valid, try again

movi      r8, 0xF4            # enable data reporting
stwio     r8, 0(r6)

mouse_ack4:
ldwio     r8, 0(r6)           # check for ack byte (0xFA) after sending command
andi      r9, r8, 0x8000      # gets rid of ack byte so mouse data is correctly aligned
beq       r9, r0, mouse_ack4  # if reading not valid, try again
andi      r9, r8, 0xFF
bne       r9, r7, mouse_ack4  # if doesnt match FA when valid, try again

/* No set up for UART */

/* Set up timer settings and enable interrupts */
movia     r6, TIMER1_BASE
movi      r4, 50              # cycles will be every 50 milliseconds
slli      r4, r4, 2           # multiply by 4*25000*1/100MHz to get 1ms
muli      r4, r4, 25000
mov       r17, r4             # load periodl
andi      r17, r17, 0xFFFF
stwio     r17, 8(r6)
mov       r17, r4             # load periodh
srli      r17, r17, 16
stwio     r17, 12(r6)
movi      r17, 0x7            # start timer on loop and enable interrupts
stwio     r17, 4(r6)

movi      r8, 0x1             # enable IRQ line 0 (Timer 1)
wrctl     ctl3, r8
movi      r8, 1               # global interrupt enable
wrctl     ctl0, r8

wait:
br        wait                # loop and wait for an interrupt
