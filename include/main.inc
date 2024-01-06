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

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld b, -1 ; direction
	ld c, 2 ; direction
Main:
	ld a, [rLY]
	cp 144
	jp nc, Main

	call WaitVBlank

	ld a, [_OAMRAM ]
	cp a, 0 + 16 - 8 + 4
	jp z, ChangeDirectionPos
	cp a, 144 + 16 - 8 - 4
	jp z, ChangeDirectionNeg
	jp SkipChangeDirection

ChangeDirectionNeg:
	ld b, -1; Down
	jp SkipChangeDirection
ChangeDirectionPos:
	ld b, 1; Down
SkipChangeDirection:
	add a, b
	ld [_OAMRAM], a

	ld a, [_OAMRAM + 1]
	cp a, 0 + 8
	jp z, ChangeDirectionPosX
	cp a, 160 + 8 - 8
	jp z, ChangeDirectionNegX
	jp SkipChangeDirectionX

ChangeDirectionNegX:
	ld c, -2; Down
	jp SkipChangeDirectionX
ChangeDirectionPosX:
	ld c, 2; Down
SkipChangeDirectionX:

	add a, c
	ld [_OAMRAM + 1], a

	jp Main
