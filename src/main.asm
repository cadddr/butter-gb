
INCLUDE "hardware.inc/hardware.inc"
	rev_Check_hardware_inc 4.0

INCLUDE "utils.inc"
INCLUDE "tiles.inc"

DEF UPDATE_EVERY_FRAMES EQU 5
DEF SCREEN_HEIGHT EQU 144 
DEF TILE_HEIGHT EQU 8
DEF TILE_TOP_Y EQU 2 * TILE_HEIGHT - TILE_HEIGHT - TILE_HEIGHT / 2 
DEF TILE_MIDDLE_Y EQU SCREEN_HEIGHT / 2 + 2 * TILE_HEIGHT - TILE_HEIGHT - TILE_HEIGHT / 2 
DEF MAX_OBJECTS EQU 10
DEF MAX_VELOCITY EQU 8
DEF SCROLL_SPEED_BG EQU 0
DEF SCROLL_SPEED_FG EQU 2

SECTION	"HBlank Handler",ROM0[$48]
HBlankHandler::	; 40 cycles
	push	af		; 4
	push	hl		; 4

	call LYC

	pop	hl		; 3
	pop	af		; 3
	reti		; 4


SECTION "Header", ROM0[$100]

	; This is your ROM's entry point
	; You have 4 bytes of code to do... something
	di
	; ei
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
	ld a, 0
	ld b, 80 - 4
	ld c, $0 
	call SpawnObjectWithDefaultAttributes

	; Draw gondola object
	ld hl, _OAMRAM + MAX_OBJECTS * 4
	ld a, 88
	ld b, 160
	ld c, $6
	call SpawnObjectWithDefaultAttributes
	
	ld a, 88 + 8
	ld b, 160
	ld c, $7
	call SpawnObjectWithDefaultAttributes
	
	ld a, 88
	ld b, 160 + 8
	ld c, $8
	call SpawnObjectWithDefaultAttributes

	ld a, 88 + 8
	ld b, 160 + 8
	ld c, $9
	call SpawnObjectWithDefaultAttributes

	; Draw gondola object
	ld hl, _OAMRAM + MAX_OBJECTS * 4 + 16
	ld a, 0
	ld b, 0
	ld c, $6
	call SpawnObjectWithDefaultAttributes
	
	ld a, 0 + 8
	ld b, 0
	ld c, $7
	call SpawnObjectWithDefaultAttributes
	
	ld a, 0
	ld b, 0 + 8
	ld c, $8
	call SpawnObjectWithDefaultAttributes

	ld a, 0 + 8
	ld b, 0 + 8
	ld c, $9
	call SpawnObjectWithDefaultAttributes

	; Turn the LCD on
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON ;| LCDCF_OBJ16
	ld [rLCDC], a

	; During the first (blank) frame, initialize display registers
	ld a, %11100100 ; palette
	ld [rBGP], a
	ld [rOBP0], a
	ld a, %00000000 ; palette
	ld [rOBP1], a


	ld	a,STATF_MODE00
	ldh	[rSTAT],a
	; enable the interrupts
	ld	a,IEF_LCDC
	ldh	[rIE],a
	xor	a
	ei
	ldh	[rIF],a

;;;;;;;; VARIABLES INIT
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

	ld a, 0
    ld [wBgScrollFast], a

	ld hl, _OAMRAM + 4

;;;;;;;; END VARIABLES INIT



macro SkipNonKeyFrames ; macro used to allow jump to Main
	ld a, [wFrameCounter]
	inc a
	ld [wFrameCounter], a
	
	cp a, UPDATE_EVERY_FRAMES; Every 15 frames (a quarter of a second), run the following code
	jp nz, Main

	; Reset the frame counter back to 0
	ld a, 0
	ld [wFrameCounter], a
endm


Main:
	call WaitBeforeVBlank
	call WaitVBlank
	SkipNonKeyFrames ; only update every few frames
	call LeaveTrailingMark


	;;;; handle angle-dependent acceleration and velocity update
	ld a, [wAccel] ; base acceleration factor
	ld c, a
	ld a, [wVel]
	ld b, a
	ld a, [wAngle] ; (sin) can be either 0/2, 1/2, 2/2                       
	call ApplyProportionalToAngle
	ld c, a
	ld a, b
	add a, c

	ld b, MAX_VELOCITY
	call ClipByMaximum

	ld [wVel], a

	;;;;;;;; distribute main speed to Y
	ld a, [wVel] ; main direction velocity
	ld c, a
	ld a, [wAngle] ; (sin) can be either 0/2, 1/2, 2/2
	call ApplyProportionalToAngle
	ld [wVelY], a

	;;;;;;;; distribute main speed to X
	ld a, [wVel]
	ld c, a
	ld a, [wAngle] ; (sin) can be either 0/2, 1/2, 2/2 

	ld d, a
	ld a, 2        
	sub a, d ; (sin) -> (cos) can be either 2/2,  1/2,  0/2

	call ApplyProportionalToAngle
	ld [wVelX], a
	;;;;
	call UpdatePositionY
	call UpdatePositionX
	; call UpdateGondolaPosition
	; call UpdateGondolaPosition2

	call SetParallaxScroll

	; arrow buttons control snowboard angle to the slope which in turn affects acceleration and direction
	call UpdateKeys

CheckLeft:
	ld a, [wCurKeys]
	and a, PADF_LEFT
	jp z, CheckRight
Left:
	ld a, [wAngleNeg] ; first check angle sign
	cp a, 1
	jp c, AngleNotNegative

	ld a, [wAngle]
	add a, 1 ; for negative angles, left key increases them
	jp NoFlipSign

AngleNotNegative:
	ld a, [wAngle]
	sub a, 1 ; for positive angles (including 0), left key reduces them

	jp nc, NoFlipSign ; check if gone below zero
	call FlipAngleSignToNegative

NoFlipSign:
	cp a, 2 + 1
	jp c, NoPivotRight
	call FlipAngleSignToPositive ; 0 is considered positive
	ld a, 1 ; above function only modifies sign but to pivot also need to set angle to 1
NoPivotRight:
	ld [wAngle], a
	ld [_OAMRAM + 2], a ; update tile to match updated angle
	jp Main

CheckRight:
	ld a, [wCurKeys]
	and a, PADF_RIGHT
	jp z, Main
Right:
	ld a, [wAngleNeg] ; I'm once again asking you to check angle sign
	cp a, 1
	jp nc, AngleNegative

	ld a, [wAngle]
	add a, 1 ; for positive angles (including 0), right arrow increases them
	jp NoFlipSignBack

AngleNegative:
	ld a, [wAngle]
	sub a, 1 ; for negative angles, right key increases them

	jp nz, NoFlipSignBack ; check if gone to or below zero
	call FlipAngleSignToPositive
	
NoFlipSignBack:
	cp a, 2 + 1
	jp c, NoPivotLeft
	call FlipAngleSignToNegative ; also sets angle to 1

NoPivotLeft:
	ld [wAngle], a
	ld [_OAMRAM + 2], a ; update tile to match updated angle
	jp Main


; @
FlipAngleSignToPositive:
	ld c, a ; store angle in c temporarily
	ld a, 0 ; flip angle sign back to 0
	ld [wAngleNeg], a
	
	ld a, $00 ; mirror tile along X (reset 5th bit)
	ld [_OAMRAM + 3], a
	ld a, c ; restore angle from c

	ret

; @
FlipAngleSignToNegative:
	ld a, 1 ; flip to 1, possibly also normalize ff into 1 with negative angle
	ld [wAngleNeg], a

	ld c, a ; store angle
	ld a, $20 ; mirror tile along X (set 5th bit)
	ld [_OAMRAM + 3], a
	ld a, c ; restore angle

	ret ; a = wAngle = wAngleNeg = 1 as that's the only possible absolute value when going from pos to neg


; @ return amount scrolled in b
UpdatePositionY:
	ld a, [wVelY] ; current Y velocity (absolute)
	ld b, a

	ld a, [_OAMRAM ] ; current Y coordinate
	cp a, TILE_MIDDLE_Y
	jp nc, .ScrollDown

	ld a, [_OAMRAM ]
	add a, b ; update Y position with velocity value
	ld [_OAMRAM], a ; write back updated Y position

	ret
	
.ScrollDown:
	; call ScrollBackgroundY
	ret


; @param b: how much to scroll by
ScrollBackgroundY:
	ld a, [mBackgroundScroll+0]
    add a, b
    ld b, a
    ld [mBackgroundScroll+0], a
    ld a, [mBackgroundScroll+1]
    adc a, 0
    ld c, a
    ld [mBackgroundScroll+1], a

	;;; TODO: with scaling on, scroll speed is out of sync with velocity
	; Descale our scaled integer 
    ; shift bits to the right 4 spaces
    ; srl c
    ; rr b
    ; srl c
    ; rr b
    ; srl c
    ; rr b
    ; srl c
    ; rr b

    ; Use the de-scaled low byte as the backgrounds position
    ld a, b
    ld [rSCY], a
	
	ret

; @ TODO: should be velocity dependent
SetParallaxScroll:
	;;;;;;;;;;;;;;
	ld a, SCROLL_SPEED_BG
	ld b, a
	ld a, [wBgScrollSlow]
	add a, b
	ld [wBgScrollSlow], a

	ld a, SCROLL_SPEED_FG
	ld b, a
	ld a, [wBgScrollFast]
	add a, b
	ld [wBgScrollFast], a

; @
UpdatePositionX:
	ld a, [wVelX]
	ld b, a

	ld a, [wAngleNeg]
	cp a, 1
	jp nc, .MoveLeft

.MoveRight:
	ld a, [_OAMRAM + 1]
	add a, b ; update X position with velocity value

	ld b, 144
	call ClipByMaximum
	
	ld [_OAMRAM + 1], a ; write back updated X position

	ret 

.MoveLeft:
	ld a, [_OAMRAM + 1]
	sub a, b ; update X position in negative directionwith velocity value

	ld b, 20
	call ClipByMinimum ; TODO this one is buggy

	ld [_OAMRAM + 1], a ; write back updated X position

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


; @param a: value to be clipped
; @param b: max value to clip by
; @returns a: clipped to max value
ClipByMaximum:
	inc b
	cp a, b
	dec b
	jp c, NoClipMax
	ld a, b

NoClipMax:
	ret

; @param a: value to be clipped
; @param b: min value to clip by
; @returns a: clipped to min value
ClipByMinimum:
	cp a, b
	jp nc, NoClipMin
	ld a, b

NoClipMin:
	ret


; @param a: angle as denominator of either 0/2, 1/2, 2/2 
; @param b: current speed if need to set to zero
; @param c: base value to be applied proportionally
; @returns a: either zero or adjusted value of c
; @returns b: either kept or reset to zero
ApplyProportionalToAngle:
	cp a, 0
	jp z, Zero

	cp a, 2
	jp z, SkipDivide
	; divide by 2
	srl c

SkipDivide:
	ld a, c
	ret ; sets a, keeps b
Zero:
	ld b, 0 ; resets b
	ret	; returns a = wAngle = 0

; scroll background before line 64 at slow speed and after at fast speed
LYC::
    push af
    ldh a, [rLY]
    cp 64 - 1
    jr nc, .scrollForeground

	ld a, 0
	ld [rSCX], a

	ld a, [wBgScrollSlow]
	ld [rSCY], a

    pop af
    reti

.scrollForeground

	add a, 128 / 2
	ld [rSCX], a

	ld a, [wBgScrollFast]
	ld [rSCY], a
	
    pop af
    reti


SECTION "Counter", WRAM0
wFrameCounter: db ; if changed to ds 0 appears to give scaled refresh
wObjectCounter: db

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

mBackgroundScroll:: dw
wTemp: dw

wBgScrollSlow: db
wBgScrollFast: db
