DEF UPDATE_EVERY_FRAMES EQU 5
DEF SCREEN_HEIGHT EQU 144
DEF TILEMAP_HEIGHT EQU 256 
DEF TILE_HEIGHT EQU 8
DEF TILE_TOP_Y EQU 2 * TILE_HEIGHT - TILE_HEIGHT - TILE_HEIGHT / 2 
DEF TILE_MIDDLE_Y EQU SCREEN_HEIGHT / 2 + 2 * TILE_HEIGHT - TILE_HEIGHT - TILE_HEIGHT / 2 
DEF MAX_OBJECTS EQU 10
DEF MAX_VELOCITY EQU 6
DEF SCROLL_SPEED_BG EQU 1
DEF SCROLL_SPEED_FG EQU 0
DEF FOREGROUND_ROWS EQU 5 ;+ 5
DEF FOREGROUND_START_Y EQU SCREEN_HEIGHT - (FOREGROUND_ROWS - 1) * TILE_HEIGHT;  subtract height of foreground tiles
DEF FOREGROUND_TILEMAP_START EQU TILEMAP_HEIGHT - (FOREGROUND_ROWS) * TILE_HEIGHT; 256 - height of foreground - extra half tile
DEF MAP_END_Y EQU 104

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

	; how much to scroll by initially so that foreground tiles are rendered right after background stops
	ld a, FOREGROUND_TILEMAP_START - FOREGROUND_START_Y 
    ld [wBgScrollFast], a

	ld a, 0
    ld [wBgScrollFastX], a

	ld hl, _OAMRAM + 4

    ret