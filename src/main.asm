
INCLUDE "hardware.inc/hardware.inc"
	rev_Check_hardware_inc 4.0

INCLUDE "utils.inc"
INCLUDE "tiles.inc"

SECTION "Header", ROM0[$100]

	; This is your ROM's entry point
	; You have 4 bytes of code to do... something
	di
	jp EntryPoint

	; Make sure to allocate some space for the header, so no important
	; code gets put there and later overwritten by RGBFIX.
	; RGBFIX is designed to operate over a zero-filled header, so make
	; sure to put zeros regardless of the padding value. (This feature
	; was introduced in RGBDS 0.4.0, but the -MG etc flags were also
	; introduced in that version.)
	ds $150 - @, 0

	EntryPoint:
	; Do not turn the LCD off outside of VBlank
	call WaitVBlank

	; Turn the LCD off
	ld a, 0
	ld [rLCDC], a

	; Copy the tile data
	ld de, Tiles
	ld hl, $9000
	ld bc, TilesEnd - Tiles
	call Memcopy

	; Copy the tilemap
	ld de, Tilemap
	ld hl, $9800
	ld bc, TilemapEnd - Tilemap
	call Memcopy

	; Copy the tile data
	ld de, Player
	ld hl, $8000
	ld bc, PlayerEnd - Player
	call Memcopy

	; Initialize object memory
	ld a, 0
	ld b, 160
	ld hl, _OAMRAM
	call ClearOam

	; Draw player object
	ld hl, _OAMRAM
	ld a, 4 + 16 ; Y
	ld [hli], a
	ld a, 80 + 8 - 4 ; X
	ld [hli], a
	ld a, $0 ; tile ID
	ld [hli], a
	ld a, %00000000 ; attributes
	ld [hl], a

	; Turn the LCD on
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16
	ld [rLCDC], a

	; During the first (blank) frame, initialize display registers
	ld a, %11100100
	ld [rBGP], a
	ld [rOBP0], a
	ld [rOBP1], a

	ld a, 0
	ld [wFrameCounter], a

	ld a, 0
	ld [wVel], a

	ld a, 0
	ld [wVelY], a
	
	ld a, 0
	ld [wVelX], a
	
	ld a, 4
	ld [wAccel], a
	
	ld a, 0
	ld [wAngle], a

	ld a, 0
	ld [wAngleNeg], a

Main:
	ld a, [rLY]
	cp 144
	jp nc, Main

	call WaitVBlank

	;;;;;;;; Refresh rate control
	ld a, [wFrameCounter]
	inc a
	ld [wFrameCounter], a
	
	cp a, 10 ;b ; Every 15 frames (a quarter of a second), run the following code
	jp nz, Main

	; Reset the frame counter back to 0
	ld a, 0
	ld [wFrameCounter], a
	;;;;;;;;

	;;;;;;;; updating Y position and velocity
	ld a, [wVelY]
	ld b, a

	ld a, [_OAMRAM ]
	; ld c, 0 + 16 - 8 + 4
	; ld d, 144 + 16 - 8 - 4
	; call CheckBoundsAndUpdateDirection
	add a, b ; update Y position with velocity value
	ld [_OAMRAM], a ; write back updated Y position

	;;;; handle angle-dependent acceleration and velocity update for Y
	ld a, [wVel]
	ld b, a
	ld a, [wAccel] ; base acceleration factor
	ld c, a
	ld a, [wAngle] ; (sin) can be either 0, 1/2, 1
	; 	                                0/2, 1/2, 2/2
	call ApplyProportionalToAngle
	ld c, a
	ld a, b
	add a, c
	ld [wVel], a

	;;;;;;;; distribute main speed to Y and X
	ld a, [wVel] ; main direction velocity
	ld c, a
	ld a, [wAngle]
	call ApplyProportionalToAngle
	ld [wVelY], a

	;;;;;;;; updating X position and velocity
	ld a, [wVelX]
	ld b, a

	ld a, [wAngleNeg]
	cp a, 1
	jp nc, MoveLeft

MoveRight:
	ld a, [_OAMRAM + 1]
	add a, b ; update X position with velocity value
	jp DoneMove
MoveLeft:
	ld a, [_OAMRAM + 1]
	sub a, b
DoneMove:
	ld [_OAMRAM + 1], a ; write back updated X position

	;;;;;;;; handle angle-dependent velocity update for X
	ld a, [wVel]
	ld c, a

	ld a, [wAngle] ; (sin) can be either 0, 1/2, 1
				   ; (cos)               2/2  1/2  0/2
	ld d, a
	ld a, 2        ; sin -> cos
	sub a, d

	call ApplyProportionalToAngle
	ld [wVelX], a
	
	;;;;;;;; X position is controlled with keys

	; Check the current keys every frame and move left or right.
	call UpdateKeys

	; First, check if the left button is pressed.
CheckLeft:
	ld a, [wCurKeys]
	and a, PADF_LEFT
	jp z, CheckRight
Left:
	ld a, [wAngleNeg]
	cp a, 1
	jp c, AngleNotNegative

	ld a, [wAngle]
	add a, 1
	jp NoFlipSign

AngleNotNegative:
	ld a, [wAngle]
	sub a, 1 

	jp nc, NoFlipSign
	ld a, 1
	ld [wAngleNeg], a

	ld b, 2
	call ClipByMaximum
	
NoFlipSign:
	ld [wAngle], a

	jp Main

; Then check the right button.
CheckRight:
	ld a, [wCurKeys]
	and a, PADF_RIGHT
	jp z, Main
Right:
	ld a, [wAngleNeg]
	cp a, 1
	jp nc, AngleNegative

	ld a, [wAngle]
	inc a
	jp NoFlipSignBack

AngleNegative:
	ld a, [wAngle]
	sub a, 1

	jp nz, NoFlipSignBack
	ld c, a
	ld a, 0
	ld [wAngleNeg], a
	ld a, c

	ld b, 2
	call ClipByMaximum
	
NoFlipSignBack:
	ld [wAngle], a

	jp Main

; @param a: value to be clipped
; @param b: max value to clip by
; @returns a: clipped to max value
ClipByMaximum:
	inc b
	cp a, b
	dec b
	jp c, NoClip
	ld a, b

NoClip:
	ret


; @param a: angle as denominator of either 0/2, 1/2, 2/2 
; @param b: current speed if need to set to zero
; @param c: base value to be applied proportionally
; @returns a: either zero or adjusted value
ApplyProportionalToAngle:
	cp a, 0
	jp z, Zero ; zero speed, rather

	cp a, 2
	jp z, SkipDivide
	; ; divide by 2
	srl c

SkipDivide:
	; ld a, b
	; add a, c ; increment and store velocity value
	ld a, c
	ret ; sets a, keeps b
Zero:
	; ld [wVel], a
	ld b, 0 ; resets b
	ret	; returns a = wAngle = 0

; @param a: coordinate
; @param b: current direction/speed
; @param c: lower limit
; @param d: higher limit 
CheckBoundsAndUpdateDirection:
	cp a, c
	jp z, ChangeDirectionPos

	cp a, d
	jp z, ChangeDirectionNeg

	ret

ChangeDirectionNeg:
	ld b, -1; Down
	
	ret

ChangeDirectionPos:
	ld b, 1; Down

	ret

SECTION "Counter", WRAM0
wFrameCounter: db

SECTION "Input Variables", WRAM0
wCurKeys: db
wNewKeys: db

SECTION "Player Variables", WRAM0
wVel: db

wVelY: db
wVelX: db

wAccel: db
wAngle: db

wAngleNeg: db
