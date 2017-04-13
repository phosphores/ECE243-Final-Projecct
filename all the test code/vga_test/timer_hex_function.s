.equ HEX1_BASE,             0xFF200020
.equ HEX2_BASE,             0xFF200030

.equ HEX0,                  0b0111111
.equ HEX1,                  0b0000110
.equ HEX2,                  0b1011011
.equ HEX3,                  0b1001111
.equ HEX4,                  0b1100110
.equ HEX5,                  0b1101101
.equ HEX6,                  0b1111101
.equ HEX7,                  0b0000111
.equ HEX8,                  0b1111111
.equ HEX9,                  0b1100111
.equ HEXA,                  0b1110111
.equ HEXB,                  0b1111100
.equ HEXC,                  0b0111001
.equ HEXD,                  0b1011110
.equ HEXE,                  0b1111001
.equ HEXF,                  0b1110001

.equ TIMER1_BASE,           0xFF202000

.data
.align 2
HEX_0:
.byte 0b0111111
HEX_1:
.byte 0b0111111
HEX_2:
.byte 0b0111111
HEX_3:
.byte 0b0111111
HEX_4:
.byte 0b0111111
HEX_5:
.byte 0b0111111
.hword 0

.align 2
.text

/* function to set timer and blocks for a specified amount of time
 * void delay(unsigned milliseconds);
 */
.global delay
delay:

delay_prologue:
subi    sp, sp, 8           # allocate space on stack
stw     r16, 0(sp)          # store used registers
stw     r17, 4(sp)

delay_setup:
movia   r16, TIMER1_BASE    # move address of timer 1 into r16
movia   r17, 42949          # check overflow as argument will be in milliseconds (2^32-1)/100000
bltu    r4, r17, delay_prepare # if argument (r4) is less than max (r17), no overflow
mov     r4, r17             # overflow, set r4 to max
delay_prepare:
slli    r4, r4, 2           # multiply by 4*25000*1/100MHz to get 1ms
muli    r4, r4, 25000
mov     r17, r4             # load periodl
andi    r17, r17, 0xFFFF
stwio   r17, 8(r16)
mov     r17, r4             # load periodh
srli    r17, r17, 16
stwio   r17, 12(r16)
movi    r17, 0x4            # start timer
stwio   r17, 4(r16)

delay_poll:
ldwio   r17, 0(r16)         # load status register into r17
andi    r17, r17, 0x2       # isolate run bit
bne     r17, r0, delay_poll # if not running, finish

delay_cleanup:
stwio   r0, 0(r16)          # clear timeout bit

delay_epilogue:
ldw     r16, 0(sp)
ldw     r17, 4(sp)
addi    sp, sp, 8

ret

/* end delay */

/* function to display a certain hex number 0-F on a certain hex display 0-5
 * void display_hex(unsigned hexNum, unsigned displayNum);
 */
.global display_hex
display_hex:

display_prologue:
subi    sp, sp, 20          # allocate space on stack
stw     r16, 0(sp)          # store used registers onto stack
stw     r17, 4(sp)
stw     r18, 8(sp)
stw     r19, 12(sp)
stw     r20, 16(sp)

display_setup:
movia   r18, HEX_0
add     r18, r18, r5

display_h0:
bgtu    r4, r0, display_h1  # if not 0, check 1
movi    r16, HEX0           # else display 0 on hex display
stb     r16, 0(r18)
br      display_gt3         # go to store values into hex
display_h1:
movi    r16, 1
bgtu    r4, r16, display_h2
movi    r16, HEX1
stb     r16, 0(r18)
br      display_gt3
display_h2:
movi    r16, 2
bgtu    r4, r16, display_h3
movi    r16, HEX2
stb     r16, 0(r18)
br      display_gt3
display_h3:
movi    r16, 3
bgtu    r4, r16, display_h4
movi    r16, HEX3
stb     r16, 0(r18)
br      display_gt3
display_h4:
movi    r16, 4
bgtu    r4, r16, display_h5
movi    r16, HEX4
stb     r16, 0(r18)
br      display_gt3
display_h5:
movi    r16, 5
bgtu    r4, r16, display_h6
movi    r16, HEX5
stb     r16, 0(r18)
br      display_gt3
display_h6:
movi    r16, 6
bgtu    r4, r16, display_h7
movi    r16, HEX6
stb     r16, 0(r18)
br      display_gt3
display_h7:
movi    r16, 7
bgtu    r4, r16, display_h8
movi    r16, HEX7
stb     r16, 0(r18)
br      display_gt3
display_h8:
movi    r16, 8
bgtu    r4, r16, display_h9
movi    r16, HEX8
stb     r16, 0(r18)
br      display_gt3
display_h9:
movi    r16, 9
bgtu    r4, r16, display_hA
movi    r16, HEX9
stb     r16, 0(r18)
br      display_gt3
display_hA:
movi    r16, 10
bgtu    r4, r16, display_hB
movi    r16, HEXA
stb     r16, 0(r18)
br      display_gt3
display_hB:
movi    r16, 11
bgtu    r4, r16, display_hC
movi    r16, HEXB
stb     r16, 0(r18)
br      display_gt3
display_hC:
movi    r16, 12
bgtu    r4, r16, display_hD
movi    r16, HEXC
stb     r16, 0(r18)
br      display_gt3
display_hD:
movi    r16, 13
bgtu    r4, r16, display_hE
movi    r16, HEXD
stb     r16, 0(r18)
br      display_gt3
display_hE:
movi    r16, 14
bgtu    r4, r16, display_hF
movi    r16, HEXE
stb     r16, 0(r18)
br      display_gt3
display_hF:
movi    r16, HEXF
stb     r16, 0(r18)

display_gt3:
stb     r16, 0(r18)         # store hex value into memory
movi    r17, 3              # comparison value to see if display is 0-3
bgtu    r5, r17, display_gt5 # if display > 3, check if < 6
movia   r17, HEX1_BASE      # else set address to base1
movia   r18, HEX_3          # set r18 to 4 bytes past hex0
br      display_swap        # check which hex value to display
display_gt5:
movi    r17, 5              # comparison value to see if display is 4-5
bgtu    r5, r17, display_cap # if > 5 set to 5
movia   r17, HEX2_BASE      # else set address to base2
movia   r18, HEX_5          # set r18 to 4 bytes past hex4
addi    r18, r18, 2
br      display_swap        # check which hex value to display
display_cap:
movia   r17, HEX2_BASE      # set to hex5 if argument is > 5
movia   r18, HEX_5          # set r18 to 4 bytes past hex4
addi    r18, r18, 2

display_swap:
movi    r4, 0               # counter
movi    r5, 4               # end condition
mov     r20, r0             # initialize data word to 0
display_swap_loop:
beq     r4, r5, display_store # end condition
ldb     r19, 0(r18)         # load byte from memory
slli    r20, r20, 8         # shift r20
or      r20, r20, r19       # store into r20
addi    r4, r4, 1           # increment counter
subi    r18, r18, 1         # decrement memory address
br      display_swap_loop   # loop

display_store:
stwio   r20, 0(r17)

display_epilogue:
ldw     r16, 0(sp)
ldw     r17, 4(sp)
ldw     r18, 8(sp)
ldw     r19, 12(sp)
ldw     r20, 16(sp)
addi    sp, sp, 20

ret

/* end display_hex */
