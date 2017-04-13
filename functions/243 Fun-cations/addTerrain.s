.equ lifeSpan,20

.global addTerrain

addTerrain:
mov r8,r4 #x
mov r9,r5 #y
mov r10,r7 #linlength
mov r11,r0 #counter i=0

addTerrainFor:
beq r11,r10,endAddTerrain

ldw r12,0(r4)
ldw r13,4(r4)
add r12,r12,r13
ldw r13,8(r4)
add r12,r12,r13 #p[i].x + y + lifeSpan = r12

beq r12,r0,addIntoTerrain #if r12 = 0, insert , then end
addi r11,r11,1 #i++
addi r4,r4,12 #nexgt array value
br addTerrainFor

addIntoTerrain:
stw r8,0(r4)
stw r9,4(r4)
mov r14,lifeSpan
stw r14,8(r4)
br endAddTerrain:


endAddTerrain:
ret