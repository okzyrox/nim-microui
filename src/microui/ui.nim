## microui

import std/[
  bitops
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
  MICROUI_REAL_FMT* = "%.3g"
  MICROUI_SLIDER_FMT* = "%.2f"

##/ Enums
type MUClip* = enum
  Partial #= 1
  All

type MUCommandType* = enum 
  Jump #= 1
  Clip
  Rect
  Text
  Icon
  Max

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
  ColorMax

type MUIcon* = enum
  Close #= 1
  Check
  Collapsed
  Expanded
  Max

type MUResult* = enum
  Active = 1 shl 0
  Submit = 1 shl 1
  Change = 1 shl 2

type MUWindowOption* = enum
  AligneCenter = 1 shl 0
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
  Left = 1 shl 0
  Right = 1 shl 1
  Middle = 1 shl 2

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
      MUColor(r: 0, g: 0, b: 0, a: 255), # ColorPanelBackground
      MUColor(r: 75, g: 75, b: 75, a: 255), # ColorButton
      MUColor(r: 95, g: 95, b: 95, a: 255), # ColorButtonHover
      MUColor(r: 115, g: 115, b: 115, a: 255), # ColorButtonFocus
      MUColor(r: 30, g: 30, b: 30, a: 255), # ColorBase
      MUColor(r: 35, g: 35, b: 35, a: 255), # ColorBaseHover
      MUColor(r: 40, g: 40, b: 40, a: 255), # ColorBaseFocus
      MUColor(r: 43, g: 43, b: 43, a: 255), # ColorScrollBase
      MUColor(r: 30, g: 30, b: 30, a: 255)  # ColorScrollThumb
    ]
  )

type MUContext* = object
  ## callbacks
  text_width*: proc(font: MUFont, text: string, len: int): int
  text_height*: proc(font: MUFont): int
  draw_frame*: proc(ctx: var MUContext, rect: MURect, colorId: int): void

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
  mousePos: MUVec2
  lastMousePos: MUVec2
  mouseDelta: MUVec2
  scrollDelta: MUVec2

  mouseDown*: int
  mousePressed*: int
  keyDown*: int
  keyPressed*: int
  inputText*: array[32, char]

var muGlobalContext*: MUContext
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
    v.x >= r.x and v.x < r.x + r.w and v.y >= r.y and r.y < r.y + r.h
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

proc muGetId*(muCtx: var MUContext = muGlobalContext, data: openArray[byte]): uint =
  let idx = muCtx.idStack.index
  result = if idx > 0: muCtx.idStack.items[idx - 1] else: HASH_INITIAL
  hash(result, data)
  muCtx.lastId = result

proc muGetIdStr*(muCtx: var MUContext = muGlobalContext, str: string): uint =
  muGetId(muCtx, cast[seq[byte]](str))

proc muPushId*(muCtx: var MUContext = muGlobalContext, data: openArray[byte]) =
  if muCtx.idStack.index < MICROUI_IDSTACK_SIZE:
    muCtx.idStack.items[muCtx.idStack.index] = muGetId(muCtx, data)
    muCtx.idStack.index += 1

proc muPushIdStr*(muCtx: var MUContext = muGlobalContext, str: string) =
  muPushId(muCtx, cast[seq[byte]](str))

proc muGetClipRect*(muCtx: var MUContext = muGlobalContext): MURect =
  if muCtx.clipStack.index > 0:
    result = muCtx.clipStack.items[muCtx.clipStack.index - 1]
  else:
    result = UnclippedRect

proc muPopId*(muCtx: var MUContext = muGlobalContext) =
  if muCtx.idStack.index > 0:
    muCtx.idStack.index -= 1

proc muPushClipRect*(muCtx: var MUContext = muGlobalContext, rect: MURect) =
  let last = muGetClipRect(muCtx)
  if muCtx.clipStack.index < MICROUI_CLIPSTACK_SIZE:
    muCtx.clipStack.items[muCtx.clipStack.index] = intersect(rect, last)
    muCtx.clipStack.index += 1

proc muPopClipRect*(muCtx: var MUContext = muGlobalContext) =
  if muCtx.clipStack.index > 0:
    muCtx.clipStack.index -= 1

proc muCheckClip*(muCtx: var MUContext = muGlobalContext, r: MURect): int =
  let cr = muGetClipRect(muCtx)
  if r.x > cr.x + cr.w or r.x + r.w < cr.x or r.y > cr.y + cr.h or r.y + r.h < cr.y:
    return ord(MUClip.All)
  if r.x >= cr.x and r.x + r.w <= cr.x + cr.w and r.y >= cr.y and r.y + r.h <= cr.y + cr.h:
    return 0
  return ord(MUClip.Partial)

proc muPoolUpdate*(muCtx: var MUContext = muGlobalContext, items: var openArray[MUPoolItem], idx: int) =
  items[idx].lastUpdate = muCtx.frame

proc muPoolInit*(muCtx: var MUContext = muGlobalContext, items: var openArray[MUPoolItem], id: uint): int =
  var n = -1
  let f = muCtx.frame
  for i in 0..<items.len:
    if items[i].lastUpdate < f:
      if n == -1:
        n = i
        break
  if n > -1:
    items[n].id = id
    muPoolUpdate(muCtx, items, n)
  result = n

proc muPoolGet*(muCtx: var MUContext = muGlobalContext, items: openArray[MUPoolItem], id: uint): int =
  for i in 0..<items.len:
    if items[i].id == id:
      return i
  return -1

proc muGetCurrentContainer*(muCtx: var MUContext = muGlobalContext): ptr MUContainer =
  if muCtx.containerStack.index > 0:
    result = muCtx.containerStack.items[muCtx.containerStack.index - 1]

proc muBringToFront*(muCtx: var MUContext = muGlobalContext, cnt: ptr MUContainer) =
  muCtx.lastZIndex += 1
  cnt.zIndex = muCtx.lastZIndex

proc getContainer(muCtx: var MUContext, id: uint, opt: int): ptr MUContainer =
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

proc muGetContainer*(muCtx: var MUContext = muGlobalContext, name: string): ptr MUContainer =
  let id = muGetIdStr(muCtx, name)
  return getContainer(muCtx, id, 0)

proc muPushCommand*(muCtx: var MUContext = muGlobalContext, cmd: MUBaseCommand) =
  let size = cmd.size
  if muCtx.commandList.index + size <= MICROUI_COMMANDLIST_SIZE:
    var dest = addr muCtx.commandList.items[muCtx.commandList.index]
    copyMem(dest, addr cmd, size)
    muCtx.commandList.index += size

proc muSetFocus*(muCtx: var MUContext = muGlobalContext, id: uint) =
  muCtx.focus = id
  muCtx.updatedFocus = true

proc muInputMouseMove*(muCtx: var MUContext = muGlobalContext, x, y: int) =
  muCtx.mousePos = vec2(x, y)

proc muInputMouseDown*(muCtx: var MUContext = muGlobalContext, x, y: int; btn: int) =
  muCtx.muInputMouseMove(x, y)
  muCtx.mouseDown = bitor[int](muCtx.mouseDown, btn)
  muCtx.mousePressed = bitor[int](muCtx.mousePressed, btn)

proc muInputMouseUp*(muCtx: var MUContext = muGlobalContext, x, y: int; btn: int) =
  muCtx.muInputMouseMove(x, y)
  muCtx.mouseDown = bitand[int](muCtx.mouseDown, bitnot(btn))

proc muInputScroll*(muCtx: var MUContext = muGlobalContext, x, y: int) =
  muCtx.scrollDelta.x += x
  muCtx.scrollDelta.y += y

proc muInputKeyDown*(muCtx: var MUContext = muGlobalContext, key: int) =
  muCtx.keyPressed = bitor[int](muCtx.keyPressed, key)
  muCtx.keyDown = bitor[int](muCtx.keyDown, key)

proc muInputKeyUp*(muCtx: var MUContext = muGlobalContext, key: int) =
  muCtx.keyDown = bitand[int](muCtx.keyDown, bitnot(key))

proc muInputText*(muCtx: var MUContext = muGlobalContext, text: string) =
  var i = 0
  while i < text.len and i < muCtx.inputText.len - 1:
    muCtx.inputText[i] = text[i]
    i += 1
  muCtx.inputText[i] = '\0'

iterator muCommands*(muCtx: var MUContext = muGlobalContext): ptr MUBaseCommand =
  var idx = 0
  while idx < muCtx.commandList.index:
    let cmd = cast[ptr MUBaseCommand](addr muCtx.commandList.items[idx])
    if cmd.kind == MUCommandType.Jump:
      idx = cast[int](cmd.destination) - cast[int](addr muCtx.commandList.items[0])
    else:
      yield cmd
      idx += cmd.size

proc muSetClip*(muCtx: var MUContext = muGlobalContext, rect: MURect) =
  var cmd: MUBaseCommand
  cmd.kind = MUCommandType.Clip
  cmd.size = sizeof(MUBaseCommand)
  cmd.clipRect = rect
  muPushCommand(muCtx, cmd)

proc muDrawRect*(muCtx: var MUContext = muGlobalContext, rect: MURect, color: MUColor) =
  var cmd: MUBaseCommand
  let r = intersect(rect, muGetClipRect(muCtx))
  if r.w > 0 and r.h > 0:
    cmd.kind = MUCommandType.Rect
    cmd.size = sizeof(MUBaseCommand)
    cmd.rectRect = r
    cmd.rectColor = color
    muPushCommand(muCtx, cmd)

proc muDrawBox*(muCtx: var MUContext = muGlobalContext, boxRect: MURect, color: MUColor) =
  muDrawRect(muCtx, rect(boxRect.x + 1, boxRect.y, boxRect.w - 2, 1), color)
  muDrawRect(muCtx, rect(boxRect.x + 1, boxRect.y + boxRect.h - 1, boxRect.w - 2, 1), color)
  muDrawRect(muCtx, rect(boxRect.x, boxRect.y, 1, boxRect.h), color)
  muDrawRect(muCtx, rect(boxRect.x + boxRect.w - 1, boxRect.y, 1, boxRect.h), color)

proc muDrawText*(muCtx: var MUContext = muGlobalContext, font: MUFont, str: string, pos: MUVec2, color: MUColor) =
  var cmd: MUBaseCommand
  let r = rect(pos.x, pos.y, muCtx.text_width(font, str, str.len), muCtx.text_height(font))
  let clipped = muCheckClip(muCtx, r)
  if clipped == ord(MUClip.All):
    return
  if clipped == ord(MUClip.Partial):
    muSetClip(muCtx, muGetClipRect(muCtx))
  cmd.kind = MUCommandType.Text
  cmd.size = sizeof(MUBaseCommand) + str.len
  cmd.textPos = pos
  cmd.textColor = color
  cmd.textFont = font
  muPushCommand(muCtx, cmd)
  if clipped != 0:
    muSetClip(muCtx, UnclippedRect)

proc muDrawIcon*(muCtx: var MUContext = muGlobalContext, id: int, rect: MURect, color: MUColor) =
  var cmd: MUBaseCommand
  let clipped = muCheckClip(muCtx, rect)
  if clipped == ord(MUClip.All):
    return
  if clipped == ord(MUClip.Partial):
    muSetClip(muCtx, muGetClipRect(muCtx))
  cmd.kind = MUCommandType.Icon
  cmd.size = sizeof(MUBaseCommand)
  cmd.iconId = id
  cmd.iconRect = rect
  cmd.iconColor = color
  muPushCommand(muCtx, cmd)
  if clipped != 0:
    muSetClip(muCtx, UnclippedRect)
  
proc getLayout(muCtx: var MUContext): ptr MULayout =
  if muCtx.layoutStack.index > 0:
    return addr muCtx.layoutStack.items[muCtx.layoutStack.index - 1]

proc muLayoutRow*(muCtx: var MUContext = muGlobalContext, items: int, widths: openArray[int], height: int) =
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

proc pushLayout(muCtx: var MUContext, body: MURect, scroll: MUVec2) =
  if muCtx.layoutStack.index < MICROUI_LAYOUTSTACK_SIZE:
    var layout = MULayout()
    layout.body = rect(body.x - scroll.x, body.y - scroll.y, body.w, body.h)
    layout.max = vec2(-0x1000000, -0x1000000)
    muCtx.layoutStack.items[muCtx.layoutStack.index] = layout
    muCtx.layoutStack.index += 1
    muLayoutRow(muCtx, 1, @[0], 0)

proc popContainer(muCtx: var MUContext) =
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

proc muLayoutWidth*(muCtx: var MUContext = muGlobalContext, width: int) =
  let layout = getLayout(muCtx)
  if layout != nil:
    layout.size.x = width

proc muLayoutHeight*(muCtx: var MUContext = muGlobalContext, height: int) =
  let layout = getLayout(muCtx)
  if layout != nil:
    layout.size.y = height

proc muLayoutNext*(muCtx: var MUContext = muGlobalContext): MURect =
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

proc muLayoutBeginColumn*(muCtx: var MUContext = muGlobalContext) =
  pushLayout(muCtx, muLayoutNext(muCtx), vec2(0, 0))

proc muLayoutEndColumn*(muCtx: var MUContext = muGlobalContext) =
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

proc muLayoutSetNext*(muCtx: var MUContext = muGlobalContext, r: MURect, relative: bool) =
  let layout = getLayout(muCtx)
  if layout != nil:
    layout.next = r
    layout.nextType = if relative: MULayoutType.Relative else: MULayoutType.Absolute

proc inHoverRoot(muCtx: var MUContext): bool =
  var i = muCtx.containerStack.index
  while i > 0:
    i -= 1
    if muCtx.containerStack.items[i] == muCtx.hoverRoot:
      return true
    if muCtx.containerStack.items[i].head != nil:
      break
  return false

proc muMouseOver*(muCtx: var MUContext = muGlobalContext, rect: MURect): bool =
  return overlaps(rect, muCtx.mousePos) and 
         overlaps(muGetClipRect(muCtx), muCtx.mousePos) and
         inHoverRoot(muCtx)

proc muUpdateControl*(muCtx: var MUContext = muGlobalContext, id: uint, rect: MURect, opt: int) =
  let mouseover = muMouseOver(muCtx, rect)
  
  if muCtx.focus == id:
    muCtx.updatedFocus = true
  if (opt and (1 shl ord(MUWindowOption.NoInteract))) != 0:
    return
  if mouseover and muCtx.mouseDown == 0:
    muCtx.hover = id
  
  if muCtx.focus == id:
    if muCtx.mousePressed != 0 and not mouseover:
      muSetFocus(muCtx, 0)
    if muCtx.mouseDown == 0 and (opt and (1 shl ord(MUWindowOption.HoldFocus))) == 0:
      muSetFocus(muCtx, 0)
  
  if muCtx.hover == id:
    if muCtx.mousePressed != 0:
      muSetFocus(muCtx, id)
    elif not mouseover:
      muCtx.hover = 0

proc drawFrame(muCtx: var MUContext, rect: MURect, colorid: int): void =
  muDrawRect(muCtx, rect, muCtx.style.colors[MUElementColor(colorid)])
  if colorid == ord(MUElementColor.ColorScrollBase) or
     colorid == ord(MUElementColor.ColorScrollThumb) or
     colorid == ord(MUElementColor.ColorTitleBackground):
    return
  if muCtx.style.colors[MUElementColor.ColorBorder].a != 0:
    muDrawBox(muCtx, expand(rect, 1), muCtx.style.colors[MUElementColor.ColorBorder])

proc muDrawControlFrame*(muCtx: var MUContext = muGlobalContext, id: uint, rect: MURect, colorid: int, opt: int) =
  if (opt and (1 shl ord(MUWindowOption.NoFrame))) != 0:
    return
  var cid = colorid
  cid += (if muCtx.focus == id: 2 elif muCtx.hover == id: 1 else: 0)
  drawFrame(muCtx, rect, cid)

proc muDrawControlText*(muCtx: var MUContext = muGlobalContext, str: string, rect: MURect, colorid: int, opt: int) =
  var pos: MUVec2
  let font = muCtx.style.font
  let tw = muCtx.text_width(font, str, str.len)
  muPushClipRect(muCtx, rect)
  pos.y = rect.y + (rect.h - muCtx.text_height(font)) div 2
  if (opt and (1 shl ord(MUWindowOption.AligneCenter))) != 0:
    pos.x = rect.x + (rect.w - tw) div 2
  elif (opt and (1 shl ord(MUWindowOption.AlignRight))) != 0:
    pos.x = rect.x + rect.w - tw - muCtx.style.padding
  else:
    pos.x = rect.x + muCtx.style.padding
  muDrawText(muCtx, font, str, pos, muCtx.style.colors[MUElementColor(colorid)])
  muPopClipRect(muCtx)

proc muText*(muCtx: var MUContext = muGlobalContext, text: string) =
  var p = 0
  let font = muCtx.style.font
  let color = muCtx.style.colors[MUElementColor.ColorText]
  muLayoutBeginColumn(muCtx)
  muLayoutRow(muCtx, 1, @[-1], muCtx.text_height(font))
  while p < text.len:
    var start = p
    var endPos = p
    var w = 0
    while p < text.len and text[p] != '\n':
      endPos = p
      p += 1
    let r = muLayoutNext(muCtx)
    muDrawText(muCtx, font, text[start..endPos], vec2(r.x, r.y), color)
    if p < text.len:
      p += 1
  muLayoutEndColumn(muCtx)

proc muLabel*(muCtx: var MUContext = muGlobalContext, text: string) =
  muDrawControlText(muCtx, text, muLayoutNext(muCtx), ord(MUElementColor.ColorText), 0)

proc muButton*(muCtx: var MUContext = muGlobalContext, label: string, icon: int = 0, opt: int = 0): int =
  var id: uint
  if label.len > 0:
    id = muGetIdStr(muCtx, label)
  else:
    id = muGetId(muCtx, cast[seq[byte]](@[byte(icon)]))
  let r = muLayoutNext(muCtx)
  muUpdateControl(muCtx, id, r, opt)
  if muCtx.mousePressed == ord(MUMouse.Left) and muCtx.focus == id:
    result = result or (1 shl ord(MUResult.Submit))
  muDrawControlFrame(muCtx, id, r, ord(MUElementColor.ColorButton), opt)
  if label.len > 0:
    muDrawControlText(muCtx, label, r, ord(MUElementColor.ColorText), opt)
  if icon != 0:
    muDrawIcon(muCtx, icon, r, muCtx.style.colors[MUElementColor.ColorText])

proc muCheckbox*(muCtx: var MUContext = muGlobalContext, label: string, state: var bool): int =
  var id = muGetId(muCtx, cast[seq[byte]](@[byte(if state: 1 else: 0)]))
  let r = muLayoutNext(muCtx)
  let box = rect(r.x, r.y, r.h, r.h)
  muUpdateControl(muCtx, id, r, 0)
  if muCtx.mousePressed == ord(MUMouse.Left) and muCtx.focus == id:
    result = result or (1 shl ord(MUResult.Change))
    state = not state
  muDrawControlFrame(muCtx, id, box, ord(MUElementColor.ColorBase), 0)
  if state:
    muDrawIcon(muCtx, ord(MUIcon.Check), box, muCtx.style.colors[MUElementColor.ColorText])
  let r2 = rect(r.x + box.w, r.y, r.w - box.w, r.h)
  muDrawControlText(muCtx, label, r2, ord(MUElementColor.ColorText), 0)

proc muTextbox*(muCtx: var MUContext = muGlobalContext, buf: var string, opt: int = 0): int =
  let id = muGetId(muCtx, cast[seq[byte]](buf))
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

proc muSlider*(muCtx: var MUContext = muGlobalContext, value: var float, low, high: float, step: float = 0, opt: int = 0): int =
  var v = value
  let id = muGetId(muCtx, cast[seq[byte]](@[byte(cast[int](addr value))]))
  let base = muLayoutNext(muCtx)
  
  muUpdateControl(muCtx, id, base, opt)
  
  if muCtx.focus == id and (muCtx.mouseDown or muCtx.mousePressed) == ord(MUMouse.Left):
    v = low + (muCtx.mousePos.x - base.x).float * (high - low) / base.w.float
  
  v = clamp(v, low, high)
  if value != v:
    result = result or (1 shl ord(MUResult.Change))
  value = v
  
  muDrawControlFrame(muCtx, id, base, ord(MUElementColor.ColorBase), opt)
  
  let w = muCtx.style.thumbSize
  let x = int((v - low) * (base.w - w).float / (high - low))
  let thumb = rect(base.x + x, base.y, w, base.h)
  muDrawControlFrame(muCtx, id, thumb, ord(MUElementColor.ColorButton), opt)

proc muHeader*(muCtx: var MUContext = muGlobalContext, label: string, opt: int = 0): bool =
  let id = muGetIdStr(muCtx, label)
  let idx = muPoolGet(muCtx, muCtx.treeNodePool, id)
  var active = idx >= 0
  var expanded = if (opt and (1 shl ord(MUWindowOption.Expanded))) != 0: not active else: active
  muLayoutRow(muCtx, 1, @[-1], 0)
  let r = muLayoutNext(muCtx)
  muUpdateControl(muCtx, id, r, 0)
  
  if muCtx.mousePressed == ord(MUMouse.Left) and muCtx.focus == id:
    active = not active
  
  if idx >= 0:
    if not active:
      muCtx.treeNodePool[idx].lastUpdate = -1
  elif active:
    discard muPoolInit(muCtx, muCtx.treeNodePool, id)
  
  drawFrame(muCtx, r, ord(MUElementColor.ColorTitleBackground))
  muDrawIcon(muCtx, if expanded: ord(MUIcon.Expanded) else: ord(MUIcon.Collapsed), 
             rect(r.x, r.y, r.h, r.h), muCtx.style.colors[MUElementColor.ColorText])
  let r2 = rect(r.x + r.h - muCtx.style.padding, r.y, r.w - (r.h - muCtx.style.padding), r.h)
  muDrawControlText(muCtx, label, r2, ord(MUElementColor.ColorText), 0)
  
  return expanded

proc muBeginTreenode*(muCtx: var MUContext = muGlobalContext, label: string, opt: int = 0): bool =
  result = muHeader(muCtx, label, opt)
  if result:
    let layout = getLayout(muCtx)
    if layout != nil:
      layout.indent += muCtx.style.indent
    muPushIdStr(muCtx, label)

proc muEndTreenode*(muCtx: var MUContext = muGlobalContext) =
  let layout = getLayout(muCtx)
  if layout != nil:
    layout.indent -= muCtx.style.indent
  muPopId(muCtx)

proc beginRootContainer(muCtx: var MUContext, cnt: ptr MUContainer) =
  if muCtx.containerStack.index < MICROUI_CONTAINERSTACK_SIZE:
    muCtx.containerStack.items[muCtx.containerStack.index] = cnt
    muCtx.containerStack.index += 1
  if muCtx.rootList.index < MICROUI_ROOTLIST_SIZE:
    muCtx.rootList.items[muCtx.rootList.index] = cnt
    muCtx.rootList.index += 1
  if overlaps(cnt.rect, muCtx.mousePos):
    if muCtx.nextHoverRoot == nil or cnt.zIndex > muCtx.nextHoverRoot.zIndex:
      muCtx.nextHoverRoot = cnt
  muCtx.clipStack.items[muCtx.clipStack.index] = UnclippedRect
  muCtx.clipStack.index += 1

proc endRootContainer(muCtx: var MUContext) =
  muPopClipRect(muCtx)
  popContainer(muCtx)

proc pushContainerBody(muCtx: var MUContext, cnt: ptr MUContainer, body: MURect, opt: int) =
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
    muPopClipRect(muCtx)
  pushLayout(muCtx, expand(bodyRect, -muCtx.style.padding), cnt.scroll)
  cnt.body = bodyRect

proc muBeginWindow*(muCtx: var MUContext = muGlobalContext, title: string, rect: MURect, opt: int = 0): bool =
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
    let titleRect = rect(cnt.rect.x, cnt.rect.y, cnt.rect.w, muCtx.style.titleHeight)
    drawFrame(muCtx, titleRect, ord(MUElementColor.ColorTitleBackground))
    muDrawControlText(muCtx, title, titleRect, ord(MUElementColor.ColorTitleText), 0)
    bodyRect.y += muCtx.style.titleHeight
    bodyRect.h -= muCtx.style.titleHeight
  
  pushContainerBody(muCtx, cnt, bodyRect, opt)
  muPushClipRect(muCtx, cnt.body)
  return true

proc muEndWindow*(muCtx: var MUContext = muGlobalContext) =
  muPopClipRect(muCtx)
  endRootContainer(muCtx)

proc muOpenPopup*(muCtx: var MUContext = muGlobalContext, name: string) =
  let cnt = muGetContainer(muCtx, name)
  muCtx.hoverRoot = cnt
  muCtx.nextHoverRoot = cnt
  cnt.rect = rect(muCtx.mousePos.x, muCtx.mousePos.y, 1, 1)
  cnt.open = 1
  muBringToFront(muCtx, cnt)

proc muBeginPopup*(muCtx: var MUContext = muGlobalContext, name: string): bool =
  let opt = (1 shl ord(MUWindowOption.Popup)) or (1 shl ord(MUWindowOption.AutoSize)) or (1 shl ord(MUWindowOption.NoResive)) or (1 shl ord(MUWindowOption.NoScroll)) or (1 shl ord(MUWindowOption.NoTitle)) or (1 shl ord(MUWindowOption.Closed))
  return muBeginWindow(muCtx, name, rect(0, 0, 0, 0), opt)

proc muEndPopup*(muCtx: var MUContext = muGlobalContext) =
  muEndWindow(muCtx)

proc muBeginPanel*(muCtx: var MUContext = muGlobalContext, name: string, opt: int = 0) =
  muPushIdStr(muCtx, name)
  let cnt = getContainer(muCtx, muCtx.lastId, opt)
  cnt.rect = muLayoutNext(muCtx)
  if (opt and (1 shl ord(MUWindowOption.NoFrame))) == 0:
    drawFrame(muCtx, cnt.rect, ord(MUElementColor.ColorPanelBackground))
  muCtx.containerStack.items[muCtx.containerStack.index] = cnt
  muCtx.containerStack.index += 1
  pushContainerBody(muCtx, cnt, cnt.rect, opt)
  muPushClipRect(muCtx, cnt.body)

proc muEndPanel*(muCtx: var MUContext = muGlobalContext) =
  muPopClipRect(muCtx)
  popContainer(muCtx)

proc muInit*(muCtx: var MUContext = muGlobalContext) =
  muCtx = MUContext()
  muCtx.style = DefaultStyle
  muCtx.styleRef = addr muCtx.style
  muCtx.draw_frame = drawFrame

proc muBegin*(muCtx: var MUContext = muGlobalContext) =
  muCtx.commandList.index = 0
  muCtx.rootList.index = 0
  muCtx.scrollTarget = nil
  muCtx.hoverRoot = muCtx.nextHoverRoot
  muCtx.mouseDelta.x = muCtx.mousePos.x - muCtx.lastMousePos.x
  muCtx.mouseDelta.y = muCtx.mousePos.y - muCtx.lastMousePos.y
  muCtx.frame += 1

proc muEnd*(muCtx: var MUContext = muGlobalContext) =
  if muCtx.scrollTarget != nil:
    muCtx.scrollTarget.scroll.x += muCtx.scrollDelta.x
    muCtx.scrollTarget.scroll.y += muCtx.scrollDelta.y
  
  if not muCtx.updatedFocus:
    muCtx.focus = 0
  
  muCtx.updatedFocus = false
  
  if muCtx.mousePressed != 0 and muCtx.nextHoverRoot != nil and 
     muCtx.nextHoverRoot.zIndex < muCtx.lastZIndex and 
     muCtx.nextHoverRoot.zIndex >= 0:
    muBringToFront(muCtx, muCtx.nextHoverRoot)
  
  muCtx.keyPressed = 0
  muCtx.inputText[0] = '\0'
  muCtx.mousePressed = 0
  muCtx.scrollDelta = vec2(0, 0)
  muCtx.lastMousePos = muCtx.mousePos
