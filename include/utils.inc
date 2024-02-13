INCLUDE "hardware.inc/hardware.inc"
	rev_Check_hardware_inc 4.0

SECTION "Utils", ROM0

WaitVBlank:
	ld a, [rLY]
	cp 144
	jp c, WaitVBlank ; while rLY < 144

  ret

; why need two of them?

WaitBeforeVBlank:
	ld a, [rLY]
	cp 144
	jp nc, WaitBeforeVBlank ; while rLY >= 144

  ret

; Copy bytes from one area to another.
; @param de: Source
; @param hl: Destination
; @param bc: Length
Memcopy:
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or a, c
    jp nz, Memcopy

    ret

ClearOam:
	ld [hli], a
	dec b
	jp nz, ClearOam

  ret

InitPalettes:
  ; During the first (blank) frame, initialize display registers
	ld a, %11100100 ; palette
	ld [rBGP], a
	ld [rOBP0], a
	ld a, %00000000 ; palette
	ld [rOBP1], a
  ret

UpdateKeys:
    ; Poll half the controller
    ld a, P1F_GET_BTN
    call .onenibble
    ld b, a ; B7-4 = 1; B3-0 = unpressed buttons
  
    ; Poll the other half
    ld a, P1F_GET_DPAD
    call .onenibble
    swap a ; A3-0 = unpressed directions; A7-4 = 1
    xor a, b ; A = pressed buttons + directions
    ld b, a ; B = pressed buttons + directions
  
    ; And release the controller
    ld a, P1F_GET_NONE
    ldh [rP1], a
  
    ; Combine with previous wCurKeys to make wNewKeys
    ld a, [wCurKeys]
    xor a, b ; A = keys that changed state
    and a, b ; A = keys that changed to pressed
    ld [wNewKeys], a
    ld a, b
    ld [wCurKeys], a
    ret
  
  .onenibble
    ldh [rP1], a ; switch the key matrix
    call .knownret ; burn 10 cycles calling a known ret
    ldh a, [rP1] ; ignore value while waiting for the key matrix to settle
    ldh a, [rP1]
    ldh a, [rP1] ; this read counts
    or a, $F0 ; A7-4 = 1; A3-0 = unpressed keys
  .knownret
    ret

; @param b: how much to scroll by
; @param hl: address of first byte
; @returns a: de-scaled low byte of resulting value
AddToScaledValueAndDescaleResult:
  ; Increase our scaled integer by 5
  ; Get our true (non-scaled) value, and save it for later usage in bc
	ld a, [hl] ; [mBackgroundScroll+0] - low?
  add a, b
  ld b, a
  ld [hli], a ; [mBackgroundScroll+0]
  ld a, [hl]; [mBackgroundScroll+1] - high?
  adc a, 0 ; add carry flag
  ld c, a
  ld [hl], a ; [mBackgroundScroll+1]

	; Descale our scaled integer 
  ; shift bits to the right 4 spaces
  srl c   ; Arithmetic shift right 1 bit, bit 0 goes to carry flag, 0 is put into bit 7.
  rr b ; 9-bit rotation to the right. The carry is copied into bit 7, and the bit leaving on the right is copied into the carry.

  srl c
  rr b

  srl c
  rr b

  srl c
  rr b

  ; Use the de-scaled low byte as the backgrounds position
  ld a, b
	
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
    
  
