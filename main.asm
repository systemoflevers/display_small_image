

SECTION "Header", ROM0[$100]

EntryPoint:
        di ; Disable interrupts.
        jp Start

REPT $150 - $104
    db 0
ENDR

SECTION "Game code", ROM0

Start:
.waitVBlank
  ld a, [$FF40]
  cp 144 ; Check if the LCD is past VBlank
  jr c, .waitVBlank
  xor a ; equivalent to ld a, 0
  ld [$FF40], a ; We will have to write to LCDC again later, so it's not a bother, really.

  ;; copy tile map
  ld hl, $9800 ; tile map 0
  ld bc, TileMap.start
  ;; column counter
  ld d, 20
  ;; row counter
  ld e, 18

.tilemapcopyloop
  ld a, [bc]
  ld [hli], a
  inc bc
  dec d
  jr nz, .tilemapcopyloop
  ;; d is 0 so we're done copying a row

  ;; reset the column counter
  ld d, 20

  ;; move hl to the first column of the next row
  ld a, 12
  add l
  ld l, a
  ld a, 0 ; use ld to preserve the carry flag
  adc a, h
  ld h, a

  ;; decrease the row counter
  dec e
  jr nz, .tilemapcopyloop
  ;; row conter is 0 so we're done copying the tile map

  ;; copy the tile data

  ;; setup tile count registers
  ld a, [TileByteCount]
  ld e, a
  ld a, [TileByteCount + 1]
  ld d, a

  ld hl, $8000
  ld bc, TileData.start

.tiledatacopyloop
  ld a, [bc]
  ld [hli], a
  inc bc

  dec de
  xor a
  cp a, e
  jr nz, .tiledatacopyloop
  cp a, d
  jr nz, .tiledatacopyloop

  ;; set bg palette
  ld a, %11100100
  ld [$FF47], a
  ;; turn screen back on
  ld a, %10010001
  ld [$FF40], a
  halt

SECTION "constants", ROM0
TileByteCount:
  DW 360 * 16

SECTION "data", ROM0
TileMap:
.start
  ;; Fill blank tile map data.
  ;; Only setting data for 20x18 tiles.
  DS 20 * 18, $00
.end

TileData:
.start
  ;; Fill blank tile data.
  ;; Filling enough space for 360 tiles, which is enough for 1 20x18 screen.
  ds 360 * 16, $FF
.end