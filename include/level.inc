SECTION "Level", ROM0

LoadLevelTiles:

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

ret