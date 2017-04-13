.global downTickTerrain

downTickTerrain:
mov r11,r5
mov r8,r0

beginTickFor:

beq r8,r11,endTick

ldw r9,8(r4)
bgt r9,r0,lifeProcessTick

stw r0,0(r4)
stw r0,4(r4)
stw r0,8(r4)
addi r4,r4,12
addi r8,r8,1
br beginTickFor 

lifeProcessTick:
ldw r9, 0(r4)
blt r9,r0,setZerosTick
ldw r9,4(r4)
blt r9,r0,setZerosTick

ldw r9,8(r4)
subi r9,r9,1
stw r9,8(r4)
addi r4,r4,12
addi r8,r8,1
br beginTickFor

setZerosTick:
stw r0,0(r4)
stw r0,4(r4)
stw r0,8(r4)
addi r4,r4,12
addi r8,r8,1
br beginTickFor 

endTick:
ret