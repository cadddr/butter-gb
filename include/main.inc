INCLUDE "hardware.inc/hardware.inc"
	rev_Check_hardware_inc 4.0

INCLUDE "utils.inc"
INCLUDE "tiles.inc"

SECTION "Entry point", ROM0

EntryPoint:
	; Shut down audio circuitry
	ld a, 0
	ld [rNR52], a

	; Do not turn the LCD off outside of VBlank
	call WaitVBlank

	; Turn the LCD off
	ld a, 0
	ld [rLCDC], a

	;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

	; Copy player object tile
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

	;;;;;;;;;;;;;;;;;;;;

	; Turn the LCD on
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16
	ld [rLCDC], a

	; During the first (blank) frame, initialize display registers
	ld a, %11100100
	ld [rBGP], a
	ld [rOBP0], a
	ld [rOBP1], a


; SECTION "Player Variables", WRAM0
; wDirectionY: db
; wDirectionX: db
	
SECTION "Main", ROM0
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; ld a, 1
	; ld [wDirectionY], a ; direction
	; ld a, 1
	; ld [wDirectionX], a ; direction
Main:
	; Wait until it's *not* VBlank
	ld a, [rLY]
	cp 144
	jp nc, Main

	call WaitVBlank

	; ld a, [wDirectionY]
	; ld b, a
	; ld a, [_OAMRAM ]
	; ld c, 0 + 16 - 8 + 4
	; ld d, 144 + 16 - 8 - 4
	; call CheckBoundsAndUpdateDirection
	; add a, b
	; ld [_OAMRAM], a
	; ld a, b
	; ld [wDirectionY], a

	; ; call UpdateKeys

	; ld a, [wDirectionX]
	; ld b, a
	; ld a, [_OAMRAM + 1]
	; ld c, 0 + 8
	; ld d, 160 + 8 - 8
	; call CheckBoundsAndUpdateDirection

	; add a, b
	; add a, b ; X speed is twice that of Y
	; ld [_OAMRAM + 1], a
	; ld a, b
	; ld [wDirectionX], a

	; jp Main
	; Check the current keys every frame and move left or right.
	; call UpdateKeys

	; First, check if the left button is pressed.
CheckLeft:
	ld a, [wCurKeys]
	and a, PADF_LEFT
	jp z, CheckRight
Left:
	; Move the paddle one pixel to the left.
	ld a, [_OAMRAM + 1]
	dec a
	; If we've already hit the edge of the playfield, don't move.
	cp a, 15
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
	; If we've already hit the edge of the playfield, don't move.
	cp a, 105
	jp z, Main
	ld [_OAMRAM + 1], a
	jp Main

; @param a: coordinate
; @param b: current direction/speed
; @param c: lower limit
; @param d: higher limit 
; CheckBoundsAndUpdateDirection:
; 	cp a, c
; 	jp z, ChangeDirectionPos

; 	cp a, d
; 	jp z, ChangeDirectionNeg

; 	ret

; ChangeDirectionNeg:
; 	ld b, -1; Down
	
; 	ret

; ChangeDirectionPos:
; 	ld b, 1; Down

; 	ret

SECTION "Input Variables", WRAM0
wCurKeys: db
wNewKeys: db