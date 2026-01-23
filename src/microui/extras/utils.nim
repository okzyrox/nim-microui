## microui - Extra utility functions
## License: MIT

import ../ui

import std/[strutils]

## Util functions

proc color*(hex: string): MUColor =
  var r, g, b, a: byte = 0

  case hex.len
  of 6: # RRGGBB
    r = parseHexInt(hex[0..1]).byte
    g = parseHexInt(hex[2..3]).byte
    b = parseHexInt(hex[4..5]).byte
    a = 255
  of 7: # #RRGGBB
    r = parseHexInt(hex[1..2]).byte
    g = parseHexInt(hex[3..4]).byte
    b = parseHexInt(hex[5..6]).byte
    a = 255
  of 8: # RRGGBBAA
    r = parseHexInt(hex[0..1]).byte
    g = parseHexInt(hex[2..3]).byte
    b = parseHexInt(hex[4..5]).byte
    a = parseHexInt(hex[6..7]).byte
  of 9: # #RRGGBBAA
    r = parseHexInt(hex[1..2]).byte
    g = parseHexInt(hex[3..4]).byte
    b = parseHexInt(hex[5..6]).byte
    a = parseHexInt(hex[7..8]).byte
  else:
    discard
  
  return color(r, g, b, a)

proc color*(hexValue: int64): MUColor =
  result = MUColor(
    r: byte(hexValue shr 24 and 0xff),
    g: byte(hexValue shr 16 and 0xff),
    b: byte(hexValue shr 8 and 0xff),
    a: byte(hexValue and 0xff)
  )

## Util Constants

const
  COLOR_TRANSPARENT* = color("#00000000")
  COLOR_WHITE* = color("#FFFFFF")
  COLOR_BLACK* = color("#000000")
  COLOR_RED*   = color("#df2a2a")
  COLOR_GREEN* = color("#3bc43b")
  COLOR_BLUE*  = color("#2222d6")
  COLOR_YELLOW* = color("#e4e421")
  COLOR_CYAN*  = color("#3ef3f3")
  COLOR_MAGENTA* = color("#ed35ed")
  COLOR_LIGHT_GRAY* = color("#c0bbbb")
  COLOR_DARK_GRAY* = color("#848383")
  COLOR_ORANGE* = color("#eca012")
  COLOR_PURPLE* = color("#740d74")
  COLOR_BROWN* = color("#6a2a2a")
  COLOR_PINK* = color("#fd9fae")