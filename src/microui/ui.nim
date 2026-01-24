## nim-microui - UI
## License: MIT

import std/[
  bitops,
  math,
  strformat,
  sequtils
]

const
  MICROUI_VERSION* = "2.02"

  MICROUI_COMMANDLIST_SIZE* = (256 * 1024)
  MICROUI_ROOTLIST_SIZE* = 32
  MICROUI_CONTAINERSTACK_SIZE* = 32
  MICROUI_CLIPSTACK_SIZE* = 32
  MICROUI_IDSTACK_SIZE* = 32
  MICROUI_LAYOUTSTACK_SIZE* = 16
  MICROUI_CONTAINERPOOL_SIZE* = 48
  MICROUI_TREENODEPOOL_SIZE* = 48
  MICROUI_MAX_WIDTHS* = 16
  MICROUI_MAX_FMT* = 127

##/ Enums
type MUClip* = enum
  None = 0
  Partial = 1
  All = 2

type MUCommandType* = enum 
  Jump = 0
  Clip = 1
  Rect = 2
  Text = 3
  Icon = 4
  ## Extras:
  Image = 5
  ## End
  Max = 6

type MULayoutType* = enum
  Relative
  Absolute

type MUElementColor* = enum
  ColorText
  ColorBorder
  ColorWindowBackground
  ColorTitleBackground
  ColorTitleText
  ColorPanelBackground
  ColorButton
  ColorButtonHover
  ColorButtonFocus
  ColorBase
  ColorBaseHover
  ColorBaseFocus
  ColorScrollBase
  ColorScrollThumb
  ## Extras:
  ColorMenuBar
  ColorSeparator
  ColorTextLink
  ## End
  ColorMax

type MUMouseState* = enum ## for renderers/windows to update
  Default = 0
  Select = 1
  DragHorizontal = 2
  DragVertical = 3
  TextSelect = 4

type MUIcon* = enum
  Close = 1
  Check = 2
  Collapsed = 3
  Expanded = 4
  Max = 5

type MUResult* = enum
  Active = 1 shl 0
  Submit = 1 shl 1
  Change = 1 shl 2

type MUWindowOption* = enum
  AlignCenter = 1 shl 0
  AlignRight = 1 shl 1
  NoInteract = 1 shl 2
  NoFrame = 1 shl 3
  NoResive = 1 shl 4
  NoScroll = 1 shl 5
  NoClose = 1 shl 6
  NoTitle = 1 shl 7
  HoldFocus = 1 shl 8
  AutoSize = 1 shl 9
  Popup = 1 shl 10
  Closed = 1 shl 11
  Expanded = 1 shl 12

type MUMouse* = enum
  Left = 1
  Right = 2
  Middle = 3

type MUControlKey* = enum
  Shift = 1 shl 0
  Ctrl = 1 shl 1
  Alt = 1 shl 2
  Backspace = 1 shl 3
  Return = 1 shl 4

##/ Structs

type MUFont* = object
  data*: pointer

type MUVec2* = object
  x*: int
  y*: int

type MURect* = object
  x*: int
  y*: int
  w*: int
  h*: int

const
  UnclippedRect* = MURect(
    x: 0,
    y: 0,
    w: 0x1000000,
    h: 0x1000000
  )

type MUColor* = object
  r*: byte
  g*: byte
  b*: byte
  a*: byte

type MUPoolItem* = object
  id*: uint
  lastUpdate*: int

##/ Structs-Commands

type MUBaseCommand* = object 
  id*, size*: int
  case kind*: MUCommandType
  of MUCommandType.Jump:
    destination*: pointer
  of MUCommandType.Clip:
    clipRect*: MURect
  of MUCommandType.Rect:
    rectRect*: MURect
    rectColor*: MUColor
  of MUCommandType.Text:
    textFont*: MUFont
    textPos*: MUVec2
    textColor*: MUColor
    textStr*: char
  of MUCommandType.Icon:
    iconRect*: MURect
    iconId*: int
    iconColor*: MUColor
  of MUCommandType.Image:
    imageRect*: MURect
    imageId*: int
    imageColor*: MUColor
    imageData*: pointer
  else:
    discard

##/ Structs-Context

type MUList*[capacity: int, T] = object
  items*: array[capacity, T]
  index*: int

type MULayout* = object
  body*: MURect
  next*: MURect
  position*: MUVec2
  size*: MUVec2
  max*: MUVec2
  
  widths*: array[MICROUI_MAX_WIDTHS, int]
  items*: int
  itemIndex*: int
  nextRow*: int
  nextType*: MULayoutType
  indent*: int

type MUContainer* = object
  head*, tail*: ptr MUBaseCommand
  rect*: MURect
  body*: MURect
  contentSize*: MUVec2
  scroll*: MUVec2
  
  zIndex*: int
  open*: int #bool?

type MUStyle* = object
  font*: MUFont
  size*: MUVec2

  padding*: int
  spacing*: int
  indent*: int
  titleHeight*: int
  scrollbarSize*: int
  thumbSize*: int
  colors*: array[MUElementColor.ColorMax, MUColor]

const
  DefaultStyle* = MuStyle(
    size: MUVec2(x: 68, y: 10),
    padding: 5,
    spacing: 4,
    indent: 24,

    titleHeight: 24,
    scrollbarSize: 12,
    thumbSize: 8,

    colors: [
      MUColor(r: 230, g: 230, b: 230, a: 255), # ColorText
      MUColor(r: 25, g: 25, b: 25, a: 255), # ColorBorder
      MUColor(r: 50, g: 50, b: 50, a: 255), # ColorWindowBackground
      MUColor(r: 25, g: 25, b: 25, a: 255), # ColorTitleBackground
      MUColor(r: 240, g: 240, b: 240, a: 255), # ColorTitleText
      MUColor(r: 0, g: 0, b: 0, a: 0), # ColorPanelBackground
      MUColor(r: 75, g: 75, b: 75, a: 255), # ColorButton
      MUColor(r: 95, g: 95, b: 95, a: 255), # ColorButtonHover
      MUColor(r: 115, g: 115, b: 115, a: 255), # ColorButtonFocus
      MUColor(r: 30, g: 30, b: 30, a: 255), # ColorBase
      MUColor(r: 35, g: 35, b: 35, a: 255), # ColorBaseHover
      MUColor(r: 40, g: 40, b: 40, a: 255), # ColorBaseFocus
      MUColor(r: 43, g: 43, b: 43, a: 255), # ColorScrollBase
      MUColor(r: 30, g: 30, b: 30, a: 255), # ColorScrollThumb
      # Extras:
      MUColor(r: 35, g: 35, b: 35, a: 255),  # ColorMenuBar
      MUColor(r: 100, g: 100, b: 100, a: 255),  # ColorSeparator
      MUColor(r: 57, g: 113, b: 219, a: 255)  # ColorTextLink
    ]
  )

proc defaultTextHeight(font: MUFont): int =
  return 18

type MUContext* = object
  ## callbacks
  text_width*: proc(font: MUFont, text: string, len: int): int
  text_height*: proc(font: MUFont): int = defaultTextHeight
  draw_frame*: proc(ctx: var ref MUContext, rect: MURect, colorId: int): void

  ## state
  style*: MUStyle
  styleRef*: ptr MUStyle
  hover*: uint
  focus*: uint
  lastId*: uint
  lastRect*: MURect
  lastZIndex*: int
  updatedFocus*: bool
  frame*: int

  hoverRoot*: ptr MUContainer
  nextHoverRoot*: ptr MUContainer
  scrollTarget*: ptr MUContainer

  numberEditBuffer*: array[MICROUI_MAX_FMT, char]
  numberEdit: uint

  ## stacks
  commandList*: MUList[MICROUI_COMMANDLIST_SIZE, char]
  rootList*: MUList[MICROUI_ROOTLIST_SIZE, ptr MUContainer]
  containerStack*: MUList[MICROUI_CONTAINERSTACK_SIZE, ptr MUContainer]
  clipStack*: MUList[MICROUI_CLIPSTACK_SIZE, MURect]
  idStack*: MUList[MICROUI_IDSTACK_SIZE, uint]
  layoutStack*: MUList[MICROUI_LAYOUTSTACK_SIZE, MULayout]

  containerPool*: array[MICROUI_CONTAINERPOOL_SIZE, MUPoolItem]
  containers*: array[MICROUI_CONTAINERPOOL_SIZE, MUContainer]
  treeNodePool*: array[MICROUI_TREENODEPOOL_SIZE, MUPoolItem]

  ## input state
  mousePos*: MUVec2
  lastMousePos: MUVec2
  mouseDelta: MUVec2
  scrollDelta: MUVec2

  mouseDown*: seq[MUMouse]
  mousePressed*: seq[MUMouse]
  keyDown*: int
  keyPressed*: int
  inputText*: array[32, char]

var muGlobalContext*: ref MUContext
##/ Utility

proc vec2*(x, y: int): MUVec2 =
  result.x = x
  result.y = y

proc rect*(x, y, w, h: int): MURect =
  result.x = x
  result.y = y
  result.w = w
  result.h = h

proc expand*(r: MURect, n: int): MURect =
  result.x = r.x - n
  result.y = r.y - n
  result.w = r.w + n * 2
  result.h = r.h + n * 2

proc intersect*(r1, r2: MURect): MURect =
  let x1 = max(r1.x, r2.x)
  let y1 = max(r1.y, r2.y)
  var x2 = min(r1.x + r1.w, r2.x + r2.w)
  var y2 = min(r1.y + r1.h, r2.y + r2.h)

  if x2 < x1: x2 = x1
  if y2 < y1: y2 = y1

  result.x = x1
  result.y = y1
  result.w = x2 - x1
  result.h = y2 - y1

proc overlaps*(r: MURect, v: MUVec2): bool =
  result = (
    v.x >= r.x and v.x < r.x + r.w and v.y >= r.y and v.y < r.y + r.h
  )

proc color*(r, g, b, a: byte): MUColor =
  result.r = r
  result.g = g
  result.b = b
  result.a = a

proc color*(r, g, b, a: int): MUColor =
  result.r = byte(r)
  result.g = byte(g)
  result.b = byte(b)
  result.a = byte(a)

##/ Functions

const HASH_INITIAL = 2166136261'u32

proc hash(h: var uint, data: openArray[byte]) =
  for b in data:
    h = (h xor uint(b)) * 16777619

proc clear[T](arr: var seq[T]) =
  let len = arr.len
  for i in 0..<len:
    arr.delete(i)

proc assertGlobalContext*() =
  if muGlobalContext == nil:
    raise newException(ValueError, "microui is not initialised!")

proc getMouseFromBtn(btn: int): MUMouse =
  case btn
  of 0: result = MUMouse.Left
  of 1: result = MUMouse.Right
  of 2: result = MUMouse.Middle
  else: result = MUMouse.Left

proc muGetId*(muCtx: var ref MUContext, data: openArray[byte]): uint =
  let idx = muCtx.idStack.index
  result = if idx > 0: muCtx.idStack.items[idx - 1] else: HASH_INITIAL
  hash(result, data)
  muCtx.lastId = result

proc muGetIdStr*(muCtx: var ref MUContext, str: string): uint =
  muGetId(muCtx, cast[seq[byte]](str))

proc muGetIdPtr*(muCtx: var ref MUContext, data: pointer, size: int): uint =
  if data == nil or size <= 0:
    return muGetId(muCtx, [])
  var bytes = newSeq[byte](size)
  copyMem(addr bytes[0], data, size)
  muGetId(muCtx, bytes)

proc muPushIdPtr*(muCtx: var ref MUContext, data: pointer, size: int) =
  let id = muGetIdPtr(muCtx, data, size)
  if muCtx.idStack.index < MICROUI_IDSTACK_SIZE:
    muCtx.idStack.items[muCtx.idStack.index] = id
    muCtx.idStack.index += 1

proc muPushId*(muCtx: var ref MUContext, data: openArray[byte]) =
  if muCtx.idStack.index < MICROUI_IDSTACK_SIZE:
    muCtx.idStack.items[muCtx.idStack.index] = muGetId(muCtx, data)
    muCtx.idStack.index += 1

proc muPushIdStr*(muCtx: var ref MUContext, str: string) =
  muPushId(muCtx, cast[seq[byte]](str))

proc muGetClipRect*(muCtx: var ref MUContext): MURect =
  if muCtx.clipStack.index > 0:
    result = muCtx.clipStack.items[muCtx.clipStack.index - 1]
  else:
    result = UnclippedRect

proc muPopId*(muCtx: var ref MUContext) =
  if muCtx.idStack.index > 0:
    muCtx.idStack.index -= 1

proc muPushClipRect*(muCtx: var ref MUContext, rect: MURect) =
  let last = muGetClipRect(muCtx)
  if muCtx.clipStack.index < MICROUI_CLIPSTACK_SIZE:
    muCtx.clipStack.items[muCtx.clipStack.index] = intersect(rect, last)
    muCtx.clipStack.index += 1

proc muPopClipRect*(muCtx: var ref MUContext) =
  if muCtx.clipStack.index > 0:
    muCtx.clipStack.index -= 1

proc muCheckClip*(muCtx: var ref MUContext, r: MURect): MUClip =
  let cr = muGetClipRect(muCtx)
  if r.x > cr.x + cr.w or r.x + r.w < cr.x or r.y > cr.y + cr.h or r.y + r.h < cr.y:
    return All
  if r.x >= cr.x and r.x + r.w <= cr.x + cr.w and r.y >= cr.y and r.y + r.h <= cr.y + cr.h:
    return None
  return Partial

proc muPoolUpdate*(muCtx: var ref MUContext, items: var openArray[MUPoolItem], idx: int) =
  items[idx].lastUpdate = muCtx.frame

proc muPoolInit*(muCtx: var ref MUContext, items: var openArray[MUPoolItem], id: uint): int =
  var n = -1
  var f = muCtx.frame
  for i in 0..<items.len:
    if items[i].lastUpdate < f:
      f = items[i].lastUpdate
      n = i
  if n > -1:
    items[n].id = id
    muPoolUpdate(muCtx, items, n)
  result = n

proc muPoolGet*(muCtx: var ref MUContext, items: openArray[MUPoolItem], id: uint): int =
  for i in 0..<items.len:
    if items[i].id == id:
      return i
  return -1

proc muGetCurrentContainer*(muCtx: var ref MUContext): ptr MUContainer =
  if muCtx.containerStack.index > 0:
    result = muCtx.containerStack.items[muCtx.containerStack.index - 1]

proc muBringToFront*(muCtx: var ref MUContext, cnt: ptr MUContainer) =
  muCtx.lastZIndex += 1
  cnt.zIndex = muCtx.lastZIndex

proc getContainer*(muCtx: var ref MUContext, id: uint, opt: int): ptr MUContainer =
  var idx = muPoolGet(muCtx, muCtx.containerPool, id)
  if idx >= 0:
    if muCtx.containers[idx].open != 0 or (opt and (1 shl ord(MUWindowOption.Closed))) == 0:
      muPoolUpdate(muCtx, muCtx.containerPool, idx)
    return addr muCtx.containers[idx]
  if (opt and (1 shl ord(MUWindowOption.Closed))) != 0:
    return nil
  idx = muPoolInit(muCtx, muCtx.containerPool, id)
  var cnt = addr muCtx.containers[idx]
  cnt[] = MUContainer()
  cnt.open = 1
  muBringToFront(muCtx, cnt)
  return cnt

proc muGetContainer*(muCtx: var ref MUContext, name: string): ptr MUContainer =
  let id = muGetIdStr(muCtx, name)
  return getContainer(muCtx, id, 0)

proc muPushCommand*(muCtx: var ref MUContext, cmd: MUBaseCommand) =
  let size = cmd.size
  if muCtx.commandList.index + size <= MICROUI_COMMANDLIST_SIZE:
    var dest = addr muCtx.commandList.items[muCtx.commandList.index]
    copyMem(dest, addr cmd, size)
    muCtx.commandList.index += size

proc muSetFocus*(muCtx: var ref MUContext, id: uint) =
  muCtx.focus = id
  muCtx.updatedFocus = true

proc muInputMouseMove*(muCtx: var ref MUContext, x, y: int) =
  muCtx.mousePos = vec2(x, y)

proc muInputMouseDown*(muCtx: var ref MUContext, x, y: int; btn: int) =
  muCtx.muInputMouseMove(x, y)
  let mouse = getMouseFromBtn(btn)

  if mouse notin muCtx.mouseDown:
    muCtx.mouseDown.add(mouse)
  if mouse notin muCtx.mousePressed:
    muCtx.mousePressed.add(mouse)

proc muInputMouseDown*(muCtx: var ref MUContext, x, y: int, btn: MUMouse) =
  if btn notin muCtx.mouseDown:
    muCtx.mouseDown.add(btn)
  if btn notin muCtx.mousePressed:
    muCtx.mousePressed.add(btn)

proc muInputMouseDown*(muCtx: var ref MUContext, btn: int) =
  let mouse = getMouseFromBtn(btn)
  if mouse notin muCtx.mouseDown:
    muCtx.mouseDown.add(mouse)
  
  if mouse notin muCtx.mousePressed:
    muCtx.mousePressed.add(mouse)

proc muInputMouseDown*(muCtx: var ref MUContext, btn: MUMouse) =
  if btn notin muCtx.mouseDown:
    muCtx.mouseDown.add(btn)
  
  if btn notin muCtx.mousePressed:
    muCtx.mousePressed.add(btn)

proc muInputMouseUp*(muCtx: var ref MUContext, x, y: int; btn: int) =
  let mouse = getMouseFromBtn(btn)

  if mouse in muCtx.mouseDown:
    for i in 0..<muCtx.mouseDown.len:
      if muCtx.mouseDown[i] == mouse:
        muCtx.mouseDown.delete(i)

proc muInputMouseUp*(muCtx: var ref MUContext, x, y: int, btn: MUMouse) =
  if btn in muCtx.mouseDown:
    for i in 0..<muCtx.mouseDown.len:
      if muCtx.mouseDown[i] == btn:
        muCtx.mouseDown.delete(i)

proc muInputMouseUp*(muCtx: var ref MUContext, btn: int) =
  let mouse = getMouseFromBtn(btn)

  if mouse in muCtx.mouseDown:
    for i in 0..<muCtx.mouseDown.len:
      if muCtx.mouseDown[i] == mouse:
        muCtx.mouseDown.delete(i)

proc muInputMouseUp*(muCtx: var ref MUContext, btn: MUMouse) =
  if btn in muCtx.mouseDown:
    for i in 0..<muCtx.mouseDown.len:
      if muCtx.mouseDown[i] == btn:
        muCtx.mouseDown.delete(i)

proc isPressed*(muCtx: var ref MUContext, btn: MUMouse): bool =
  result = btn in muCtx.mousePressed

proc isPressed*(btn: MUMouse): bool =
  assertGlobalContext()
  result = btn in muGlobalContext.mousePressed

proc isPressed*(muCtx: var ref MUContext, btn: int): bool =
  let mouse = getMouseFromBtn(btn)
  result = mouse in muCtx.mousePressed

proc isPressed*(btn: int): bool =
  assertGlobalContext()
  let mouse = getMouseFromBtn(btn)
  result = mouse in muGlobalContext.mousePressed

proc isDown*(muCtx: var ref MUContext, btn: MUMouse): bool =
  result = btn in muCtx.mouseDown

proc isDown*(btn: MUMouse): bool =
  assertGlobalContext()
  result = btn in muGlobalContext.mouseDown

proc isDown*(muCtx: var ref MUContext, btn: int): bool =
  let mouse = getMouseFromBtn(btn)
  result = mouse in muCtx.mouseDown

proc isDown*(btn: int): bool =
  assertGlobalContext()
  let mouse = getMouseFromBtn(btn)
  result = mouse in muGlobalContext.mouseDown

proc isAnyMouseDown*(muCtx: var ref MUContext): bool =
  result = muCtx.mouseDown.len > 0

proc isAnyMouseDown*(): bool =
  assertGlobalContext()
  result = muGlobalContext.mouseDown.len > 0

proc isAnyMousePressed*(muCtx: var ref MUContext): bool =
  result = muCtx.mousePressed.len > 0

proc isAnyMousePressed*(): bool =
  assertGlobalContext()
  result = muGlobalContext.mousePressed.len > 0

proc muInputScroll*(muCtx: var ref MUContext, x, y: int) =
  muCtx.scrollDelta.x += x
  muCtx.scrollDelta.y += y

proc muInputKeyDown*(muCtx: var ref MUContext, key: int) =
  muCtx.keyPressed = bitor[int](muCtx.keyPressed, key)
  muCtx.keyDown = bitor[int](muCtx.keyDown, key)

proc muInputKeyUp*(muCtx: var ref MUContext, key: int) =
  muCtx.keyDown = bitand[int](muCtx.keyDown, bitnot(key))

proc muInputText*(muCtx: var ref MUContext, text: string) =
  var len = 0
  while len < muCtx.inputText.len and muCtx.inputText[len] != '\0':
    len += 1
  var i = 0
  while i < text.len and len + i < muCtx.inputText.len - 1:
    muCtx.inputText[len + i] = text[i]
    i += 1
  if len + i < muCtx.inputText.len:
    muCtx.inputText[len + i] = '\0'

iterator muCommands*(muCtx: var ref MUContext): ptr MUBaseCommand =
  var cmd = cast[ptr MUBaseCommand](addr muCtx.commandList.items[0])
  let endPtr = cast[int](addr muCtx.commandList.items[muCtx.commandList.index])
  while cast[int](cmd) < endPtr:
    if cmd.kind == MUCommandType.Jump:
      cmd = cast[ptr MUBaseCommand](cmd.destination)
      continue
    yield cmd
    cmd = cast[ptr MUBaseCommand](cast[int](cmd) + cmd.size)

proc muNextCommand*(muCtx: var ref MUContext, cmd: var ptr MUBaseCommand): bool =
  let endPtr = cast[int](addr muCtx.commandList.items[muCtx.commandList.index])
  if cmd != nil:
    cmd = cast[ptr MUBaseCommand](cast[int](cmd) + cmd.size)
  else:
    cmd = cast[ptr MUBaseCommand](addr muCtx.commandList.items[0])
  while cast[int](cmd) < endPtr:
    if cmd == nil:
      return false
    if cmd.kind != MUCommandType.Jump:
      return true
    cmd = cast[ptr MUBaseCommand](cmd.destination)
  cmd = nil
  return false

proc pushJump*(muCtx: var ref MUContext, dest: pointer): ptr MUBaseCommand =
  if muCtx.commandList.index + sizeof(MUBaseCommand) > MICROUI_COMMANDLIST_SIZE:
    return nil
  {.cast(uncheckedAssign).}:
    let cmd = cast[ptr MUBaseCommand](addr muCtx.commandList.items[muCtx.commandList.index])
    cmd.kind = MUCommandType.Jump
    cmd.size = sizeof(MUBaseCommand)
    cmd.destination = dest
    muCtx.commandList.index += cmd.size
    return cmd

proc muSetClip*(muCtx: var ref MUContext, rect: MURect) =
  {.cast(uncheckedAssign).}:
    var cmd: MUBaseCommand
    cmd.kind = MUCommandType.Clip
    cmd.size = sizeof(MUBaseCommand)
    cmd.clipRect = rect
    muPushCommand(muCtx, cmd)

proc muDrawRect*(muCtx: var ref MUContext, rect: MURect, color: MUColor) =
  var cmd: MUBaseCommand
  let r = intersect(rect, muGetClipRect(muCtx))
  if r.w > 0 and r.h > 0:
    {.cast(uncheckedAssign).}:
      cmd.kind = MUCommandType.Rect
      cmd.size = sizeof(MUBaseCommand)
      cmd.rectRect = r
      cmd.rectColor = color
      muPushCommand(muCtx, cmd)

proc muDrawBox*(muCtx: var ref MUContext, boxRect: MURect, color: MUColor) =
  muDrawRect(muCtx, rect(boxRect.x + 1, boxRect.y, boxRect.w - 2, 1), color)
  muDrawRect(muCtx, rect(boxRect.x + 1, boxRect.y + boxRect.h - 1, boxRect.w - 2, 1), color)
  muDrawRect(muCtx, rect(boxRect.x, boxRect.y, 1, boxRect.h), color)
  muDrawRect(muCtx, rect(boxRect.x + boxRect.w - 1, boxRect.y, 1, boxRect.h), color)

proc muDrawText*(muCtx: var ref MUContext, font: MUFont, str: string, pos: MUVec2, color: MUColor) =
  let r = rect(pos.x, pos.y, muCtx.text_width(font, str, str.len), muCtx.text_height(font))
  let clipped = muCheckClip(muCtx, r)
  if clipped == MUClip.All:
    return
  if clipped == MUClip.Partial:
    muSetClip(muCtx, muGetClipRect(muCtx))
  let size = sizeof(MUBaseCommand) + str.len
  if muCtx.commandList.index + size <= MICROUI_COMMANDLIST_SIZE:
    {.cast(uncheckedAssign).}:
      let cmd = cast[ptr MUBaseCommand](addr muCtx.commandList.items[muCtx.commandList.index])
      cmd.kind = MUCommandType.Text
      cmd.size = size
      cmd.textPos = pos
      cmd.textColor = color
      cmd.textFont = font
    let textDest = cast[ptr UncheckedArray[char]](addr cmd.textStr)
    if str.len > 0:
      copyMem(textDest, unsafeAddr str[0], str.len)
    textDest[str.len] = '\0'
    muCtx.commandList.index += size
  if clipped != None:
    muSetClip(muCtx, UnclippedRect)

proc muDrawIcon*(muCtx: var ref MUContext, id: int, rect: MURect, color: MUColor) =
  var cmd: MUBaseCommand
  let clipped = muCheckClip(muCtx, rect)
  if clipped == All:
    return
  if clipped == Partial:
    muSetClip(muCtx, muGetClipRect(muCtx))
  {.cast(uncheckedAssign).}:
    cmd.kind = MUCommandType.Icon
    cmd.size = sizeof(MUBaseCommand)
    cmd.iconId = id
    cmd.iconRect = rect
    cmd.iconColor = color
  muPushCommand(muCtx, cmd)
  if clipped != None:
    muSetClip(muCtx, UnclippedRect)

proc muDrawImage*(muCtx: var ref MUContext, id: int, rect: MURect, color: MUColor, data: pointer) =
  var cmd: MUBaseCommand
  let clipped = muCheckClip(muCtx, rect)
  if clipped == All:
    return
  if clipped == Partial:
    muSetClip(muCtx, muGetClipRect(muCtx))
  {.cast(uncheckedAssign).}:
    cmd.kind = MUCommandType.Image
    cmd.size = sizeof(MUBaseCommand)
    cmd.imageId = id
    cmd.imageRect = rect
    cmd.imageColor = color
    cmd.imageData = data
  muPushCommand(muCtx, cmd)
  if clipped != None:
    muSetClip(muCtx, UnclippedRect)
  
proc getLayout*(muCtx: var ref MUContext): ptr MULayout =
  if muCtx.layoutStack.index > 0:
    return addr muCtx.layoutStack.items[muCtx.layoutStack.index - 1]

proc muLayoutRow*(muCtx: var ref MUContext, items: int, widths: openArray[int], height: int) =
  let layout = getLayout(muCtx)
  if layout != nil:
    if widths.len > 0:
      for i in 0..<min(items, MICROUI_MAX_WIDTHS):
        if i < widths.len:
          layout.widths[i] = widths[i]
    layout.items = items
    layout.position = vec2(layout.indent, layout.nextRow)
    layout.size.y = height
    layout.itemIndex = 0

proc pushLayout*(muCtx: var ref MUContext, body: MURect, scroll: MUVec2) =
  if muCtx.layoutStack.index < MICROUI_LAYOUTSTACK_SIZE:
    var layout = MULayout()
    layout.body = rect(body.x - scroll.x, body.y - scroll.y, body.w, body.h)
    layout.max = vec2(-0x1000000, -0x1000000)
    muCtx.layoutStack.items[muCtx.layoutStack.index] = layout
    muCtx.layoutStack.index += 1
    muLayoutRow(muCtx, 1, @[0], 0)

proc popContainer(muCtx: var ref MUContext) =
  let cnt = muGetCurrentContainer(muCtx)
  let layout = getLayout(muCtx)
  if cnt != nil and layout != nil:
    cnt.contentSize.x = layout.max.x - layout.body.x
    cnt.contentSize.y = layout.max.y - layout.body.y
  if muCtx.containerStack.index > 0:
    muCtx.containerStack.index -= 1
  if muCtx.layoutStack.index > 0:
    muCtx.layoutStack.index -= 1
  muPopId(muCtx)

proc muLayoutWidth*(muCtx: var ref MUContext, width: int) =
  let layout = getLayout(muCtx)
  if layout != nil:
    layout.size.x = width

proc muLayoutHeight*(muCtx: var ref MUContext, height: int) =
  let layout = getLayout(muCtx)
  if layout != nil:
    layout.size.y = height

proc muLayoutNext*(muCtx: var ref MUContext): MURect =
  var layout = getLayout(muCtx)
  var style = addr muCtx.style
  var res: MURect
  
  if layout == nil:
    return res
  
  if layout.nextType != MULayoutType(0):
    let layoutType = layout.nextType
    layout.nextType = MULayoutType(0)
    res = layout.next
    if layoutType == MULayoutType.Absolute:
      muCtx.lastRect = res
      return res
  else:
    if layout.itemIndex == layout.items:
      muLayoutRow(muCtx, layout.items, [], layout.size.y)
    
    res.x = layout.position.x
    res.y = layout.position.y
    
    res.w = if layout.items > 0: layout.widths[layout.itemIndex] else: layout.size.x
    res.h = layout.size.y
    if res.w == 0: res.w = style.size.x + style.padding * 2
    if res.h == 0: res.h = style.size.y + style.padding * 2
    if res.w < 0: res.w += layout.body.w - res.x + 1
    if res.h < 0: res.h += layout.body.h - res.y + 1
    
    layout.itemIndex += 1
  
  layout.position.x += res.w + style.spacing
  layout.nextRow = max(layout.nextRow, res.y + res.h + style.spacing)
  
  res.x += layout.body.x
  res.y += layout.body.y
  
  layout.max.x = max(layout.max.x, res.x + res.w)
  layout.max.y = max(layout.max.y, res.y + res.h)
  
  muCtx.lastRect = res
  return res

proc muLayoutBeginColumn*(muCtx: var ref MUContext) =
  pushLayout(muCtx, muLayoutNext(muCtx), vec2(0, 0))

proc muLayoutEndColumn*(muCtx: var ref MUContext) =
  var a, b: ptr MULayout
  b = getLayout(muCtx)
  if muCtx.layoutStack.index > 0:
    muCtx.layoutStack.index -= 1
  a = getLayout(muCtx)
  if a != nil and b != nil:
    a.position.x = max(a.position.x, b.position.x + b.body.x - a.body.x)
    a.nextRow = max(a.nextRow, b.nextRow + b.body.y - a.body.y)
    a.max.x = max(a.max.x, b.max.x)
    a.max.y = max(a.max.y, b.max.y)

proc muLayoutSetNext*(muCtx: var ref MUContext, r: MURect, relative: bool) =
  let layout = getLayout(muCtx)
  if layout != nil:
    layout.next = r
    layout.nextType = if relative: MULayoutType.Relative else: MULayoutType.Absolute

proc inHoverRoot(muCtx: var ref MUContext): bool =
  var i = muCtx.containerStack.index
  while i > 0:
    i -= 1
    if muCtx.containerStack.items[i] == muCtx.hoverRoot:
      return true
    if muCtx.containerStack.items[i].head != nil:
      break
  return false

proc muMouseOver*(muCtx: var ref MUContext, rect: MURect): bool =
  return overlaps(rect, muCtx.mousePos) and 
         overlaps(muGetClipRect(muCtx), muCtx.mousePos) and
         inHoverRoot(muCtx)

proc muUpdateControl*(muCtx: var ref MUContext, id: uint, rect: MURect, opt: int) =
  let mouseover = muMouseOver(muCtx, rect)
  
  if muCtx.focus == id:
    muCtx.updatedFocus = true
  if (opt and (1 shl ord(MUWindowOption.NoInteract))) != 0:
    return
  if mouseover and not muCtx.isAnyMouseDown:
    muCtx.hover = id
  
  if muCtx.focus == id:
    if muCtx.isAnyMousePressed and not mouseover:
      muSetFocus(muCtx, 0)
    if not muCtx.isAnyMouseDown and (opt and (1 shl ord(MUWindowOption.HoldFocus))) == 0:
      muSetFocus(muCtx, 0)
  
  if muCtx.hover == id:
    if muCtx.isAnyMousePressed:
      muSetFocus(muCtx, id)
    elif not mouseover:
      muCtx.hover = 0
  elif mouseover and muCtx.isAnyMousePressed:
    muSetFocus(muCtx, id)

proc drawFrame(muCtx: var ref MUContext, rect: MURect, colorid: int): void =
  muDrawRect(muCtx, rect, muCtx.style.colors[MUElementColor(colorid)])
  if colorid == ord(MUElementColor.ColorScrollBase) or
     colorid == ord(MUElementColor.ColorScrollThumb) or
     colorid == ord(MUElementColor.ColorTitleBackground):
    return
  if muCtx.style.colors[MUElementColor.ColorBorder].a != 0:
    muDrawBox(muCtx, expand(rect, 1), muCtx.style.colors[MUElementColor.ColorBorder])

proc muDrawControlFrame*(muCtx: var ref MUContext, id: uint, rect: MURect, colorid: int, opt: int) =
  if (opt and (1 shl ord(MUWindowOption.NoFrame))) != 0:
    return
  var cid = colorid
  cid += (if muCtx.focus == id: 2 elif muCtx.hover == id: 1 else: 0)
  drawFrame(muCtx, rect, cid)

proc muDrawControlText*(muCtx: var ref MUContext, str: string, rect: MURect, colorid: int, opt: int) =
  var pos: MUVec2
  let font = muCtx.style.font
  let tw = muCtx.text_width(font, str, str.len)
  muPushClipRect(muCtx, rect)
  pos.y = rect.y + (rect.h - muCtx.text_height(font)) div 2
  if (opt and (1 shl ord(MUWindowOption.AlignCenter))) != 0:
    pos.x = rect.x + (rect.w - tw) div 2
  elif (opt and (1 shl ord(MUWindowOption.AlignRight))) != 0:
    pos.x = rect.x + rect.w - tw - muCtx.style.padding
  else:
    pos.x = rect.x + muCtx.style.padding
  muDrawText(muCtx, font, str, pos, muCtx.style.colors[MUElementColor(colorid)])
  muPopClipRect(muCtx)

proc muText*(muCtx: var ref MUContext, text: string) =
  var p = 0
  let font = muCtx.style.font
  let color = muCtx.style.colors[MUElementColor.ColorText]
  muLayoutBeginColumn(muCtx)
  muLayoutRow(muCtx, 1, @[-1], muCtx.text_height(font))
  while p < text.len:
    let r = muLayoutNext(muCtx)
    var w = 0
    var start = p
    var endPos = p
    while p < text.len and text[p] != '\n':
      let wordStart = p
      while p < text.len and text[p] != ' ' and text[p] != '\n':
        p += 1
      let word = text[wordStart ..< p]
      w += muCtx.text_width(font, word, word.len)
      if w > r.w and endPos != start:
        break
      if p < text.len and text[p] == ' ':
        w += muCtx.text_width(font, " ", 1)
        endPos = p
        p += 1
      else:
        endPos = p
    if endPos > start:
      muDrawText(muCtx, font, text[start ..< endPos], vec2(r.x, r.y), color)
    else:
      muDrawText(muCtx, font, "", vec2(r.x, r.y), color)
    if p < text.len and text[p] == '\n':
      p += 1
  muLayoutEndColumn(muCtx)

proc muLabel*(muCtx: var ref MUContext, text: string) =
  muDrawControlText(muCtx, text, muLayoutNext(muCtx), ord(MUElementColor.ColorText), 0)

proc muButton*(muCtx: var ref MUContext, label: string, icon: int = 0, opt: int = 0): bool =
  var id: uint
  if label.len > 0:
    id = muGetIdStr(muCtx, label)
  else:
    id = muGetId(muCtx, cast[seq[byte]](@[byte(icon)]))
  let r = muLayoutNext(muCtx)
  muUpdateControl(muCtx, id, r, opt)
  if muCtx.isPressed(MUMouse.Left) and muCtx.focus == id:
    result = result or (1 shl ord(MUResult.Submit)) != 0
  muDrawControlFrame(muCtx, id, r, ord(MUElementColor.ColorButton), opt)
  if label.len > 0:
    muDrawControlText(muCtx, label, r, ord(MUElementColor.ColorText), opt)
  if icon != 0:
    muDrawIcon(muCtx, icon, r, muCtx.style.colors[MUElementColor.ColorText])

proc muCheckbox*(muCtx: var ref MUContext, label: string, state: var bool): int =
  var statePtr = addr state
  var id = muGetIdPtr(muCtx, addr statePtr, sizeof(statePtr))
  let r = muLayoutNext(muCtx)
  let box = rect(r.x, r.y, r.h, r.h)
  muUpdateControl(muCtx, id, r, 0)
  if muCtx.isPressed(MUMouse.Left) and muCtx.focus == id:
    result = result or (1 shl ord(MUResult.Change))
    state = not state
  muDrawControlFrame(muCtx, id, box, ord(MUElementColor.ColorBase), 0)
  if state:
    muDrawIcon(muCtx, ord(MUIcon.Check), box, muCtx.style.colors[MUElementColor.ColorText])
  let r2 = rect(r.x + box.w, r.y, r.w - box.w, r.h)
  muDrawControlText(muCtx, label, r2, ord(MUElementColor.ColorText), 0)

proc muTextbox*(muCtx: var ref MUContext, buf: var string, opt: int = 0): int =
  var bufPtr = addr buf
  let id = muGetIdPtr(muCtx, addr bufPtr, sizeof(bufPtr))
  let r = muLayoutNext(muCtx)
  muUpdateControl(muCtx, id, r, opt or (1 shl ord(MUWindowOption.HoldFocus)))
  
  if muCtx.focus == id:
    let len = buf.len
    let inputLen = min(255 - len, muCtx.inputText.len)
    if inputLen > 0:
      var i = 0
      while i < inputLen and muCtx.inputText[i] != '\0':
        buf.add(muCtx.inputText[i])
        i += 1
      result = result or (1 shl ord(MUResult.Change))
    
    if (muCtx.keyPressed and (1 shl ord(MUControlKey.Backspace))) != 0 and len > 0:
      buf.setLen(len - 1)
      result = result or (1 shl ord(MUResult.Change))
    
    if (muCtx.keyPressed and (1 shl ord(MUControlKey.Return))) != 0:
      muSetFocus(muCtx, 0)
      result = result or (1 shl ord(MUResult.Submit))
  
  muDrawControlFrame(muCtx, id, r, ord(MUElementColor.ColorBase), opt)
  if muCtx.focus == id:
    let color = muCtx.style.colors[MUElementColor.ColorText]
    let font = muCtx.style.font
    let textw = muCtx.text_width(font, buf, buf.len)
    let texth = muCtx.text_height(font)
    let ofx = r.w - muCtx.style.padding - textw - 1
    let textx = r.x + min(ofx, muCtx.style.padding)
    let texty = r.y + (r.h - texth) div 2
    muPushClipRect(muCtx, r)
    muDrawText(muCtx, font, buf, vec2(textx, texty), color)
    muDrawRect(muCtx, rect(textx + textw, texty, 1, texth), color)
    muPopClipRect(muCtx)
  else:
    muDrawControlText(muCtx, buf, r, ord(MUElementColor.ColorText), opt)

proc muSlider*(muCtx: var ref MUContext, value: var float, low, high: float, step: float = 0, opt: int = 0): int =
  var v = value
  var valuePtr = addr value
  let id = muGetIdPtr(muCtx, addr valuePtr, sizeof(valuePtr))
  let base = muLayoutNext(muCtx)
  
  muUpdateControl(muCtx, id, base, opt)
  
  if muCtx.focus == id and (muCtx.isPressed(MUMouse.Left) or muCtx.isDown(MUMouse.Left)):
    v = low + (muCtx.mousePos.x - base.x).float * (high - low) / base.w.float
    if step != 0:
      v = (round((v / step).float) * step)
  
  v = clamp(v, low, high)
  if value != v:
    result = result or (1 shl ord(MUResult.Change))
  value = v
  
  muDrawControlFrame(muCtx, id, base, ord(MUElementColor.ColorBase), opt)
  
  let w = muCtx.style.thumbSize
  let x = int((v - low) * (base.w - w).float / (high - low))
  let thumb = rect(base.x + x, base.y, w, base.h)
  muDrawControlFrame(muCtx, id, thumb, ord(MUElementColor.ColorButton), opt)
  let text = &"{v:.2f}"
  muDrawControlText(muCtx, text, base, ord(MUElementColor.ColorText), opt)

proc header(muCtx: var ref MUContext, label: string, isTreenode: bool, opt: int): int =
  let id = muGetIdStr(muCtx, label)
  let idx = muPoolGet(muCtx, muCtx.treeNodePool, id)
  var active = idx >= 0
  var expanded = if (opt and (1 shl ord(MUWindowOption.Expanded))) != 0: not active else: active
  muLayoutRow(muCtx, 1, @[-1], 0)
  let r = muLayoutNext(muCtx)
  muUpdateControl(muCtx, id, r, 0)

  if muCtx.isPressed(MUMouse.Left) and muCtx.focus == id:
    active = not active

  if idx >= 0:
    if active:
      muPoolUpdate(muCtx, muCtx.treeNodePool, idx)
    else:
      muCtx.treeNodePool[idx] = MUPoolItem()
  elif active:
    discard muPoolInit(muCtx, muCtx.treeNodePool, id)

  if isTreenode:
    if muCtx.hover == id:
      drawFrame(muCtx, r, ord(MUElementColor.ColorButtonHover))
  else:
    muDrawControlFrame(muCtx, id, r, ord(MUElementColor.ColorButton), 0)

  muDrawIcon(muCtx, if expanded: ord(MUIcon.Expanded) else: ord(MUIcon.Collapsed),
             rect(r.x, r.y, r.h, r.h), muCtx.style.colors[MUElementColor.ColorText])
  let r2 = rect(r.x + r.h - muCtx.style.padding, r.y, r.w - (r.h - muCtx.style.padding), r.h)
  muDrawControlText(muCtx, label, r2, ord(MUElementColor.ColorText), 0)

  if expanded:
    return (1 shl ord(MUResult.Active))
  return 0

proc muHeader*(muCtx: var ref MUContext, label: string, opt: int = 0): bool =
  return header(muCtx, label, false, opt) != 0

proc muBeginTreenode*(muCtx: var ref MUContext, label: string, opt: int = 0): bool =
  result = header(muCtx, label, true, opt) != 0
  if result:
    let layout = getLayout(muCtx)
    if layout != nil:
      layout.indent += muCtx.style.indent
    if muCtx.idStack.index < MICROUI_IDSTACK_SIZE:
      muCtx.idStack.items[muCtx.idStack.index] = muCtx.lastId
      muCtx.idStack.index += 1

proc muEndTreenode*(muCtx: var ref MUContext) =
  let layout = getLayout(muCtx)
  if layout != nil:
    layout.indent -= muCtx.style.indent
  muPopId(muCtx)

proc beginRootContainer(muCtx: var ref MUContext, cnt: ptr MUContainer) =
  if muCtx.containerStack.index < MICROUI_CONTAINERSTACK_SIZE:
    muCtx.containerStack.items[muCtx.containerStack.index] = cnt
    muCtx.containerStack.index += 1
  if muCtx.rootList.index < MICROUI_ROOTLIST_SIZE:
    muCtx.rootList.items[muCtx.rootList.index] = cnt
    muCtx.rootList.index += 1
  cnt.head = pushJump(muCtx, nil)
  if overlaps(cnt.rect, muCtx.mousePos):
    if muCtx.nextHoverRoot == nil or cnt.zIndex > muCtx.nextHoverRoot.zIndex:
      muCtx.nextHoverRoot = cnt
  muCtx.clipStack.items[muCtx.clipStack.index] = UnclippedRect
  muCtx.clipStack.index += 1

proc endRootContainer(muCtx: var ref MUContext) =
  let cnt = muGetCurrentContainer(muCtx)
  if cnt != nil:
    cnt.tail = pushJump(muCtx, nil)
    if cnt.head != nil:
      cnt.head.destination = cast[pointer](addr muCtx.commandList.items[muCtx.commandList.index])
  muPopClipRect(muCtx)
  popContainer(muCtx)

proc pushContainerBody(muCtx: var ref MUContext, cnt: ptr MUContainer, body: MURect, opt: int) =
  var bodyRect = body
  if (opt and (1 shl ord(MUWindowOption.NoScroll))) == 0:
    let sz = muCtx.style.scrollbarSize
    var cs = cnt.contentSize
    cs.x += muCtx.style.padding * 2
    cs.y += muCtx.style.padding * 2
    muPushClipRect(muCtx, bodyRect)
    if cs.y > cnt.body.h:
      bodyRect.w -= sz
    if cs.x > cnt.body.w:
      bodyRect.h -= sz
    let maxScrollY = cs.y - bodyRect.h
    if maxScrollY > 0 and bodyRect.h > 0:
      var base = bodyRect
      base.x = bodyRect.x + bodyRect.w
      base.w = muCtx.style.scrollbarSize
      let id = muGetIdStr(muCtx, "!scrollbary")
      muUpdateControl(muCtx, id, base, 0)
      if muCtx.focus == id and muCtx.isDown(MUMouse.Left):
        cnt.scroll.y += muCtx.mouseDelta.y * cs.y div base.h
      cnt.scroll.y = clamp(cnt.scroll.y, 0, maxScrollY)
      drawFrame(muCtx, base, ord(MUElementColor.ColorScrollBase))
      var thumb = base
      thumb.h = max(muCtx.style.thumbSize, base.h * bodyRect.h div cs.y)
      thumb.y += cnt.scroll.y * (base.h - thumb.h) div maxScrollY
      drawFrame(muCtx, thumb, ord(MUElementColor.ColorScrollThumb))
      if muMouseOver(muCtx, bodyRect):
        muCtx.scrollTarget = cnt
    else:
      cnt.scroll.y = 0
    let maxScrollX = cs.x - bodyRect.w
    if maxScrollX > 0 and bodyRect.w > 0:
      var base = bodyRect
      base.y = bodyRect.y + bodyRect.h
      base.h = muCtx.style.scrollbarSize
      let id = muGetIdStr(muCtx, "!scrollbarx")
      muUpdateControl(muCtx, id, base, 0)
      if muCtx.focus == id and muCtx.isDown(MUMouse.Left):
        cnt.scroll.x += muCtx.mouseDelta.x * cs.x div base.w
      cnt.scroll.x = clamp(cnt.scroll.x, 0, maxScrollX)
      drawFrame(muCtx, base, ord(MUElementColor.ColorScrollBase))
      var thumb = base
      thumb.w = max(muCtx.style.thumbSize, base.w * bodyRect.w div cs.x)
      thumb.x += cnt.scroll.x * (base.w - thumb.w) div maxScrollX
      drawFrame(muCtx, thumb, ord(MUElementColor.ColorScrollThumb))
      if muMouseOver(muCtx, bodyRect):
        muCtx.scrollTarget = cnt
    else:
      cnt.scroll.x = 0
    muPopClipRect(muCtx)
  pushLayout(muCtx, expand(bodyRect, -muCtx.style.padding), cnt.scroll)
  cnt.body = bodyRect

proc muBeginWindow*(muCtx: var ref MUContext, title: string, rect: MURect, opt: int = 0): bool =
  let id = muGetIdStr(muCtx, title)
  let cnt = getContainer(muCtx, id, opt)
  if cnt == nil or cnt.open == 0:
    return false
  muCtx.idStack.items[muCtx.idStack.index] = id
  muCtx.idStack.index += 1
  
  if cnt.rect.w == 0:
    cnt.rect = rect
  beginRootContainer(muCtx, cnt)
  var bodyRect = cnt.rect
  
  if (opt and (1 shl ord(MUWindowOption.NoFrame))) == 0:
    drawFrame(muCtx, cnt.rect, ord(MUElementColor.ColorWindowBackground))

  if (opt and (1 shl ord(MUWindowOption.NoTitle))) == 0:
    var titleRect = rect(cnt.rect.x, cnt.rect.y, cnt.rect.w, muCtx.style.titleHeight)
    drawFrame(muCtx, titleRect, ord(MUElementColor.ColorTitleBackground))
    let titleId = muGetIdStr(muCtx, "!title")
    muUpdateControl(muCtx, titleId, titleRect, opt)
    muDrawControlText(muCtx, title, titleRect, ord(MUElementColor.ColorTitleText), 0)
    if titleId == muCtx.focus and muCtx.isDown(MUMouse.Left):
      cnt.rect.x += muCtx.mouseDelta.x
      cnt.rect.y += muCtx.mouseDelta.y
    bodyRect.y += titleRect.h
    bodyRect.h -= titleRect.h
    if (opt and (1 shl ord(MUWindowOption.NoClose))) == 0:
      let closeId = muGetIdStr(muCtx, "!close")
      let closeRect = rect(titleRect.x + titleRect.w - titleRect.h, titleRect.y, titleRect.h, titleRect.h)
      muDrawIcon(muCtx, ord(MUIcon.Close), closeRect, muCtx.style.colors[MUElementColor.ColorTitleText])
      muUpdateControl(muCtx, closeId, closeRect, opt)
      if muCtx.isPressed(MUMouse.Left) and closeId == muCtx.focus:
        cnt.open = 0
      titleRect.w -= closeRect.w

  pushContainerBody(muCtx, cnt, bodyRect, opt)

  if (opt and (1 shl ord(MUWindowOption.NoResive))) == 0:
    let sz = muCtx.style.titleHeight
    let resizeId = muGetIdStr(muCtx, "!resize")
    let resizeRect = rect(rect.x + rect.w - sz, rect.y + rect.h - sz, sz, sz)
    muUpdateControl(muCtx, resizeId, resizeRect, opt)
    if resizeId == muCtx.focus and muCtx.isDown(MUMouse.Left):
      cnt.rect.w = max(96, cnt.rect.w + muCtx.mouseDelta.x)
      cnt.rect.h = max(64, cnt.rect.h + muCtx.mouseDelta.y)

  if (opt and (1 shl ord(MUWindowOption.AutoSize))) != 0:
    let layout = getLayout(muCtx)
    if layout != nil:
      cnt.rect.w = cnt.contentSize.x + (cnt.rect.w - layout.body.w)
      cnt.rect.h = cnt.contentSize.y + (cnt.rect.h - layout.body.h)

  if (opt and (1 shl ord(MUWindowOption.Popup))) != 0 and muCtx.isAnyMousePressed and muCtx.hoverRoot != cnt:
    cnt.open = 0

  muPushClipRect(muCtx, cnt.body)
  return true

proc muEndWindow*(muCtx: var ref MUContext) =
  muPopClipRect(muCtx)
  endRootContainer(muCtx)

proc muOpenPopup*(muCtx: var ref MUContext, name: string) =
  let cnt = muGetContainer(muCtx, name)
  muCtx.hoverRoot = cnt
  muCtx.nextHoverRoot = cnt
  cnt.rect = rect(muCtx.mousePos.x, muCtx.mousePos.y, 1, 1)
  cnt.open = 1
  muBringToFront(muCtx, cnt)

proc muBeginPopup*(muCtx: var ref MUContext, name: string): bool =
  let opt = (1 shl ord(MUWindowOption.Popup)) or (1 shl ord(MUWindowOption.AutoSize)) or (1 shl ord(MUWindowOption.NoResive)) or (1 shl ord(MUWindowOption.NoScroll)) or (1 shl ord(MUWindowOption.NoTitle)) or (1 shl ord(MUWindowOption.Closed))
  return muBeginWindow(muCtx, name, rect(0, 0, 0, 0), opt)

proc muEndPopup*(muCtx: var ref MUContext) =
  muEndWindow(muCtx)

proc muBeginPanel*(muCtx: var ref MUContext, name: string, opt: int = 0) =
  muPushIdStr(muCtx, name)
  let cnt = getContainer(muCtx, muCtx.lastId, opt)
  cnt.rect = muLayoutNext(muCtx)
  if (opt and (1 shl ord(MUWindowOption.NoFrame))) == 0:
    drawFrame(muCtx, cnt.rect, ord(MUElementColor.ColorPanelBackground))
  muCtx.containerStack.items[muCtx.containerStack.index] = cnt
  muCtx.containerStack.index += 1
  pushContainerBody(muCtx, cnt, cnt.rect, opt)
  muPushClipRect(muCtx, cnt.body)

proc muEndPanel*(muCtx: var ref MUContext) =
  muPopClipRect(muCtx)
  popContainer(muCtx)

proc muInit*(muCtx: var ref MUContext) =
  if muCtx != nil:
    return

  muCtx = new MUContext
  muCtx.style = DefaultStyle
  muCtx.styleRef = addr muCtx.style
  muCtx.draw_frame = drawFrame

  muGlobalContext = muCtx

proc muBegin*(muCtx: var ref MUContext) =
  muCtx.commandList.index = 0
  muCtx.rootList.index = 0
  muCtx.scrollTarget = nil
  muCtx.hoverRoot = muCtx.nextHoverRoot
  muCtx.nextHoverRoot = nil
  muCtx.mouseDelta.x = muCtx.mousePos.x - muCtx.lastMousePos.x
  muCtx.mouseDelta.y = muCtx.mousePos.y - muCtx.lastMousePos.y
  muCtx.frame += 1

proc muEnd*(muCtx: var ref MUContext) =
  if muCtx.scrollTarget != nil:
    muCtx.scrollTarget.scroll.x += muCtx.scrollDelta.x
    muCtx.scrollTarget.scroll.y += muCtx.scrollDelta.y
  
  if not muCtx.updatedFocus:
    muCtx.focus = 0
  
  muCtx.updatedFocus = false
  
  if muCtx.isAnyMousePressed and muCtx.nextHoverRoot != nil and 
     muCtx.nextHoverRoot.zIndex < muCtx.lastZIndex and 
     muCtx.nextHoverRoot.zIndex >= 0:
    muBringToFront(muCtx, muCtx.nextHoverRoot)
  
  muCtx.keyPressed = 0
  muCtx.inputText[0] = '\0'
  muCtx.mousePressed.clear()
  muCtx.scrollDelta = vec2(0, 0)
  muCtx.lastMousePos = muCtx.mousePos

  if muCtx.rootList.index > 1:
    var i = 1
    while i < muCtx.rootList.index:
      let key = muCtx.rootList.items[i]
      var j = i
      while j > 0 and muCtx.rootList.items[j - 1].zIndex > key.zIndex:
        muCtx.rootList.items[j] = muCtx.rootList.items[j - 1]
        j -= 1
      muCtx.rootList.items[j] = key
      i += 1

  let n = muCtx.rootList.index
  if n > 0:
    let first = muCtx.rootList.items[0]
    if first != nil and first.head != nil:
      let cmd = cast[ptr MUBaseCommand](addr muCtx.commandList.items[0])
      cmd.destination = cast[pointer](cast[int](first.head) + first.head.size)
  var i = 0
  while i < n:
    let cnt = muCtx.rootList.items[i]
    if cnt != nil and cnt.tail != nil:
      if i + 1 < n and muCtx.rootList.items[i + 1] != nil:
        let nextHead = muCtx.rootList.items[i + 1].head
        if nextHead != nil:
          cnt.tail.destination = cast[pointer](cast[int](nextHead) + nextHead.size)
      else:
        cnt.tail.destination = cast[pointer](addr muCtx.commandList.items[muCtx.commandList.index])
    i += 1

## Templates

template mu*(muCtx: var ref MUContext, body: untyped) =
  muBegin(muCtx)
  try:
    body
  finally:
    muEnd(muCtx)

template muWindow*(muCtx: var ref MUContext, title: string, rect: MURect, body: untyped) =
  if muBeginWindow(muCtx, title, rect, 0):
    try:
      body
    finally:
      muEndWindow(muCtx)

template muPanel*(muCtx: var ref MUContext, name: string, body: untyped) =
  muBeginPanel(muCtx, name, 0)
  try:
    body
  finally:
    muEndPanel(muCtx)

template muPopup*(muCtx: var ref MUContext, name: string, body: untyped) =
  if muBeginPopup(muCtx, name):
    try:
      body
    finally:
      muEndPopup(muCtx)

template muTreenode*(muCtx: var ref MUContext, label: string, body: untyped) =
  if muBeginTreenode(muCtx, label, 0):
    try:
      body
    finally:
      muEndTreenode(muCtx)

template muLayoutColumn*(muCtx: var ref MUContext, body: untyped) =
  muLayoutBeginColumn(muCtx)
  try:
    body
  finally:
    muLayoutEndColumn(muCtx)

# Global context
# note: we have to do this down here as `muCtx: var ref MUContext = muGlobalContext` fails type matching

## Global funcs

proc muInputMouseDown*(btn: MUMouse) =
  assertGlobalContext()

  muInputMouseDown(muGlobalContext, btn)

proc muInputMouseUp*(btn: MUMouse) =
  assertGlobalContext()
  
  muInputMouseUp(muGlobalContext, btn)

proc muInputMouseMove*(x, y: int) =
  assertGlobalContext()
  
  muInputMouseMove(muGlobalContext, x, y)

proc muInputScroll*(dx, dy: int) =
  assertGlobalContext()
  
  muInputScroll(muGlobalContext, dx, dy)

proc muInputKeyDown*(key: int) =
  assertGlobalContext()
  
  muInputKeyDown(muGlobalContext, key)

proc muInputKeyUp*(key: int) =
  assertGlobalContext()
  
  muInputKeyUp(muGlobalContext, key)

proc muInputText*(text: string) =
  assertGlobalContext()
    
  muInputText(muGlobalContext, text)

proc muLayoutRow*(cols: int, widths: openArray[int], height: int) =
  assertGlobalContext()
  
  muLayoutRow(muGlobalContext, cols, widths, height)

proc muText*(text: string) =
  assertGlobalContext()

  muText(muGlobalContext, text)

proc muLabel*(text: string) =
  assertGlobalContext()

  muLabel(muGlobalContext, text)

proc muButton*(label: string, icon: int = 0, opt: int = 0): bool =
  assertGlobalContext()

  return muButton(muGlobalContext, label, icon, opt)

proc muCheckbox*(label: string, state: var bool): int =
  assertGlobalContext()

  return muCheckbox(muGlobalContext, label, state)

proc muTextbox*(buf: var string, opt: int = 0): int =
  assertGlobalContext()

  return muTextbox(muGlobalContext, buf, opt)

proc muSlider*(value: var float, low, high: float, step: float = 0, opt: int = 0): int =
  assertGlobalContext()

  return muSlider(muGlobalContext, value, low, high, step, opt)
  
proc muHeader*(label: string, opt: int = 0): bool =
  assertGlobalContext()

  return muHeader(muGlobalContext, label, opt)

proc muBeginWindow*(title: string, rect: MURect, opt: int = 0): bool =
  assertGlobalContext()

  return muBeginWindow(muGlobalContext, title, rect, opt)

proc muEndWindow*() =
  assertGlobalContext()

  muEndWindow(muGlobalContext)

proc muOpenPopup*(name: string) =
  assertGlobalContext()

  muOpenPopup(muGlobalContext, name)

proc muBeginPopup*(name: string): bool =
  assertGlobalContext()
  
  return muBeginPopup(muGlobalContext, name)

proc muEndPopup*() =
  assertGlobalContext()
  
  muEndPopup(muGlobalContext)

proc muBeginPanel*(name: string, opt: int = 0) =
  assertGlobalContext()
  
  muBeginPanel(muGlobalContext, name, opt)

proc muEndPanel*() =
  assertGlobalContext()
  
  muEndPanel(muGlobalContext)

proc muBeginTreenode*(label: string, opt: int = 0): bool =
  assertGlobalContext()
  
  return muBeginTreenode(muGlobalContext, label, opt)

proc muEndTreenode*() =
  assertGlobalContext()
  
  muEndTreenode(muGlobalContext)

proc muLayoutBeginColumn*() =
  assertGlobalContext()
  
  muLayoutBeginColumn(muGlobalContext)

proc muLayoutEndColumn*() =
  assertGlobalContext()
  
  muLayoutEndColumn(muGlobalContext)

## Global Templates

template mu*(body: untyped) =
  assertGlobalContext()

  mu(muGlobalContext, body)

template muWindow*(title: string, rect: MURect, body: untyped) =
  assertGlobalContext()

  muWindow(muGlobalContext, title, rect, body)

template muPanel*(name: string, body: untyped) =
  assertGlobalContext()
  
  muPanel(muGlobalContext, name, body)

template muPopup*(name: string, body: untyped) =
  assertGlobalContext()
  
  muPopup(muGlobalContext, name, body)

template muTreenode*(label: string, body: untyped) =
  assertGlobalContext()
  
  muTreenode(muGlobalContext, label, body)