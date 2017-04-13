.equ TIMER1_BASE,             0xFF202000

.equ STACK_START,             0x03FFFFFF

.equ PS2_BASE,                0xFF200100

.equ UART_BASE,           	  0xFF201000

.equ VGA_BASE,                0xFF203020
.equ VGA_BUFFER,              0x08000000

/* memory defines */
.equ NUM_PLATFORMS,           5
.equ PLATFORM_LENGTH,         30
.equ NUM_TERRAIN,             50
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

check_pause:
movia     r6, pause_control
ldb       r7, 0(r6)
beq       r7, r0, draw_start_screen
br        service_mouse

draw_start_screen:
movia     r4, start_screen
movi      r5, 0
movi      r6, 320
call      draw_background

check_unpause:
movia     r6, UART_BASE       # read character from input
movi      r8, 0x20            # ASCII code for space (jump)
ldwio     r9, 0(r6)           # read data
andi      r10, r9, 0x8000     # mask for valid bit
beq       r10, r0, check_unpause # if not valid, read again
andi      r10, r9, 0xFF       # if valid, mask for data
bne       r10, r8, check_unpause # if not space, read again

movia     r6, pause_control
movi      r7, 1
stb       r7, 0(r6)
br        end_handler1

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
movia     r4, mouse_data      # move mouse_data address into r4 to prep for function call
movia     r5, mouse_pos       # move mouse_pos into r5
call      calc_pos            # calculate new mouse position

terrain_add:
movia     r4, mouse_data      # check whether left mouse button has been clicked
ldb       r5, 0(r4)
andi      r5, r5, 1           # mask to check left mouse button bit
beq       r5, r0, terrain_tickdown # if left mouse button not clicked, skip adding terrain

movia     r8, mouse_pos       # set up registers to add terrain
ldw       r4, 0(r8)
ldw       r5, 4(r8)
movia     r6, drawnTerrain
movi      r7, NUM_TERRAIN
call      addTerrain          # add terrain on mouse click

terrain_tickdown:
movia     r4, drawnTerrain
movi      r5, NUM_TERRAIN
call      downTickTerrain

terrain_advance:
movia     r4, drawnTerrain
movi      r5, NUM_TERRAIN
call      advanceDrawnTerrain
movia     r4, drawnTerrain
movi      r5, NUM_TERRAIN
call      advanceDrawnTerrain

platforms_advance:
movia     r4, platforms
movi      r5, NUM_PLATFORMS
movi      r6, PLATFORM_LENGTH
call      advancePlatforms
movia     r4, platforms
movi      r5, NUM_PLATFORMS
movi      r6, PLATFORM_LENGTH
call      advancePlatforms

/* two paths for gravity, if jump counter is set, ignore gravity and set jump physics
 * if jump counter is 0, read uart and decrement according to gravity
 */
movia     r6, jump_counter    # read jump counter to determine if jump state
ldb       r7, 0(r6)
beq       r7, r0, service_uart # if not jump state, read uart
br        jump_physics        # if jump state, go to jump physics

/* read shit from UART */
service_uart:

/*movi      r9, 0x1B
movi      r10, 0x5B
movi      r11, 0x32
movi      r12, 0x4B

stwio     r9, 0(r19)
stwio     r10, 0(r19)
stwio     r11, 0(r19)
stwio     r12, 0(r19)

movi	    r11, 0x48

stwio	    r9, 0(r6)
stwio     r10, 0(r6)
stwio     r11, 0(r6)*/

check_collision:
movia     r4, platforms       # check if collision
movi      r5, NUM_PLATFORMS
movia     r6, drawnTerrain
movi      r7, NUM_TERRAIN
subi      sp, sp, 4
movia     r8, player
stw       r8, 0(sp)
call      collisionPlayer
addi      sp, sp, 4
movi      r3, 2
beq       r2, r3, you_dead

uart_read:
movia     r6, UART_BASE       # read character from input
movia     r7, jump_counter    # jump counter address in case of change
movi      r8, 0x20            # ASCII code for space (jump)
ldwio     r9, 0(r6)           # read data
andi      r10, r9, 0x8000     # mask for valid bit
beq       r10, r0, uart_clear # if not valid, uart data is false
andi      r10, r9, 0xFF       # if valid, mask for data
bne       r10, r8, uart_clear # if not space, ignore and do nothing

uart_data_true:
beq       r2, r0, uart_clear  # if no collision, do not toggle jump state
br        toggle_jump

you_dead:
movia     r6, player
movi      r7, 80
stw       r7, 0(r6)
movi      r7, 100
stw       r7, 4(r6)
movia     r6, score
stw       r0, 0(r6)

draw_end_screen:
movia     r4, end_screen
movia     r5, 0
movi      r6, 320
call      draw_background

br        check_unpause

toggle_jump:
movia     r7, jump_counter
movi      r8, 10              # else toggle jump state
stb       r8, 0(r7)
uart_clear:
movia     r6, UART_BASE
ldwio     r9, 0(r6)           # read data
andi      r10, r9, 0x8000     # mask for valid bit
bne       r10, r0, uart_clear # if not valid, read again

regular_physics:
movia     r4, platforms
movi      r5, NUM_PLATFORMS
movia     r6, drawnTerrain
movi      r7, NUM_TERRAIN
subi      sp, sp, 4
movia     r8, player
stw       r8, 0(sp)
call      advancePlayerGravity
addi      sp, sp, 4
movia     r4, platforms
movi      r5, NUM_PLATFORMS
movia     r6, drawnTerrain
movi      r7, NUM_TERRAIN
subi      sp, sp, 4
movia     r8, player
stw       r8, 0(sp)
call      advancePlayerGravity
addi      sp, sp, 4
movia     r4, platforms
movi      r5, NUM_PLATFORMS
movia     r6, drawnTerrain
movi      r7, NUM_TERRAIN
subi      sp, sp, 4
movia     r8, player
stw       r8, 0(sp)
call      advancePlayerGravity
addi      sp, sp, 4

br        draw_shit

jump_physics:
movia     r6, jump_counter
ldb       r7, 0(r6)
subi      r7, r7, 1
stb       r7, 0(r6)

movia     r6, player
ldw       r7, 4(r6)
subi      r7, r7, 2
stw       r7, 4(r6)

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

draw_shit:
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
mov       r8,r0
movi      r9,NUM_PLATFORMS
movia     r10, platforms
platform_draw_loop:
beq       r8,r9,mouse_draw
movia     r4, platform
ldw       r5, 4(r10)
ldw       r6, 0(r10)
ldw       r7, 8(r10)
add       r7,r7,r6
call      draw_platform
addi r10,r10,12
addi r8,r8,1
br platform_draw_loop

mouse_draw:
movia     r4, mouse_data
movia     r5, mouse_pos
ldw       r4, 0(r5)           # grab X and Y positions
ldw       r5, 4(r5)
movi      r6, 0               # draw in white
call      draw_vga

draw_terrain:
movia     r7, drawnTerrain
movi      r8, NUM_TERRAIN
movi      r9, 0
draw_terrain_loop:
beq       r9, r8, draw_terrain_end
ldw       r4,0(r7)
ldw       r5,4(r7)
movi      r6,0
call      draw_vga
addi      r7,r7,12
addi      r9, r9, 1
br draw_terrain_loop
draw_terrain_end:

dude_draw:
movia     r7, player
movia     r4, dude
ldw       r5, 0(r7)
ldw       r6, 4(r7)
call      draw_dude

br        display_data_end

display_data_end:
movia     r6, score
ldw       r7, 0(r6)
movi      r9, 0
movi      r10, 6

display_score_loop:
beq       r9, r10, display_score_loop_end

slli      r8, r9, 2          # multiply by 4
srl       r4, r7, r8
andi      r4, r4, 0xF
mov       r5, r9
call      display_hex
addi      r9, r9, 1

br        display_score_loop

display_score_loop_end:
addi      r7, r7, 1
stw       r7, 0(r6)
call      swap_buffer

end_handler1:
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

pause_control:
.byte 0                       # control bit to pause the game

jump_counter:
.byte 0                       # counter for jump (value 0-10)

.align 1
scroll_counter:
.hword 0                      # counter for background scroll position

.align 1
vga_back_buffer:
.skip 246784

mouse_data:
.byte 0                       # overflow data
.byte 0                       # delta X
.byte 0                       # delta Y

.align 2
mouse_pos:
.word 0                       # X position
.word 0                       # Y position

.align 1
start_screen:
.incbin "startscreen.bmp"

.align 1
end_screen:
.incbin "endscreen.bmp"

.align 1
background:
.incbin "background.bmp"

.align 1
platform:
.incbin "platform.bmp"

.align 1
dude:
.incbin "dude.bmp"

.align 2
score:
.word 0

.align 2
drawnTerrain:
.skip 600

.align 2
platforms:
.word 20
.word 100
.word 30

.word 80
.word 120
.word 30

.word 140
.word 150
.word 30

.word 200
.word 120
.word 30

.word 260
.word 150
.word 30

.word 320
.word 120
.word 30

.align 2
player:
.word 80                     # initial player x position
.word 100                    # initial player y position
.word 20                     # player height
.word 8                      # player width
.word 1                      # alive/dead status (alive)

.text
.global start
start:

movia     sp, STACK_START     # initialize stack pointer

/* Set up VGA front and back buffer addresses */
movia     r6, VGA_BASE        # address for VGA registers
movia     r8, vga_back_buffer # address for back buffer
stwio     r8, 4(r6)           # set back buffer to address

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
movia     r6, drawnTerrain
movi      r7, 600
terrain_init_loop:
beq       r7, r0, terrain_init_end
subi      r7, r7, 12
add       r8, r7, r6
stw       r0, 0(r8)
br        terrain_init_loop
terrain_init_end:

movia     r6, platforms

/* Set up timer settings and enable interrupts */
movia     r6, TIMER1_BASE
movi      r4, 100              # cycles will be every 50 milliseconds
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
