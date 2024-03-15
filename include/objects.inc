; @param hl: starting destination address
; @param a: screen Y
; @param b: screen X
; @param c: tile ID
; @param d: attributes
SpawnObject:
	add a, 16 ; Y
	ld [hli], a

	ld a, b
	add a, 8 ; X
	ld [hli], a

	ld a, c ;tile ID
	ld [hli], a

	ld a, d ; attributes
	ld [hli], a
	ret

SpawnObjectWithDefaultAttributes:
	ld d, %00000000
	call SpawnObject
	ret

InitObjects:

	; Draw gondola object
	ld hl, OAM_GONDOLA_RIGHT
	ld a, 88
	ld b, 160
	ld c, TILE_GONDOLA
	call SpawnObjectWithDefaultAttributes

	ld a, 88
	ld b, 160 + 8
	ld c, TILE_GONDOLA + 2
	call SpawnObjectWithDefaultAttributes

	; Draw gondola object 2
	ld hl, OAM_GONDOLA_LEFT
	ld a, 0
	ld b, 0
	ld c, TILE_GONDOLA
	call SpawnObjectWithDefaultAttributes

	ld a, 0
	ld b, 0 + 8
	ld c, TILE_GONDOLA + 2
	call SpawnObjectWithDefaultAttributes

	; Draw trees left
	ld hl, OAM_TREES_LEFT
	ld a, FOREGROUND_START_Y - 8 ;1
	ld b, 0 - 4
	ld c, TILE_TREES
	call SpawnObjectWithDefaultAttributes

	ld a, FOREGROUND_START_Y - 8 ;2
	ld b, 0 + 4
	ld c, TILE_TREES + 2
	call SpawnObjectWithDefaultAttributes

	ld a, FOREGROUND_START_Y - 8 ;3
	ld b, 0 + 12
	ld c, TILE_TREES + 4
	call SpawnObjectWithDefaultAttributes

	; Draw trees right
	ld hl, OAM_TREES_RIGHT
	ld a, FOREGROUND_START_Y - 8 ;1
	ld b, 160 - (8 - 4)
	ld c, TILE_TREES
	ld d, $20
	call SpawnObject

	ld a, FOREGROUND_START_Y - 8 ;2
	ld b, 160 - (8 + 4)
	ld c, TILE_TREES + 2
	ld d, $20
	call SpawnObject

	ld a, FOREGROUND_START_Y - 8 ;3
	ld b, 160 - (8 + 12)
	ld c, TILE_TREES + 4
	ld d, $20
	call SpawnObject

	ret

AdvanceTileToNextFrame:
	inc hl
	inc hl
	ld a, [hl];tile ID
	add a, 6
	cp a, (TILE_TREES + 5) + (6 + 1)
	jp c, .NoResetTile
.ResetTile:
	sub a, 6
	sub a, 6
	
.NoResetTile
	ld [hli], a

	inc hl
	ret 

; @param hl: starting destination address
AnimateTrees: ; +2
	call AdvanceTileToNextFrame
	call AdvanceTileToNextFrame
	call AdvanceTileToNextFrame

	ret

; @param hl: gondola oam
UpdateGondolaPositionDec: 
	; 0
	ld a, [hl]
	dec a
	ld [hli], a

	ld a, [hl]
	dec a
	ld [hli], a

	inc hl
	inc hl

	; 2
	ld a, [hl]
	dec a
	ld [hli], a

	ld a, [hl]
	dec a
	ld [hli], a

	ret

; @param hl: gondola oam
UpdateGondolaPositionInc:
	; 0
	ld a, [hl]
	inc a
	ld [hli], a

	ld a, [hl]
	inc a
	ld [hli], a

	inc hl
	inc hl

	; 2
	ld a, [hl]
	inc a
	ld [hli], a

	ld a, [hl]
	inc a
	ld [hli], a

	ret

LeaveTrailingMark:
	ld a, [wVelY]
	or a, a
	jp nz, .Continue ; only leave traces when moving

	; if stopped make traces in the air disappear
.ClearUpTraces:
	push hl
	ld hl, _OAMRAM + 4
	ld b, (MAX_OBJECTS - 1) * 4
	call ClearOam
	pop hl

	ret 

.Continue:
	call EnforceObjectLimit

	ld a, [_OAMRAM] ; create trail object at current coordinate
	ld [hli], a
	ld a, [_OAMRAM + 1]
	ld [hli], a
	ld a, [_OAMRAM + 2] ; player tile id
	add a, 6 ; offset to trails tiles
	ld [hli], a
	ld a, [_OAMRAM + 3] ; flags e.g., orientation
	or a, $10 ; white palette
	ld [hli], a 
	
	ld a, [rSCY] ; is this correct?
	cp a, 1
	jp nc, .ScrollTrailsUp; not less than 1

	ret

.ScrollTrailsUp: ; if motion is done via scrolling, move all previous trails by velocity amount
	ld a, [wVelY]
	ld d, a

	push hl

	ld hl, _OAMRAM + 4 ; start of trail objects
	ld bc, 4 * (MAX_OBJECTS - 1) ; length
.Loop:
	ld a, [hl]; get Y value
	sub a, d ; move each trail tile up by speed amount
	ld [hl], a

	inc hl
	inc hl
	inc hl
	inc hl

	dec bc
	dec bc
	dec bc
	dec bc

	ld a, b
    or a, c
	jp nz, .Loop

	pop hl

	ret

EnforceObjectLimit:
	ld a, [wObjectCounter]
	cp a, MAX_OBJECTS ; has to be one more than two total objects for carry to occur
	jp c, .NoResetObjects ; not less than
	ld a, 1 ; resetting
	ld hl, _OAMRAM + 4 ; the fact that it resets pointer to first object makes it hard to tell old vs new
.NoResetObjects:
	inc a
	ld [wObjectCounter], a

	ret
