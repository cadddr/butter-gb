macro HandleInput
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

endm
    