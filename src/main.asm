
INCLUDE "hardware.inc/hardware.inc"
	rev_Check_hardware_inc 4.0

INCLUDE "utils.inc"
INCLUDE "tiles.inc"
INCLUDE "constants.inc"
INCLUDE "level.inc"
INCLUDE "player.inc"
INCLUDE "objects.inc"
INCLUDE "input.inc"

SECTION	"HBlank Handler",ROM0[$48]
HBlankHandler::	; 40 cycles
	push	af		; 4
	push	hl		; 4

	; call LYC

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

	call LoadLevelTiles
	call InitPlayer
	call InitObjects

	; Turn the LCD on
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON ;| LCDCF_OBJ16
	ld [rLCDC], a

	call InitPalettes

	ld	a,STATF_MODE00
	ldh	[rSTAT],a
	; enable the interrupts
	ld	a,IEF_LCDC
	ldh	[rIE],a
	xor	a
	ei
	ldh	[rIF],a

	call InitVariables

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

	call UpdatePlayerVelocity

	;;;;
	call UpdatePositionY
	call UpdatePositionX
	; call UpdateGondolaPosition
	; call UpdateGondolaPosition2

	call SetParallaxScroll

	; arrow buttons control snowboard angle to the slope which in turn affects acceleration and direction
	HandleInput ; macro jumps back to main

; @ return amount scrolled in b
UpdatePositionY:
	ld a, [wVelY] ; current Y velocity (absolute)
	ld b, a

	ld a, [_OAMRAM ] ; current Y coordinate
	cp a, FOREGROUND_START_Y
	jp nc, .ScrollDown

	ld a, [_OAMRAM ]
	add a, b ; update Y position with velocity value
	ld [_OAMRAM], a ; write back updated Y position

	ret
	
.ScrollDown:
	; call ScrollBackgroundY
	push hl
	ld hl, mBackgroundScroll
	call AddToScaledValueAndDescaleResult
	ld [rSCY], a
	pop hl
	ret

; ; @param b: how much to scroll by
; ScrollBackgroundY:
; 	ld a, [mBackgroundScroll+0]
;     add a, b
;     ld b, a
;     ld [mBackgroundScroll+0], a
;     ld a, [mBackgroundScroll+1]
;     adc a, 0
;     ld c, a
;     ld [mBackgroundScroll+1], a

; 	;;; TODO: with scaling on, scroll speed is out of sync with velocity
; 	; Descale our scaled integer 
;     ; shift bits to the right 4 spaces
;     srl c
;     rr b
;     srl c
;     rr b
;     srl c
;     rr b
;     srl c
;     rr b

;     ; Use the de-scaled low byte as the backgrounds position
;     ld a, b
;     ld [rSCY], a
	
; 	ret

; @ TODO: should be velocity dependent
SetParallaxScroll:
	;;;;;;;;;;;;;;
	ld a, SCROLL_SPEED_BG
	ld b, a
	ld a, [wBgScrollSlow]
	add a, b
	ld [wBgScrollSlow], a

	ld a, [wVelY]
	; ld a, SCROLL_SPEED_FG
	ld b, a
	ld a, [wBgScrollFast]
	add a, b

	;;; reset scroll after 1 tile
	cp a, FOREGROUND_TILEMAP_START - FOREGROUND_START_Y + 11 + 1
	jp c, .noResetScrollPosition
	ld a, FOREGROUND_TILEMAP_START - FOREGROUND_START_Y - 4
.noResetScrollPosition:
	;;;

	ld [wBgScrollFast], a

	ld a, [wVelX]
	ld b, a
	ld a, [wBgScrollFastX]
	add a, b
	ld [wBgScrollFastX], a

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

; scroll background before line 64 at slow speed and after at fast speed
LYC::
    push af
    ldh a, [rLY]
    cp FOREGROUND_START_Y - 1
    jr nc, .scrollForeground

	ld a, 0
	ld [rSCX], a

	ld a, [wBgScrollSlow]
	ld [rSCY], a

    pop af
    reti

.scrollForeground
	ld b, a ; store rLY

	ld a, [wAngle]
	cp a, 1
	jp c, .NoCurve

	; ld a, [wAngleNeg]
	; cp a, 1
	; jp nc, .CurveLeft

; .CurveRight:
; 	ld a, 128 + FOREGROUND_START_Y ; offset to center
; 	sub a, b
; 	ld [rSCX], a
; 	jp .DoneCurve

; .CurveLeft:
; 	; ld a, [wBgScrollFastX]
; 	ld a, 128 - FOREGROUND_START_Y ; offset to center
; 	add a, b
; 	ld [rSCX], a
; 	jp .DoneCurve

.NoCurve:
	ld a, 128; offset to center
	ld [rSCX], a

.DoneCurve:
	ld a, [wBgScrollFast] ;104;

	ld [rSCY], a
	
    pop af
    reti

