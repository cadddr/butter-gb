DEF UPDATE_EVERY_FRAMES EQU 5
DEF SCREEN_HEIGHT EQU 144 
DEF TILE_HEIGHT EQU 8
DEF TILE_TOP_Y EQU 2 * TILE_HEIGHT - TILE_HEIGHT - TILE_HEIGHT / 2 
DEF TILE_MIDDLE_Y EQU SCREEN_HEIGHT / 2 + 2 * TILE_HEIGHT - TILE_HEIGHT - TILE_HEIGHT / 2 
DEF MAX_OBJECTS EQU 10
DEF MAX_VELOCITY EQU 6
DEF SCROLL_SPEED_BG EQU 1
DEF SCROLL_SPEED_FG EQU 0
DEF FOREGROUND_START_Y EQU 144 - 3 * 8 ;  subtract height of foreground tiles
DEF FOREGROUND_TILEMAP_START EQU 256 - 32 - 4 ; 256 - height of foreground - extra half tile

SECTION "Variable Defines", WRAM0
wFrameCounter: db
wObjectCounter: db

wCurKeys: db
wNewKeys: db

wVel: db
wVelY: db
wVelX: db

wAccel: db
wAngle: db
wAngleNeg: db

mBackgroundScroll:: dw
wBgScrollSlow: db
wBgScrollFast: db
wBgScrollFastX: db

wTemp: dw

SECTION "Variables Init", ROM0
InitVariables:
	ld a, 0
	ld [wFrameCounter], a

	ld a, 1
	ld [wObjectCounter], a

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

	ld a, 0
    ld [mBackgroundScroll+0],a
    ld a, 0
    ld [mBackgroundScroll+1],a

	ld a, 0
    ld [wTemp+0],a
    ld a, 0
    ld [wTemp+1],a

	ld a, 0
    ld [wBgScrollSlow], a

	ld a, FOREGROUND_TILEMAP_START - FOREGROUND_START_Y
    ld [wBgScrollFast], a

	ld a, 0
    ld [wBgScrollFastX], a

	ld hl, _OAMRAM + 4

    ret