
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

	call LoadLevelTiles
	call InitPlayer
	call InitObjects

	; Turn the LCD on
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16
	ld [rLCDC], a

	call InitPalettes
	call InitInterrupts


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

	push hl
	ld hl, OAM_GONDOLA_RIGHT
	call UpdateGondolaPositionDec
	ld hl, OAM_GONDOLA_LEFT
	call UpdateGondolaPositionInc
	pop hl

	call SetParallaxScroll

	; arrow buttons control snowboard angle to the slope which in turn affects acceleration and direction
	HandleInput ; macro jumps back to main


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

; controls apparent motion vs background scrolling
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
	ld a, [wBgScrollSlow]
	cp a, MAP_END_Y ; end of mountain tiles
	jp nc, .ZeroVelY

	push hl
	ld hl, mBackgroundScroll ; virtual scrolling amount (scaled)
	call AddToScaledValueAndDescaleResult
	pop hl
	ld [wBgScrollSlow], a ; actual value used to set scroll register
	ret
	
.ZeroVelY:
	ld a, 0
	ld [wVelY], a
	ld [_OAMRAM + 2], a ; also reset player anim
	ret

; @ 
SetParallaxScroll: ; this is for the scrolling foreground
	ld a, [wVelY]
	cp a, 0
	jp z, .Exit

	ld b, a ; copy velocity
	ld a, [wBgScrollFast]
	add a, b

	ld [wBgScrollFast], a

	;;; used to set side scrolling for slope curving
	ld a, [wVelX]
	ld b, a
	ld a, [wBgScrollFastX]
	add a, b
	ld [wBgScrollFastX], a

	ld hl, OAM_TREES_LEFT
	call AnimateTrees
	ld hl, OAM_TREES_RIGHT
	call AnimateTrees

.Exit:
	ret

; scroll background before FOREGROUND_START_Y line at slow speed and after it at fast speed
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

	; ld a, [wAngle]
	; cp a, 1
	; jp c, .NoCurve

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
	cp a, FOREGROUND_TILEMAP_START - FOREGROUND_START_Y + TILE_HEIGHT
	jp c, .NoReset

	sub a, TILE_HEIGHT ; this allows wrapping scrolled foreground rows
	ld [wBgScrollFast], a

.NoReset:

	ld [rSCY], a
	
    pop af
    reti
