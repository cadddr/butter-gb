INCLUDE "hardware.inc/hardware.inc"
	rev_Check_hardware_inc 4.0

SECTION "Utils", ROM0

WaitVBlank:
	ld a, [rLY]
	cp 144
	jp c, WaitVBlank

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
