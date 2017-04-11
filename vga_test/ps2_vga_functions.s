.equ VGA_BASE,                0xFF203020

.equ SCREEN_RES_X,            319
.equ SCREEN_RES_Y,            239

.data

.align 2
.text

/* function to read packet data from memory and update mouse position
 * void calc_pos(void* mouse_packet, void* mouse_pos);
 */
.global calc_pos
calc_pos:

calc_pos_prologue:
subi    sp, sp, 28
stw     r16, 0(sp)
stw     r17, 4(sp)
stw     r18, 8(sp)
stw     r19, 12(sp)
stw     r20, 16(sp)
stw     r21, 20(sp)
stw     r22, 24(sp)

calc_pos_setup:
ldb     r16, 0(r4)            # direction and overflow
ldb     r17, 1(r4)            # change in X
ldb     r18, 2(r4)            # change in Y
ldb     r19, 0(r5)            # current X position
ldb     r20, 1(r5)            # current Y position

/* section to check for overflow, though I don't think this would normally happen
 * to be implemented in the future
 */
calc_pos_checks:
mov     r21, r16              # check for overflow
andi    r21, r21, 0xC0
bne     r21, r0, calc_pos_epilogue # if overflowed, ignore packet and exit

mov     r21, r16              # check sign bits
andi    r21, r21, 0x10        # isolate X sign bit
bne     r21, r0, x_neg        # X sign bit is 1 => negative

x_pos:
add     r17, r17, r19         # X sign bit is 0 => positive
movi    r22, SCREEN_RES_X     # if new value > max X value
bgt     r17, r22, reset_x_max # go to reset
br      update_x_pos          # if valid, update X position

x_neg:
sub     r17, r17, r19         # calculate new X position
blt     r17, r0, reset_x_min  # if new value < 0 go to reset
br      update_x_pos          # if valid, update X position

reset_x_max:
movi    r17, SCREEN_RES_X     # set to maximum X
br      update_x_pos

reset_x_min:
mov     r17, r0               # set to minimum X

update_x_pos:
stb     r17, 0(r5)

mov     r21, r16
andi    r21, r21, 0x20
bne     r21, r0, y_neg

y_pos:
add     r18, r18, r20
movi    r22, SCREEN_RES_Y
bgt     r17, r22, reset_y_max
br      update_y_pos

y_neg:
sub     r18, r18, r20
blt     r17, r0, reset_y_min
br      update_y_pos

reset_y_max:
movi    r18, SCREEN_RES_Y
br      update_y_pos

reset_y_min:
mov     r18, r0

update_y_pos:
stb     r18, 1(r5)

calc_pos_epilogue:
ldw     r16, 0(sp)
ldw     r17, 4(sp)
ldw     r18, 8(sp)
ldw     r19, 12(sp)
ldw     r20, 16(sp)
ldw     r21, 20(sp)
ldw     r22, 24(sp)
addi    sp, sp, 28

ret

/* function to clear the vga screen to prepare for next draw
 * void clear_vga(uint16_t color);
 */
.global clear_vga
clear_vga:

clear_prologue:
subi    sp, sp, 20            # allocate space on stack
stw     r16, 0(sp)            # store used registers
stw     r17, 4(sp)
stw     r18, 8(sp)
stw     r19, 12(sp)
stw     r20, 16(sp)

clear_setup:
movia   r16, VGA_BASE         # move VGA register address into r16
ldwio   r17, 4(r16)           # read current back buffer address
movi    r18, 320              # initialize counter i for X to 319
movi    r19, 240              # initialize counter j for Y to 239

clear_loop1:
beq     r18, r0, clear_epilogue # check i (X) end condition
subi    r18, r18, 1           # decrement i
clear_loop2:
beq     r19, r0, clear_loop2_end # check j (Y) end condition
subi    r19, r19, 1           # decrement j

mov     r20, r19              # move Y position into r20
slli    r20, r20, 9           # shift to make room for X position
or      r20, r20, r18         # add X position onto r20
slli    r20, r20, 1           # shift into right format
add     r20, r20, r17         # add buffer address to X,Y
sthio   r4, 0(r20)            # load into buffer

br      clear_loop2           # loop j
clear_loop2_end:
movi    r19, 240              # reinitialize j
br      clear_loop1           # loop i

clear_epilogue:
ldw     r16, 0(sp)            # restore used registers
ldw     r17, 4(sp)
ldw     r18, 8(sp)
ldw     r19, 12(sp)
ldw     r20, 16(sp)
addi    sp, sp, 20            # deallocate stack space

ret

/* function to copy from front buffer onto back buffer to prep it for drawing
 * void copy_buffer(void)
 */
.global copy_buffer
copy_buffer:

copy_prologue:
subi    sp, sp, 32
stw     r16, 0(sp)
stw     r17, 4(sp)
stw     r18, 8(sp)
stw     r19, 12(sp)
stw     r20, 16(sp)
stw     r21, 20(sp)
stw     r22, 24(sp)
stw     r28, 28(sp)

copy_setup:
movia   r16, VGA_BASE         # move VGA register address into r16
ldwio   r17, 0(r16)           # read front buffer location
ldwio   r18, 4(r16)           # read back buffer location
movi    r19, 320
movi    r20, 240

copy_loop1:
beq     r19, r0, copy_epilogue # check i (X) end condition
subi    r19, r19, 1           # decrement i
copy_loop2:
beq     r20, r0, copy_loop2_end # check j (Y) end condition
subi    r20, r20, 1           # decrement j

mov     r21, r20              # move Y position into r20
slli    r21, r21, 9           # shift to make room for X position
or      r21, r21, r19         # add X position onto r20
slli    r21, r21, 1           # shift into right format
add     r22, r21, r17         # add front buffer address to X,Y and store into r22
ldhio   r22, 0(r22)           # load value from front buffer into r22
add     r23, r21, r18         # add back buffer address to X,Y and store into r23
sthio   r22, 0(r23)           # store value into back buffer

br      copy_loop2            # loop j
copy_loop2_end:
movi    r20, 240              # reinitialize j
br      copy_loop1            # loop i

copy_epilogue:
ldw     r16, 0(sp)
ldw     r17, 4(sp)
ldw     r18, 8(sp)
ldw     r19, 12(sp)
ldw     r20, 16(sp)
ldw     r21, 20(sp)
ldw     r22, 24(sp)
ldw     r28, 28(sp)
addi    sp, sp, 32

ret

/* function to draw a point on the screen at a X,Y location in a specified color
 * void draw_vga(x_pos, y_pos, uint16_t color)
 */
.global draw_vga
draw_vga:

draw_prologue:
subi    sp, sp, 12
stw     r16, 0(sp)
stw     r17, 4(sp)
stw     r18, 8(sp)

draw_setup:
movia   r16, VGA_BASE         # move VGA register address into r16
ldwio   r17, 4(r16)           # read current back buffer address
mov     r18, r5               # move Y value into r18
slli    r18, r18, 9           # slide to the left by 9 to make room for X
or      r18, r18, r4          # add X value into r18
slli    r18, r18, 1           # slide to the left by 1
add     r18, r18, r17         # add value of back buffer address
sthio   r6, 0(r18)            # store value into buffer

draw_epilogue:
ldw     r16, 0(sp)
ldw     r17, 4(sp)
ldw     r18, 8(sp)
addi    sp, sp, 12

ret
