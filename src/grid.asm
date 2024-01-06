;INCLUDE "hardware.inc"
INCLUDE "hardware.inc/hardware.inc"
	rev_Check_hardware_inc 4.0
SECTION "Header", ROM0[$100]

	jp EntryPoint

	ds $150 - @, 0 ; Make room for the header

EntryPoint:
	; Shut down audio circuitry
	ld a, 0
	ld [rNR52], a

	; Do not turn the LCD off outside of VBlank
WaitVBlank:
	ld a, [rLY]
	cp 144
	jp c, WaitVBlank

	; Turn the LCD off
	ld a, 0
	ld [rLCDC], a

	; Copy the tile data
	ld de, Tiles
	ld hl, $9000
	ld bc, TilesEnd - Tiles
CopyTiles:
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or a, c
	jp nz, CopyTiles

	; Copy the tilemap
	ld de, Tilemap
	ld hl, $9800
	ld bc, TilemapEnd - Tilemap
CopyTilemap:
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or a, c
	jp nz, CopyTilemap

	; Copy player object tile
	ld de, Player
	ld hl, $8000
	ld bc, PlayerEnd - Player
CopyPlayer:
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or a, c
	jp nz, CopyPlayer

	; Initialize object memory
	ld a, 0
	ld b, 160
	ld hl, _OAMRAM
ClearOam:
	ld [hli], a
	dec b
	jp nz, ClearOam

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

	ld a, %11100100
	ld [rOBP0], a
	
	ld a, %11100100
	ld [rOBP1], a

;ld a, 0
;ld [wStepsTaken], a

ld b, -1 ; direction
ld c, 2 ; direction
Main:
	ld a, [rLY]
	cp 144
	jp nc, Main
WaitVBlank2:
	ld a, [rLY]
	cp 144
	jp c, WaitVBlank2

	;ld a, [wStepsTaken]
	;inc a
	;ld [wStepsTaken], a
	;cp a, 3 + 1

	;jp nz, Main

	;ld a, 0
	;ld [wStepsTaken], a
	jp Main
	; Move player object
	ld a, [_OAMRAM ]
	cp a, 64 + 16 - 8
	jp z, ChangeDirectionPos
	cp a, 64 + 16 + 8
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
	cp a, 12 + 8 - 8
	jp z, ChangeDirectionPosX
	cp a, 12 + 8 + 24
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


SECTION "Tile data", ROM0

Player:
	dw `00000000, `00000300, `00011000, `00112200, `00111100, `00011000, `02111100, `21133110
	dw `21133310, `21333331, `01333330, `03330333, `03300033, `03330033, `20333332, `02222220
PlayerEnd:

Tiles:
	;db $00,$00, $00,$00, $00,$00, $00,$00, $00,$00, $00,$00, $00,$00, $00,$00
	dw `00000000, `00000000, `00000000, `00000000, `00000000, `00000000, `00000000, `00000000
	
	dw `00000011, `00001100, `00110000, `11000011, `11000000, `00110000, `00001100, `00000011 ; 1 <
	dw `11000000, `00110000, `00001100, `00000011, `11000011, `00001100, `00110000, `11000000 ; 2 >
	dw `00000000, `00000000, `00000000, `00000000, `00000011, `00001100, `00110000, `11000000 ; 3 sp/
	dw `11000000, `00110000, `00001100, `00000011, `00000000, `00000000, `00000000, `00000000 ; 4 \sp
	dw `00000000, `00000000, `00000000, `00000000, `11000000, `00110000, `00001100, `00000011 ; 5 sp\
	dw `00000011, `00001100, `00110000, `11000000, `00000000, `00000000, `00000000, `00000000 ; 6 /sp
	
	dw `22200222, `22022022, `20222202, `02222220, `02222220, `20222202, `22022022, `22200222 ; 7 old square tiles
	dw `22211222, `21122112, `12222221, `21122112, `22211222, `21122112, `12222221, `21122112 ; 8 old low res isometric tiles


	dw `22222222, `22222322, `22211222, `22110022, `22111122, `22211222, `20111122, `01133112
	dw `01133312, `01333331, `21333332, `23332333, `23322233, `23332233, `02333330, `20000002 
TilesEnd:




SECTION "Tilemap", ROM0

Tilemap:
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $03, $05, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0	 ; /\
	db $00, $00, $00, $00, $00, $00, $00, $03, $06, $00, $00, $04, $05, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0	; /\/\
	db $00, $00, $00, $00, $00, $03, $06, $03, $05, $00, $00, $03, $05, $04, $05, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0	;/\/\
	db $00, $00, $00, $03, $06, $00, $06, $00, $00, $00, $06, $00, $00, $04, $05, $04, $05, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $03, $06, $03, $05, $00, $00, $00, $03, $05, $00, $00, $00, $00, $00, $00, $00, $04, $05, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $06, $00, $00, $00, $00, $00, $00, $06, $00, $00, $04, $00, $00, $00, $00, $00, $00, $00, $00, $04,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $03, $05, $00, $00, $00, $00, $03, $05, $00, $00, $00, $00, $03, $05, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $03, $05, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0	
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $03, $05, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0	
	db $00, $00, $00, $00, $00, $03, $05, $00, $00, $00, $00, $00, $00, $00, $00, $00, $03, $05, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0	
	db $00, $00, $00, $00, $00, $00, $00, $04, $05, $00, $03, $05, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $03, $05, $00, $00, $00, $00, $00, $01, $00, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $04, $05, $03, $06, $04, $00, $00, $00, $03, $05, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $03, $01, $02, $01, $02, $05, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $01, $04, $01, $02, $01, $02, $06, $02, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $04, $06, $00, $00, $00, $00, $00, $00, $00, $00, $00,  0,0,0,0,0,0,0,0,0,0,0,0
	
TilemapEnd:
