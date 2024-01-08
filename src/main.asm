
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
	ld a, 1
	ld [wDirectionY], a ; direction
	ld a, 1
	ld [wDirectionX], a ; direction
	ld a, 15
	ld [wMotionMul], a

Main:
	ld a, [rLY]
	cp 144
	jp nc, Main

	call WaitVBlank

	ld a, [wMotionMul]
	ld b, a
	ld a, [wFrameCounter]
	inc a
	ld [wFrameCounter], a
	
	cp b ; Every 15 frames (a quarter of a second), run the following code
	jp nz, Main
	ld a, [wMotionMul]
	cp a, 1
	jp z, SkipAcceleration
	sub a, 1
	ld [wMotionMul], a
SkipAcceleration:

	; Reset the frame counter back to 0
	ld a, 0
	ld [wFrameCounter], a

	ld a, [wDirectionY]
	ld b, a
	ld a, [_OAMRAM ]
	ld c, 0 + 16 - 8 + 4
	ld d, 144 + 16 - 8 - 4
	call CheckBoundsAndUpdateDirection
	add a, b
	ld [_OAMRAM], a
	ld a, b
	; add a, 1
	ld [wDirectionY], a

	; Check the current keys every frame and move left or right.
	call UpdateKeys

	; First, check if the left button is pressed.
CheckLeft:
	ld a, [wCurKeys]
	and a, PADF_LEFT
	jp z, CheckRight
Left:
	; Move the paddle one pixel to the left.
	ld a, [_OAMRAM + 1]
	dec a
	dec a
	; If we've already hit the edge of the playfield, don't move.
	cp a, 0 + 8
	jp z, Main
	ld [_OAMRAM + 1], a
	jp Main

; Then check the right button.
CheckRight:
	ld a, [wCurKeys]
	and a, PADF_RIGHT
	jp z, Main
Right:
	; Move the paddle one pixel to the right.
	ld a, [_OAMRAM + 1]
	inc a
	inc a
	; If we've already hit the edge of the playfield, don't move.
	cp a, 160 + 8 - 8
	jp z, Main
	ld [_OAMRAM + 1], a
	jp Main

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
	ld b, 0;-1; Down
	
	ret

ChangeDirectionPos:
	ld b, 0;1; Down

	ret

SECTION "Counter", WRAM0
wFrameCounter: db

SECTION "Input Variables", WRAM0
wCurKeys: db
wNewKeys: db

SECTION "Player Variables", WRAM0
wDirectionY: db
wDirectionX: db
wMotionMul: db
