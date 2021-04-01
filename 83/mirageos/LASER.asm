
;*************************************************************
;
; Laser Mayhem v1.1
; =================
;
; by badja
; 25 June 1999
;
; ported to ION by Andrew Magness
; Oct 11,1999
;
; MirageOS Port by Andrew Magness
; July 25, 2000
; 
; http://move.to/badja
; badja@alphalink.com.au
;
; You may modify this source code for personal use only.
; You may NOT distribute the modified source or program file.
;
; Laser Mayhem is based on Laserstrike for Windows by Kevin Ng
;
;*************************************************************

#include	"ti83plus.inc"			;Standard TI-83 Plus include file
#include      "mirage.inc"			;Mirage include file

	.org    $9d93				;Origin
	.db     $BB,$6D				;Compiled AsmPrgm token
	ret					;Header Byte 1 -- So TIOS wont run
	.db	1				;Header Byte 2 -- Identifies as MirageOS prog
button:						;Button - should be a 15x15 graphic
	.db	%00000000,%00000000
	.db	%00111001,%10000000
	.db	%01000101,%10000000
	.db	%01010101,%10000000
	.db	%01101101,%11100000
	.db	%00111001,%11100000
	.db	%00000000,%00000000
	.db	%00010000,%01101100
	.db	%00010000,%01111100
	.db	%01010000,%01111100
	.db	%01100000,%01101100
	.db	%01010111,%01101100
	.db	%01001000,%00000000
	.db	%01111100,%00000000
	.db	%00000000,%00000000
strDescription:			;Description - zero terminated
	.db	"Laser Mayhem 1.1",0

array	.equ	saferam1
sfp	.equ	array+96
temp	.equ	sfp+2

xPos	.equ	0
yPos	.equ	xPos+1
dx	.equ	yPos+1
dy	.equ	dx+1
xOld	.equ	dy+1
yOld	.equ	xOld+1
xSrc	.equ	yOld+1
ySrc	.equ	xSrc+1
item	.equ	ySrc+1
hide	.equ	item+1
place	.equ	hide+2
levdata	.equ	place+2
numlevs	.equ	levdata+2

progstart:					;Program code starts here
	ld	hl,(progptr)
	ld	ix,strDetect
	call	idetect
	ret	nz
	ld	ix,sfp+4

firstLevel:
	ld	hl,(progptr)
	ld	(ix+place),h
	ld	(ix+place+1),l
showTitle:
	bcall(_ClrLCDFull)
	ld	bc,$0001
	ld	(CURROW),bc
	ld	hl,strDescription
	bcall(_puts)
	ld	de,256*18+6
;	ld	(PENCOL),bc
	ld	hl,strEmail
	call setvputs
;	bcall(_vputs)
	ld	de,256*28+16
;	ld	(PENCOL),bc
	ld	hl,str2nd
	call setvputs
;	bcall(_vputs)
	ld	de,256*36+8
;	ld	(PENCOL),bc
	ld	hl,strAlpha
	call setvputs
;	bcall(_vputs)
	ld	de,256*48+4
;	ld	(PENCOL),bc
	ld	hl,strPorter
	call setvputs
;	bcall(_vputs)
	ld	de,256*54+12
;	ld	(PENCOL),bc
	ld	hl,strPorterM
	call setvputs
;	bcall(_vputs)
	ld	h,(ix+place)
	ld	l,(ix+place+1)
	push	ix
	ld	ix,strDetect
	call	idetect
	EI
	pop	ix
	jr	nz,firstLevel
;	ld	(ix+place),d
;	ld	(ix+place+1),e
	ld  de,256*36+34
;	ld	(pencol),bc
;	bcall(_vputs)
	call setvputs
	ld	a,(hl)
	ld	(ix+numlevs),a
	inc	hl
	ld	(ix+levdata),h
	ld	(ix+levdata+1),l

titleLoop:
	ld	a,$df
	call directin
	cp	127
	jp	z,showTitle

	ld	a,$fd
	call directin
	cp	191
	ret z

	ld	a,$bf
	call directin
	cp	223
	jr	z,newLevel
	jr	titleLoop

newLevel:
	bcall(_ClrLCDFull)
	ld	bc,$0703
	ld	(currow),bc
	ld	h,(ix+levdata)
	ld	l,(ix+levdata+1)
	ld	l,(hl)
	ld	h,0
	inc	hl
	bcall(_dispHL)
	ld	a,3
	ld	(curcol),a
	ld	hl,strLevel
	bcall(_puts)
	call	delayPause
	ld	bc,$c0ff
levelLoop:

	ld	a,$fd
	call directin
	cp	253
	call	z,nextLevel
	cp	251
	call	z,prevLevel
	dec	bc
	ld	a,b
	or a
	jr	nz,levelLoop

	bcall(_grbufclr)
	call	loadLevel
	ld	(ix+xPos),0
	ld	(ix+yPos),0
	ld	b,8
mainY:
	push	bc
	ld	b,12
mainX:
	push	bc
	call	getItem
	call	drawSprite
	inc	(ix+xPos)
	pop	bc
	djnz	mainX
	ld	(ix+xPos),0
	inc	(ix+yPos)
	pop	bc
	djnz	mainY
	ld	(ix+xPos),0
	ld	(ix+yPos),0
	call ifastcopy
	ld	(ix+hide),0
mainLoop:

	ld	a,$fe
	call directin
	cp	254
	call	z,mainDown
	cp	253
	call	z,mainLeft
	cp	251
	call	z,mainRight
	cp	247
	call	z,mainUp

	ld	a,$fd
	call directin
	cp	253
	call	z,nextLevel
	cp	251
	call	z,prevLevel
	cp	191
	ret z

	ld	a,$bf
	call directin
	cp	223
	call	z,main2nd
	cp	127
	jp	z,newLevel
	ld	b,(ix+hide)
	ld	c,(ix+hide+1)
	ld	a,b
	or a
	jr	z,mainLoop
	dec	bc
	ld	(ix+hide),b
	ld	(ix+hide+1),c
	ld	a,b
	or a
	jr	nz,mainLoop
	ld	bc,cursor
	call	xorSprite
	call ifastcopy
	jr	mainLoop

mainUp:
	ld	a,(ix+hide)
	or a
	jr	z,upSkip
	ld	bc,cursor
	call	xorSprite
upSkip:
	dec	(ix+yPos)
	ld	a,(ix+yPos)
	cp	-1
	jp	nz,delay
	ld	(ix+yPos),7
	jp	delay

mainRight:
	ld	a,(ix+hide)
	or a
	jr	z,rightSkip
	ld	bc,cursor
	call	xorSprite
rightSkip:
	inc	(ix+xPos)
	ld	a,(ix+xPos)
	cp	12
	jp	nz,delay
	ld	(ix+xPos),0
	jp	delay

mainLeft:
	ld	a,(ix+hide)
	or a
	jr	z,leftSkip
	ld	bc,cursor
	call	xorSprite
leftSkip:
	dec	(ix+xPos)
	ld	a,(ix+xPos)
	cp	-1
	jp	nz,delay
	ld	(ix+xPos),11
	jp	delay

mainDown:
	ld	a,(ix+hide)
	or a
	jr	z,downSkip
	ld	bc,cursor
	call	xorSprite
downSkip:
	inc	(ix+yPos)
	ld	a,(ix+yPos)
	cp	8
	jp	nz,delay
	ld	(ix+yPos),0
	jp	delay

main2nd:
	ld	a,(ix+hide)
	or a
	jr	nz,skip2nd
	ld	bc,cursor
	call	xorSprite
	call ifastcopy
skip2nd:
	ld	(ix+hide),$ff
	ld	(ix+hide+1),$ff
	ld	a,(ix+xPos)
	ld	(ix+xOld),a
	ld	a,(ix+yPos)
	ld	(ix+yOld),a
	call	getItem
	cp	1
	jp	z,fireUp
	cp	2
	jp	z,fireRight
	cp	3
	jp	z,fireDown
	cp	4
	jp	z,fireLeft
	cp	16
	jp	z,shiftUp
	cp	17
	jp	z,shiftRight
	cp	18
	jp	z,shiftDown
	cp	19
	jp	z,shiftLeft
	cp	20
	jp	z,fireUp
	cp	21
	jp	z,fireRight
	cp	22
	jp	z,fireDown
	cp	23
	jp	z,fireLeft
	ret

shiftUp:
	ld	(ix+dx),0
	ld	(ix+dy),1
	jp	shift

shiftRight:
	ld	(ix+dx),-1
	ld	(ix+dy),0
	jp	shift

shiftDown:
	ld	(ix+dx),0
	ld	(ix+dy),-1
	jp	shift

shiftLeft:
	ld	(ix+dx),1
	ld	(ix+dy),0


shift:
	call	getItem
	ld	(ix+item),a
	ld	a,(ix+yPos)
	ld	(ix+ySrc),a
	ld	a,(ix+xPos)
	ld	(ix+xSrc),a
	add	a,(ix+dx)
	ld	(ix+xPos),a
	cp	-1
	jp	z,delayFire
	cp	12
	jp	z,delayFire
	ld	a,(ix+yPos)
	add	a,(ix+dy)
	ld	(ix+yPos),a
	cp	-1
	jp	z,delayFire
	cp	8
	jp	z,delayFire

	ld	a,(ix+dx)
	or a
	jr	z,shiftNS
	call	getItem
	cp	1
	jr	z,checkTrack
	cp	3
	jr	z,checkTrack
	cp	17
	jp	z,arrowE
	cp	19
	jp	z,arrowW
	jr	shift
shiftNS:
	call	getItem
	cp	2
	jr	z,checkTrack
	cp	4
	jr	z,checkTrack
	cp	16
	jp	z,arrowN
	cp	18
	jp	z,arrowS
	jr	shift
checkTrack:
	ld	a,(ix+dx)
	or a
	jr	z,trackNS
	ld	a,(ix+item)
	cp	5
	jr	z,makeShift
	jr	shift
trackNS:
	ld	a,(ix+item)
	cp	6
	jr	z,makeShift
	jp	shift
makeShift:
	push	af
	call	getItem
	ld	(ix+item),a
	call	drawSprite
	pop	af
	call	putItem
	call	drawSprite
	ld	a,(ix+xSrc)
	ld	(ix+xPos),a
	ld	a,(ix+ySrc)
	ld	(ix+yPos),a
	call	getItem
	call	drawSprite
	ld	a,(ix+item)
	call	putItem
	call	drawSprite
	jp	delayFire

arrowN:
	ld	a,(ix+dy)
	cp	-1
	jp	z,delayFire
	jp	shift

arrowE:
	ld	a,(ix+dx)
	cp	1
	jp	z,delayFire
	jp	shift

arrowS:
	ld	a,(ix+dy)
	cp	1
	jp	z,delayFire
	jp	shift

arrowW:
	ld	a,(ix+dx)
	cp	-1
	jp	z,delayFire
	jp	shift

fireUp:
	ld	(ix+dx),0
	ld	(ix+dy),-1
	jp	fire

fireRight:
	ld	(ix+dx),1
	ld	(ix+dy),0
	jp	fire

fireDown:
	ld	(ix+dx),0
	ld	(ix+dy),1
	jp	fire

fireLeft:
	ld	(ix+dx),-1
	ld	(ix+dy),0
	jp	fire

fire:
	ld	a,(ix+xPos)
	add	a,(ix+dx)
	ld	(ix+xPos),a
	cp	-1
	jp	z,delayFire
	cp	12
	jp	z,delayFire
	ld	a,(ix+yPos)
	add	a,(ix+dy)
	ld	(ix+yPos),a
	cp	-1
	jp	z,delayFire
	cp	8
	jp	z,delayFire
	call	getItem
	or a
	jp z,here
;	cp	1
;	jp	z,destroy
;	cp	2
;	jp	z,destroy
;	cp	3
;	jp	z,destroy
;	cp	4
;	jp	z,destroy
;	cp	5
;	jp	z,destroy
;	cp	6
;	jp	z,destroy
    cp 7
    jp c, destroy
    jp z, mirrorNW

;	cp	7
;	jp	z,mirrorNW
	cp	8
	jp	z,mirrorNE
	cp	9
	jp	z,mirrorSE
	cp	10
	jp	z,mirrorSW
	cp	11
	jp	z,moveItem
	cp	13
	jp	z,hitBrick
	cp	14
	jp	z,killBrick
	cp	15
	jp	z,openIris
	cp	20
	jp	z,rotatePod
	cp	21
	jp	z,rotatePod
	cp	22
	jp	z,rotatePod
	cp	23
	jp	z,rotatePod

;    cp 24
;    jp c, rotatePod
;    jp z, closeGate


	cp	24
	jp	z,closeGate
	cp	25
	jp	z,moveItem
	cp	26
	jp	z,rotateGateEW
	cp	27
	jp	z,rotateGateNS
	cp	29
	jp	z,moveItem
	cp	30
	jp	z,moveItem
	cp	31
	jp	z,nextLevel
here:
	or a
	jp	nz,delayFire
	call	drawLaser
	call	delaySkip
	call	drawLaser
	jp	fire

destroy:
	call	drawSprite
	ld	a,28
	call	putItem
	call	drawSprite
	jp	delayFire

mirrorNW:
	ld	a,(ix+dx)
	cp	-1
	jp	z,moveItem
	cp	1
	jr	z,reflectNW
	ld	a,(ix+dy)
	cp	-1
	jp	z,moveItem
reflectNW:
	ld	bc,laserNW
	call	xorSprite
	ld	a,(ix+dx)
	or a
	jr	z,skipNW
	ld	(ix+dx),0
	ld	(ix+dy),-1
	jr	drawNW
skipNW:
	ld	(ix+dx),-1
	ld	(ix+dy),0
drawNW:
	call	delaySkip
	ld	bc,laserNW
	call	xorSprite
	jp	fire

mirrorNE:
	ld	a,(ix+dx)
	cp	1
	jp	z,moveItem
	cp	-1
	jr	z,reflectNE
	ld	a,(ix+dy)
	cp	-1
	jp	z,moveItem
reflectNE:
	ld	bc,laserNE
	call	xorSprite
	ld	a,(ix+dx)
	or a
	jr	z,skipNE
	ld	(ix+dx),0
	ld	(ix+dy),-1
	jr	drawNE
skipNE:
	ld	(ix+dx),1
	ld	(ix+dy),0
drawNE:
	call	delaySkip
	ld	bc,laserNE
	call	xorSprite
	jp	fire

mirrorSE:
	ld	a,(ix+dx)
	cp	1
	jp	z,moveItem
	cp	-1
	jr	z,reflectSE
	ld	a,(ix+dy)
	cp	1
	jp	z,moveItem
reflectSE:
	ld	bc,laserSE
	call	xorSprite
	ld	a,(ix+dx)
	or a
	jr	z,skipSE
	ld	(ix+dx),0
	ld	(ix+dy),1
	jr	drawSE
skipSE:
	ld	(ix+dx),1
	ld	(ix+dy),0
drawSE:
	call	delaySkip
	ld	bc,laserSE
	call	xorSprite
	jp	fire

mirrorSW:
	ld	a,(ix+dx)
	cp	-1
	jp	z,moveItem
	cp	1
	jr	z,reflectSW
	ld	a,(ix+dy)
	cp	1
	jp	z,moveItem
reflectSW:
	ld	bc,laserSW
	call	xorSprite
	ld	a,(ix+dx)
	or a
	jr	z,skipSW
	ld	(ix+dx),0
	ld	(ix+dy),1
	jr	drawSW
skipSW:
	ld	(ix+dx),-1
	ld	(ix+dy),0
drawSW:
	call	delaySkip
	ld	bc,laserSW
	call	xorSprite
	jp	fire

moveItem:
	call	getItem
	ld	(ix+item),a
	ld	a,(ix+xPos)
	ld	(ix+xSrc),a
	ld	b,(ix+yPos)
	ld	(ix+ySrc),b
	add	a,(ix+dx)
	ld	(ix+xPos),a
	cp	-1
	jp	z,delayFire
	cp	12
	jp	z,delayFire
	ld	a,b
	add	a,(ix+dy)
	ld	(ix+yPos),a
	cp	-1
	jp	z,delayFire
	cp	8
	jp	z,delayFire
	ld	a,(ix+item)
	cp	25
	jp	z,moveSlime
	call	getItem

	cp	7
	jp	z,moveNW
	cp	8
	jp	z,moveNE
	cp	9
	jp	z,moveSE
	cp	10
	jp	z,moveSW
    or a
	jp	z,makeMove
	jp	delayFire

moveSlime:
	call	getItem

	cp	25
	jp	z,delayFire
	or a
	jp	z,makeMove
	call	drawSprite
	xor a
	call	putItem
	ld	a,(ix+xSrc)
	ld	(ix+xPos),a
	ld	a,(ix+ySrc)
	ld	(ix+yPos),a
	ld	a,25
	call	drawSprite
	xor a
	call	putItem
	jp	delayFire

moveNW:
	ld	a,(ix+item)
	cp	9
	jp	nz,delayFire
	ld	a,(ix+dx)
	cp	1
	jr	z,joinNW
	ld	a,(ix+dy)
	cp	1
	jr	z,joinNW
	jp	delayFire
joinNW:
	call	getItem
	call	drawSprite
	ld	a,29
	jp	joinEnd

moveNE:
	ld	a,(ix+item)
	cp	10
	jp	nz,delayFire
	ld	a,(ix+dx)
	cp	-1
	jr	z,joinNE
	ld	a,(ix+dy)
	cp	1
	jr	z,joinNE
	jp	delayFire
joinNE:
	call	getItem
	call	drawSprite
	ld	a,30
	jp	joinEnd

moveSE:
	ld	a,(ix+item)
	cp	7
	jp	nz,delayFire
	ld	a,(ix+dx)
	cp	-1
	jr	z,joinSE
	ld	a,(ix+dy)
	cp	-1
	jr	z,joinSE
	jp	delayFire
joinSE:
	call	getItem
	call	drawSprite
	ld	a,29
	jp	joinEnd

moveSW:
	ld	a,(ix+item)
	cp	8
	jp	nz,delayFire
	ld	a,(ix+dx)
	cp	1
	jr	z,joinSW
	ld	a,(ix+dy)
	cp	-1
	jr	z,joinSW
	jp	delayFire
joinSW:
	call	getItem
	call	drawSprite
	ld	a,30

joinEnd:
	call	putItem
	call	drawSprite
	ld	a,(ix+xSrc)
	ld	(ix+xPos),a
	ld	a,(ix+ySrc)
	ld	(ix+yPos),a
	ld	a,(ix+item)
	call	drawSprite
	xor a
	call	putItem
	jp	delayFire

hitBrick:
	call	drawSprite
	ld	a,14
	call	putItem
	call	drawSprite
	jp	delayFire

killBrick:
	call	drawSprite
	xor a
	call	putItem
	jp	delayFire

openIris:
	call	drawSprite
	ld	a,31
	call	putItem
	call	drawSprite
	jp	delayFire

rotatePod:
	call	drawSprite
	call	getItem
	inc a
	cp	24
	jr	nz,rotateSkip
	ld	a,20
rotateSkip:
	call	putItem
	call	drawSprite
	jp	delayFire

closeGate:
	call	drawSprite
	ld	a,12
	call	putItem
	call	drawSprite
	call	delaySkip
	jp	fire

rotateGateEW:
	ld	a,(ix+dx)
	or a
	jp	z,delayFire
	call	getItem
	call	drawSprite
	ld	a,27
	call	putItem
	call	drawSprite
	call	delaySkip
	jp	fire

rotateGateNS:
	ld	a,(ix+dx)
	or a
	jp	nz,delayFire
	call	getItem
	call	drawSprite
	ld	a,26
	call	putItem
	call	drawSprite
	call	delaySkip
	jp	fire

nextLevel:
	pop	bc
	ld	h,(ix+levdata)
	ld	l,(ix+levdata+1)
	ld	a,(hl)
	inc	a
	ld	(hl),a
	ld	b,(ix+numlevs)
	cp	b
	jp	nz,newLevel
	ld	(hl),0
	jp	newLevel

prevLevel:
	pop	bc
	ld	h,(ix+levdata)
	ld	l,(ix+levdata+1)
	ld	a,(hl)
	dec	a
	ld	(hl),a
	cp	-1
	jp	nz,newLevel
	ld	a,(ix+numlevs)
	dec	a
	ld	(hl),a
	jp	newLevel

drawLaser:
	ld	a,(ix+dx)
	or a
	jr	z,laserVertical
	ld	bc,laserEW
	jr	laserDraw
laserVertical:
	ld	bc,laserNS
laserDraw:
	jp	xorSprite
	
loadLevel:
	push	ix
	ld	h,(ix+levdata)
	ld	l,(ix+levdata+1)
	ld	a,(hl)
	inc	hl
	or a
	jr	z,loadSkip
	ld	b,a
	ld	de,60
loadAdd:
	add	hl,de
	djnz	loadAdd
loadSkip:
	ld	ix,array
	push	bc
	push	bc
	push	bc
	ld	(sfp),sp
	ld	b,12
loadLoop:
	push	bc
	ld	de,(sfp)
	ld	bc,5
	ldir
	push	ix
	ld	ix,(sfp)
	ld	a,(ix+4)
	call	rotate
	pop	ix
	and	%00011111
	ld	(ix+7),a
	push	ix
	ld	ix,(sfp)
	ld	a,(ix+1)
	call	rotate
	pop	ix
	and	%00011111
	ld	(ix+2),a
	push	ix
	ld	ix,(sfp)
	ld	a,(ix+3)
	call	rotate
	pop	ix
	and	%00011111
	ld	(ix+5),a
	push	ix
	ld	ix,(sfp)
	ld	a,(ix+0)
	call	rotate
	pop	ix
	and	%00011111
	ld	(ix+0),a
	push	ix
	ld	ix,(sfp)
	ld	a,(ix+2)
	call	rotate
	pop	ix
	and	%00011111
	ld	(ix+3),a
	push	ix
	ld	ix,(sfp)
	ld	a,(ix+4)
	call	rotate
	pop	ix
	and	%00011111
	ld	(ix+6),a
	push	ix
	ld	ix,(sfp)
	ld	a,(ix+1)
	call	rotate
	pop	ix
	and	%00011111
	ld	(ix+1),a
	push	ix
	ld	ix,(sfp)
	ld	a,(ix+3)
	pop	ix
	and	%00011111
	ld	(ix+4),a
	ld	bc,8
	add	ix,bc
	pop	bc
	dec	b
	jp	nz,loadLoop
	pop	bc
	pop	bc
	pop	bc
	pop	ix
	ret

rotate:
	srl	(ix+0)
	rr	(ix+1)
	rr	(ix+2)
	rr	(ix+3)
	rr	(ix+4)
	ret

drawSprite:
	add a,a
	add a,a
	add a,a
	ld	hl,sprites
	ld	c,a
	add	hl,bc
	ld	b,h
	ld	c,l
;	jp	xorSprite
	
xorSprite:
	ld	a,(ix+xPos)
	add a,a
	add a,a
	add a,a
	ld	l,(ix+yPos)
	sla	l
	sla	l
	sla	l
	push	ix
	ld	(temp),bc
	ld	ix,(temp)
;	ld	b,8
	call	putsprite8
	pop	ix
	ret

getItem:
	call	findLoc
	ld	a,(hl)
	ret

putItem:
	push	af
	call	findLoc
	pop	af
	ld	(hl),a
	ret

findLoc:
	ld	a,(ix+yPos)
	add a,a
	add a,a
	add a,a
	ld	e,(ix+yPos)
	sla e
	sla e
	add	a,e
	ld	e,(ix+xPos)
	add	a,e
	ld	hl,array
	ld	b,0
	ld	c,a
	add	hl,bc
	ret

makeMove:
	ld	a,(ix+item)
	call	putItem
	call	drawSprite
	ld	a,(ix+xSrc)
	ld	(ix+xPos),a
	ld	a,(ix+ySrc)
	ld	(ix+yPos),a
	ld	a,(ix+item)
	call	drawSprite
	xor a
	call	putItem

delayFire:
	ld	a,(ix+xOld)
	ld	(ix+xPos),a
	ld	a,(ix+yOld)
	ld	(ix+yPos),a
	jr	delaySkip

delay:
	ld	(ix+hide),$ff
	ld	(ix+hide+1),$ff
	ld	bc,cursor
	call	xorSprite
delaySkip:
	call ifastcopy
delayPause:
	ld	bc,$70ff
delayLoop:
	dec	bc
	ld	a,b
	or a
	jr	nz,delayLoop
	ret

exitGame:
;	bcall(_cleartextshad)
;	call	_RSTRSHADOW
;	bcall(_cleargbuf)     
;	bcall(_GetKey)
;	bcall(_homeUp)
	ret

strEmail
	.db	"badja@alphalink.com.au",0
str2nd:
	.db	"2nd - Play the game",0
strAlpha:
	.db	"ALPHA -",0

cursor:
	.db	%11111111
	.db	%11111111
	.db	%11111111
	.db	%11111111
	.db	%11111111
	.db	%11111111
	.db	%11111111
	.db	%11111111

laserNS:
	.db	%00011000
	.db	%00011000
	.db	%00011000
	.db	%00011000
	.db	%00011000
	.db	%00011000
	.db	%00011000
	.db	%00011000

strPorter:
	.db	"MOS Port: Andrew Magness"

laserEW:
	.db	%00000000
	.db	%00000000
	.db	%00000000
	.db	%11111111
	.db	%11111111
	.db	%00000000
	.db	%00000000
	.db	%00000000

laserNW:
	.db	%00011000
	.db	%00011000
	.db	%00011000
	.db	%11110000
	.db	%11100000
	.db	%00000000
	.db	%00000000
	.db	%00000000

laserNE:
	.db	%00011000
	.db	%00011000
	.db	%00011000
	.db	%00001111
	.db	%00000111
	.db	%00000000
	.db	%00000000
	.db	%00000000

strDetect:
	.db	"LaserMay"

laserSE:
	.db	%00000000
	.db	%00000000
	.db	%00000000
	.db	%00000111
	.db	%00001111
	.db	%00011000
	.db	%00011000
	.db	%00011000

strLevel:
	.db	"Level"

laserSW:
	.db	%00000000
	.db	%00000000
	.db	%00000000
	.db	%11100000
	.db	%11110000
	.db	%00011000
	.db	%00011000
	.db	%00011000


strPorterM:
	.db	"<andrew@calc.org>"

sprites:
	.db	%00000000
	.db	%00000000
	.db	%00000000
	.db	%00000000
	.db	%00000000
	.db	%00000000
	.db	%00000000
	.db	%00000000

	.db	%00111100
	.db	%11100111
	.db	%10100101
	.db	%10100101
	.db	%10100101
	.db	%10011001
	.db	%10000001
	.db	%01111110

	.db	%01111110
	.db	%10000010
	.db	%10011111
	.db	%10100001
	.db	%10100001
	.db	%10011111
	.db	%10000010
	.db	%01111110

	.db	%01111110
	.db	%10000001
	.db	%10011001
	.db	%10100101
	.db	%10100101
	.db	%10100101
	.db	%11100111
	.db	%00111100

	.db	%01111110
	.db	%01000001
	.db	%11111001
	.db	%10000101
	.db	%10000101
	.db	%11111001
	.db	%01000001
	.db	%01111110

	.db	%00000000
	.db	%11111111
	.db	%00000000
	.db	%00000000
	.db	%00000000
	.db	%00000000
	.db	%11111111
	.db	%00000000

	.db	%01000010
	.db	%01000010
	.db	%01000010
	.db	%01000010
	.db	%01000010
	.db	%01000010
	.db	%01000010
	.db	%01000010

	.db	%00000000
	.db	%00000010
	.db	%00000110
	.db	%00001110
	.db	%00011010
	.db	%00110010
	.db	%01111110
	.db	%00000000

	.db	%00000000
	.db	%01000000
	.db	%01100000
	.db	%01110000
	.db	%01011000
	.db	%01001100
	.db	%01111110
	.db	%00000000

	.db	%00000000
	.db	%01111110
	.db	%01001100
	.db	%01011000
	.db	%01110000
	.db	%01100000
	.db	%01000000
	.db	%00000000

	.db	%00000000
	.db	%01111110
	.db	%00110010
	.db	%00011010
	.db	%00001110
	.db	%00000110
	.db	%00000010
	.db	%00000000

	.db	%00000000
	.db	%01111110
	.db	%01000010
	.db	%01011010
	.db	%01011010
	.db	%01000010
	.db	%01111110
	.db	%00000000

	.db	%11111111
	.db	%10111101
	.db	%11111111
	.db	%11111111
	.db	%11111111
	.db	%11111111
	.db	%10111101
	.db	%11111111

	.db	%11111111
	.db	%10001000
	.db	%11111111
	.db	%00100010
	.db	%11111111
	.db	%10001000
	.db	%11111111
	.db	%00100010

	.db	%01101101
	.db	%10001000
	.db	%11011011
	.db	%00100010
	.db	%10110110
	.db	%10001000
	.db	%01101101
	.db	%00100010

	.db	%00111100
	.db	%01001010
	.db	%10001001
	.db	%11111001
	.db	%10011111
	.db	%10010001
	.db	%01010010
	.db	%00111100

	.db	%11111111
	.db	%10000001
	.db	%10011001
	.db	%10111101
	.db	%10011001
	.db	%10011001
	.db	%10000001
	.db	%11111111

	.db	%11111111
	.db	%10000001
	.db	%10001001
	.db	%10111101
	.db	%10111101
	.db	%10001001
	.db	%10000001
	.db	%11111111

	.db	%11111111
	.db	%10000001
	.db	%10011001
	.db	%10011001
	.db	%10111101
	.db	%10011001
	.db	%10000001
	.db	%11111111

	.db	%11111111
	.db	%10000001
	.db	%10010001
	.db	%10111101
	.db	%10111101
	.db	%10010001
	.db	%10000001
	.db	%11111111

	.db	%00111100
	.db	%01100110
	.db	%10100101
	.db	%10100101
	.db	%10100101
	.db	%10011001
	.db	%01000010
	.db	%00111100

	.db	%00111100
	.db	%01000010
	.db	%10011111
	.db	%10100001
	.db	%10100001
	.db	%10011111
	.db	%01000010
	.db	%00111100

	.db	%00111100
	.db	%01000010
	.db	%10011001
	.db	%10100101
	.db	%10100101
	.db	%10100101
	.db	%01100110
	.db	%00111100

	.db	%00111100
	.db	%01000010
	.db	%11111001
	.db	%10000101
	.db	%10000101
	.db	%11111001
	.db	%01000010
	.db	%00111100

	.db	%11100111
	.db	%11100111
	.db	%11100111
	.db	%00000000
	.db	%00000000
	.db	%11100111
	.db	%11100111
	.db	%11100111

	.db	%00110000
	.db	%01001110
	.db	%01000001
	.db	%10000001
	.db	%10000010
	.db	%01000001
	.db	%01011001
	.db	%00100110

	.db	%00111100
	.db	%01111110
	.db	%11111111
	.db	%00000000
	.db	%00000000
	.db	%11111111
	.db	%01111110
	.db	%00111100

	.db	%00100100
	.db	%01100110
	.db	%11100111
	.db	%11100111
	.db	%11100111
	.db	%11100111
	.db	%01100110
	.db	%00100100

	.db	%01010100
	.db	%01000011
	.db	%00010100
	.db	%01001010
	.db	%10100000
	.db	%00010101
	.db	%11000010
	.db	%00101010

	.db	%00000000
	.db	%01111110
	.db	%01001110
	.db	%01011110
	.db	%01111010
	.db	%01110010
	.db	%01111110
	.db	%00000000

	.db	%00000000
	.db	%01111110
	.db	%01110010
	.db	%01111010
	.db	%01011110
	.db	%01001110
	.db	%01111110
	.db	%00000000

	.db	%00111100
	.db	%01000010
	.db	%10000001
	.db	%10000001
	.db	%10000001
	.db	%10000001
	.db	%01000010
	.db	%00111100

.end
