.equ max_x, 319
.equ max_y,239
.equ platLen, 30

.global advancePlatforms

advancePlatforms:
mov r8,r5 # SIZE OF PLATFORM ARRAY
mov r9,r6 #PLATFORM LENGTH
mov r10,r0 #r10 is for loop counter, STARTING AT 0

advancePlatformFor:
beq r10,r8,endAdvPlat # for loop condition, i < platformArraySize

ldw r11, 0(r4) #r11 = pf[i].x
beq r11,r0,recreateNewPlatform #if pf[i].x == 0, make new platform

#else condition
movi r13, 0(r4)
subi r13,r13,1
stw r13,0(r4) #pf[i].x -= 1
addi r10,r10,1 #i++
addi r4,r4,12 #shift r4 array up by 12 bytes since it a strcut with 3 ints
br advancePlatformFor

recreateNewPlatform: #if condition

movi r12,max_x #r12 = max_x

stw r12,0(r4) #pf[i].x = max_x

subi sp,sp,32 #save the regs before calling rand
stw r4,0(sp)
stw r8,4(sp)
stw r9,8(sp)
stw r10,12(sp)
stw r11,16(sp)
stw r12,20(sp)
stw r13,24(sp)
stw r14,28(sp)

movi r4,max_y #parameter to mod by

#call randomInt
ldw r4,0(sp)
ldw r8,4(sp)
ldw r9,8(sp)
ldw r10,12(sp)
ldw r11,16(sp)
ldw r12,20(sp)
ldw r13,24(sp)
ldw r14,28(sp)
addi sp,sp,32

stw r2,4(r4) #pf[i].y = rand()%max_y
movi r14,platLen
stw r14,8(r4) #pf[i].length = platLen

addi r10,r10,1 #i++
addi r4,r4,12 #shift r4 array up by 12 bytes since it a strcut with 3 ints
br advancePlatformFor

endAdvPlat:
ret
