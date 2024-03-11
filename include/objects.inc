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
	ld hl, _OAMRAM + MAX_OBJECTS * 4
	ld a, 88
	ld b, 160
	ld c, $6
	call SpawnObjectWithDefaultAttributes

	; ld a, 88 + 8
	; ld b, 160
	; ld c, $7
	; call SpawnObjectWithDefaultAttributes

	ld a, 88
	ld b, 160 + 8
	ld c, $8
	call SpawnObjectWithDefaultAttributes

	; ld a, 88 + 8
	; ld b, 160 + 8
	; ld c, $9
	; call SpawnObjectWithDefaultAttributes

	; Draw gondola object
	ld hl, _OAMRAM + MAX_OBJECTS * 4 + 8
	ld a, 0
	ld b, 0
	ld c, $6
	call SpawnObjectWithDefaultAttributes

	; ld a, 0 + 8
	; ld b, 0
	; ld c, $7
	; call SpawnObjectWithDefaultAttributes

	ld a, 0
	ld b, 0 + 8
	ld c, $8
	call SpawnObjectWithDefaultAttributes

	; ld a, 0 + 8
	; ld b, 0 + 8
	; ld c, $9
	; call SpawnObjectWithDefaultAttributes

	; Draw trees left
	ld a, FOREGROUND_START_Y - 8 ;1
	ld b, 0 - 4
	ld c, $A
	call SpawnObjectWithDefaultAttributes

	; ld a, FOREGROUND_START_Y
	; ld b, 0 - 4
	; ld c, $B
	; call SpawnObjectWithDefaultAttributes

	ld a, FOREGROUND_START_Y - 8 ;2
	ld b, 0 + 4
	ld c, $C
	call SpawnObjectWithDefaultAttributes

	; ld a, FOREGROUND_START_Y
	; ld b, 0 + 4
	; ld c, $D
	; call SpawnObjectWithDefaultAttributes

	ld a, FOREGROUND_START_Y - 8 ;3
	ld b, 0 + 12
	ld c, $E
	call SpawnObjectWithDefaultAttributes

	; ld a, FOREGROUND_START_Y
	; ld b, 0 + 12
	; ld c, $F
	; call SpawnObjectWithDefaultAttributes

	; Draw trees right
	ld a, FOREGROUND_START_Y - 8 ;1
	ld b, 160 - (8 - 4)
	ld c, $A
	ld d, $20
	call SpawnObject

	; ld a, FOREGROUND_START_Y
	; ld b, 160 - (8- 4)
	; ld c, $B
	; ld d, $20
	; call SpawnObject

	ld a, FOREGROUND_START_Y - 8 ;2
	ld b, 160 - (8 + 4)
	ld c, $C
	ld d, $20
	call SpawnObject

	; ld a, FOREGROUND_START_Y
	; ld b, 160 - (8 + 4)
	; ld c, $D
	; ld d, $20
	; call SpawnObject

	ld a, FOREGROUND_START_Y - 8 ;3
	ld b, 160 - (8 + 12)
	ld c, $E
	ld d, $20
	call SpawnObject

	; ld a, FOREGROUND_START_Y
	; ld b, 160 - (8 + 12)
	; ld c, $F
	; ld d, $20
	; call SpawnObject

	ret

AdvanceTileToNextFrame:
	inc hl
	inc hl
	ld a, [hl];tile ID
	add a, 6
	cp a, $F + 7
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
	; call AdvanceTileToNextFrame
	; call AdvanceTileToNextFrame
	; call AdvanceTileToNextFrame

	ret

UpdateGondolaPosition:
	ld a, h ; store hl in memory
	ld [wTemp], a
	ld a, l
	ld [wTemp + 1], a

	ld hl, _OAMRAM + MAX_OBJECTS * 4

	; 0
	ld a, [hl]
	dec a
	ld [hli], a

	ld a, [hl]
	dec a
	ld [hli], a

	inc hl
	inc hl

	; 1
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

	inc hl
	inc hl

	; 3
	ld a, [hl]
	dec a
	ld [hli], a

	ld a, [hl]
	dec a
	ld [hl], a


	ld a, [wTemp] ; restore hl from memory
	ld h, a
	ld a, [wTemp + 1]
	ld l, a

	ret

UpdateGondolaPosition2:
	ld a, h ; store hl in memory
	ld [wTemp], a
	ld a, l
	ld [wTemp + 1], a

	ld hl, _OAMRAM + MAX_OBJECTS * 4 + 16

	; 0
	ld a, [hl]
	inc a
	ld [hli], a

	ld a, [hl]
	inc a
	ld [hli], a

	inc hl
	inc hl

	; 1
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

	inc hl
	inc hl

	; 3
	ld a, [hl]
	inc a
	ld [hli], a

	ld a, [hl]
	inc a
	ld [hl], a


	ld a, [wTemp] ; restore hl from memory
	ld h, a
	ld a, [wTemp + 1]
	ld l, a

	ret

LeaveTrailingMark:
	ld a, [wVelY]
	or a, a
	jp nz, .Continue ; only leave traces when moving
	ret 

.Continue:
	call EnforceObjectLimit

	ld a, [_OAMRAM] ; create trail object at current coordinate
	ld [hli], a
	ld a, [_OAMRAM + 1]
	ld [hli], a
	ld a, [_OAMRAM + 2]
	add a, 3 ; offset to trails tiles
	ld [hli], a
	ld a, [_OAMRAM + 3]
	or a, $10 ; white palette
	ld [hli], a 
	
	ld a, [rSCY]
	cp a, 1
	jp nc, .ScrollTrailsUp; not less than 1

	ret

.ScrollTrailsUp: ; if motion is done via scrolling, move all previous trails by velocity amount
	ld a, [wVelY]
	ld d, a

	ld a, h ; store hl in memory
	ld [wTemp], a
	ld a, l
	ld [wTemp + 1], a

	ld hl, _OAMRAM + 4
	ld bc, 4 * (MAX_OBJECTS - 1) ; length
.Loop:
	ld a, [hl]; get Y value
	sub a, d
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

	ld a, [wTemp] ; restore hl from memory
	ld h, a
	ld a, [wTemp + 1]
	ld l, a

	ret

EnforceObjectLimit:
	ld a, [wObjectCounter]
	cp a, MAX_OBJECTS ; has to be one more than two total objects for carry to occur
	jp c, .NoResetObjects ; not less than
	ld a, 1
	ld hl, _OAMRAM + 4 ; the fact that it resets pointer to first object makes it hard to tell old vs new
.NoResetObjects:
	inc a
	ld [wObjectCounter], a

	ret
