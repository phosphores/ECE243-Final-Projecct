.global advanceDrawnTerrain

advanceDrawnTerrain:
mov r8,r5#linelength
mov r9,r0 #counte

advanceDrawnTerrainFor:
beq r9,r8,endAdvDrawnTerrain

ldw r10,0(r4) #r10 = p[i].x
bgt r10,r0,advanceTerrainIf #decrement if p[i].x > 0
#else
stw r0,0(r4)
stw r0,4(r4)
stw r0,8(r4)
addi r9,r9,1
addi r4,r4,12
br advanceDrawnTerrainFor

advanceTerrainIf:#if condition
ldw r11,0(r4) #r11 = p[i].x
subi r11,r11,1
stw r11,0(r4)
addi r9,r9,1
addi r4,r4,12
br advanceDrawnTerrainFor

endAdvDrawnTerrain:
ret