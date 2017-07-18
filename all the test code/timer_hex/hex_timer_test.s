/* This program is used as a unit section to test the hex display
 *
 * This code loops through each of the 6 hex displays and cycles through hex
 * values 0-F with 1 second delay between each change.
 *
 * C equivalent:
 * for(;;){
 *     for(int i = 0; i != 6; i++){
 *         for(int j = 0; j != 16; j++){
 *            display_hex(j,i);
 *            delay(1000);
 *         }
 *     }
 * }
 */

.equ STACK_START,           0x03FFFFFF

.align 2
.text
.global _start
_start:

movia   sp, STACK_START     # initialize stack pointer

movi    r4, 0               # iterator j = 0
movi    r5, 0               # iterator i = 0

movi    r6, 6               # end condition i
movi    r7, 16              # end condition j

loop1:
beq     r5, r6, loop1_end   # while i != 6, loop through 0-5

loop2:
beq     r4, r7, loop2_end   # while j != 16, loop through 0-15
subi    sp, sp, 8           # store r4 in stack before function call
stw     r4, 0(sp)
stw     r5, 4(sp)
call    display_hex         # display value r4 on hex r5

movi    r4, 250
call    delay               # delay and keep value on hex for 1000ms

ldw     r4, 0(sp)           # restore value of r4 from stack
ldw     r5, 4(sp)
addi    sp, sp, 8
addi    r4, r4, 1           # increment r4, j++
br      loop2               # loop again and check condition

loop2_end:
mov     r4, r0              # reset the value of r4 to 0 for next iteration
subi    sp, sp, 8
stw     r4, 0(sp)
stw     r5, 4(sp)
call    display_hex
ldw     r4, 0(sp)
ldw     r5, 4(sp)
addi    sp, sp, 8
addi    r5, r5, 1           # increment r5, i++
br      loop1               # check loop condition

loop1_end:
br      _start              # loop and run infinitely
