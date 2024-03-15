SECTION "Player", ROM0

InitPlayer:

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
	ld a, FOREGROUND_START_Y
	ld b, 80 - 4
	ld c, $0 
	call SpawnObjectWithDefaultAttributes

	ret

UpdatePlayerVelocity:
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

    ret


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
