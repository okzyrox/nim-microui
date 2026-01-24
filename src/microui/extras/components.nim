## nim-microui - Extra UI Components
## License: MIT

import ../ui
import ./utils

import std/[browsers]

## Extra/MenuBar
## A menu bar that runs across the top of the Window or a specified width (if running without a Window)
const MENUBAR_HEIGHT = 26

type MenuBarContext = object
  barRect: MURect
  barX: int
  isRootContainer: bool

var menuBarStack: seq[MenuBarContext] = @[]
var activeMenuTab: uint = 0

proc muBeginMenuBar*(muCtx: var ref MUContext, x: int = 0, y: int = 0, width: int = 0): bool =
  var barRect: MURect
  var isRoot = false
  let layout = muCtx.getLayout()
  
  if layout != nil:
    muCtx.muLayoutRow(1, @[-1], MENUBAR_HEIGHT)
    barRect = muCtx.muLayoutNext()
  else:
    let w = if width > 0: width else: 10000
    barRect = rect(x, y, w, MENUBAR_HEIGHT)
    isRoot = true
    
    let id = muCtx.muGetIdStr("##toplevel_menubar")
    let cnt = muCtx.muGetContainer("##toplevel_menubar")
    cnt.rect = barRect
    cnt.open = 1
    
    muCtx.muPushIdStr("##toplevel_menubar")
    if muCtx.containerStack.index < MICROUI_CONTAINERSTACK_SIZE:
      muCtx.containerStack.items[muCtx.containerStack.index] = cnt
      muCtx.containerStack.index += 1
    if muCtx.rootList.index < MICROUI_ROOTLIST_SIZE:
      muCtx.rootList.items[muCtx.rootList.index] = cnt
      muCtx.rootList.index += 1
    
    cnt.head = muCtx.pushJump(nil)
    if overlaps(cnt.rect, muCtx.mousePos):
      if muCtx.nextHoverRoot == nil or cnt.zIndex > muCtx.nextHoverRoot.zIndex:
        muCtx.nextHoverRoot = cnt
    
    muCtx.pushLayout(barRect, vec2(0, 0))
  
  muCtx.muDrawRect(barRect, muCtx.style.colors[MUElementColor.ColorMenuBar])
  
  menuBarStack.add(MenuBarContext(
    barRect: barRect,
    barX: barRect.x,
    isRootContainer: isRoot
  ))
  
  muCtx.muPushClipRect(barRect)
  
  return true

proc muBeginMenuBar*(x: int = 0, y: int = 0, width: int = 0): bool =
  assertGlobalContext()

  return muBeginMenuBar(muGlobalContext, x, y, width)

proc muEndMenuBar*(muCtx: var ref MUContext) =
  if menuBarStack.len > 0:
    let barCtx = menuBarStack[menuBarStack.len - 1]
    menuBarStack.setLen(menuBarStack.len - 1)
    
    if barCtx.isRootContainer:
      if muCtx.layoutStack.index > 0:
        muCtx.layoutStack.index -= 1
      
      let cnt = muCtx.muGetCurrentContainer()
      if cnt != nil:
        cnt.tail = muCtx.pushJump(nil)
        if cnt.head != nil:
          cnt.head.destination = cast[pointer](addr muCtx.commandList.items[muCtx.commandList.index])
      
      if muCtx.containerStack.index > 0:
        muCtx.containerStack.index -= 1
      
      muCtx.muPopId()
  
  muCtx.muPopClipRect()

proc muEndMenuBar*() =
  assertGlobalContext()

  muEndMenuBar(muGlobalContext)

template muMenuBar*(muCtx: var ref MUContext, body: untyped) =
  if muBeginMenuBar(muCtx):
    try:
      body
    finally:
      muEndMenuBar(muCtx)

template muMenuBar*(body: untyped) =
  assertGlobalContext()
  
  muMenuBar(muGlobalContext, body)

template muMenuBar*(muCtx: var ref MUContext, x, y, width: int, body: untyped) =
  if muBeginMenuBar(muCtx, x, y, width):
    try:
      body
    finally:
      muEndMenuBar(muCtx)
  
template muMenuBar*(x, y, width: int, body: untyped) =
  assertGlobalContext()

  muMenuBar(muGlobalContext, x, y, width, body)
    
## Extra/MenuBarTab
# A menu bar Tab for usage with a MenuBar

proc muBeginMenuBarTab*(muCtx: var ref MUContext, label: string): bool =
  if menuBarStack.len == 0:
    return false
  
  var barCtx = menuBarStack[menuBarStack.len - 1]
  let font = muCtx.style.font
  let tw = muCtx.text_width(font, label, label.len)
  let tabWidth = tw + muCtx.style.padding * 4
  
  let id = muCtx.muGetIdStr(label)
  let r = rect(barCtx.barX, barCtx.barRect.y, tabWidth, MENUBAR_HEIGHT)
  
  barCtx.barX += tabWidth
  menuBarStack[menuBarStack.len - 1] = barCtx
  
  muCtx.muUpdateControl(id, r, 0)
  
  var colorId = ord(MUElementColor.ColorMenuBar)
  if muCtx.hover == id:
    colorId = ord(MUElementColor.ColorButtonHover)
  if activeMenuTab == id:
    colorId = ord(MUElementColor.ColorButtonFocus)
  
  muCtx.muDrawRect(r, muCtx.style.colors[MUElementColor(colorId)])
  muCtx.muDrawControlText(label, r, ord(MUElementColor.ColorText), 1 shl ord(MUWindowOption.AlignCenter))
  
  if muCtx.isPressed(MUMouse.Left) and muCtx.hover == id:
    if activeMenuTab == id:
      activeMenuTab = 0
    else:
      let popupName = "##menubar_" & label
      muCtx.muOpenPopup(popupName)
      activeMenuTab = id
  
  if activeMenuTab == id:
    let popupName = "##menubar_" & label
    if muCtx.muBeginPopup(popupName):
      let cnt = muCtx.muGetCurrentContainer()
      cnt.rect.x = r.x
      cnt.rect.y = r.y + r.h
      
      if muCtx.isAnyMousePressed and muCtx.hoverRoot != cnt:
        activeMenuTab = 0
      return true
    else:
      activeMenuTab = 0
  
  return false

proc muBeginMenuBarTab*(label: string): bool =
  assertGlobalContext()

  return muBeginMenuBarTab(muGlobalContext, label)

proc muEndMenuBarTab*(muCtx: var ref MUContext) =
  muCtx.muEndPopup()

proc muEndMenuBarTab*() =
  assertGlobalContext()

  muEndMenuBarTab(muGlobalContext)

template muMenuBarTab*(muCtx: var ref MUContext, label: string, body: untyped) =
  if muBeginMenuBarTab(muCtx, label):
    try:
      body
    finally:
      muEndMenuBarTab(muCtx)

template muMenuBarTab*(label: string, body: untyped) =
  assertGlobalContext()

  muMenuBarTab(muGlobalContext, label, body)

## Extras/Separator
## Horizontal seperator line

proc muSeparator*(muCtx: var ref MUContext) =
  let r = muCtx.muLayoutNext()
  let lineRect = rect(r.x, r.y + (r.h - 1) div 2, r.w, 1)
  muCtx.muDrawRect(lineRect, muCtx.style.colors[MUElementColor.ColorSeparator])

proc muSeparator*() =
  assertGlobalContext()

  muSeparator(muGlobalContext)

## Extras/TextSeparator
## A text label with horizontal lines on either side
proc muTextSeparator*(muCtx: var ref MUContext, text: string) =
  let r = muCtx.muLayoutNext()
  let font = muCtx.style.font
  let tw = muCtx.text_width(font, text, text.len)
  let th = muCtx.text_height(font)
  
  let lineHeight = 1
  let lineY = r.y + (r.h - lineHeight) div 2
  let pad = 5
  
  let leftRect = rect(r.x, lineY, (r.w - tw) div 2 - pad, lineHeight)
  let rightRect = rect(r.x + (r.w + tw) div 2 + pad, lineY, (r.w - tw) div 2 - pad, lineHeight)
  
  muCtx.muDrawRect(leftRect, muCtx.style.colors[MUElementColor.ColorSeparator])
  muCtx.muDrawRect(rightRect, muCtx.style.colors[MUElementColor.ColorSeparator])
  
  let textPos = vec2(r.x + (r.w - tw) div 2, r.y + (r.h - th) div 2)
  muCtx.muDrawText(font, text, textPos, muCtx.style.colors[MUElementColor.ColorText])

proc muTextSeparator*(text: string) =
  assertGlobalContext()

  muTextSeparator(muGlobalContext, text)

## Extras/TextLink
## A piece of text that opens a URL when clicked

proc muTextLink*(muCtx: var ref MUContext, text: string, url: string) =
  let font = muCtx.style.font
  let tw = muCtx.text_width(font, text, text.len)
  let th = muCtx.text_height(font)
  
  let r = muCtx.muLayoutNext()
  let textRect = rect(r.x + muCtx.style.padding, r.y, tw, th)
  
  let id = muCtx.muGetIdStr(text & url)
  muCtx.muUpdateControl(id, textRect, 0)
  
  var color = muCtx.style.colors[MUElementColor.ColorTextLink]
  if muCtx.hover == id:
    color.r = min(255, color.r.int + 30).byte
    color.g = min(255, color.g.int + 30).byte
    color.b = min(255, color.b.int + 30).byte
  
  let pos = vec2(textRect.x, textRect.y + (r.h - th) div 2)
  muCtx.muDrawText(font, text, pos, color)
  
  let underlineY = pos.y + th - 1
  muCtx.muDrawRect(rect(textRect.x, underlineY, tw, 1), color)
  
  if muCtx.isPressed(MUMouse.Left) and muCtx.focus == id:
    openDefaultBrowser(url)

proc muTextLink*(text: string, url: string) =
  assertGlobalContext()

  muTextLink(muGlobalContext, text, url)


## Extras/Text (Color option)
## Base text compontent with color argument

proc muText*(muCtx: var ref MUContext, text: string, color: MUColor) =
  var p = 0
  let font = muCtx.style.font
  let color = color
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

proc muText*(text: string, color: MUColor) =
  assertGlobalContext()

  muText(muGlobalContext, text, color)

## Extras/Window (bool)
## A window that is visible (open/closed) by a boolean

proc muBeginWindow*(muCtx: var ref MUContext, title: string, rect: MURect, isOpen: var bool, opt: int = 0): bool =
  if not isOpen:
    return false
  
  let cnt = muCtx.muGetContainer(title)
  if cnt != nil and cnt.open == 0:
    cnt.open = 1
  
  if not muCtx.muBeginWindow(title, rect, opt):
    isOpen = false
    return false
  
  return true

proc muBeginWindow*(title: string, rect: MURect, isOpen: var bool, opt: int = 0): bool =
  assertGlobalContext()

  return muBeginWindow(muGlobalContext, title, rect, isOpen, opt)

proc muEndWindow*(muCtx: var ref MUContext, title: string, isOpen: var bool) =
  let cnt = muCtx.muGetCurrentContainer()
  muCtx.muEndWindow()
  if cnt != nil and cnt.open == 0:
    isOpen = false

proc muEndWindow*(title: string, isOpen: var bool) =
  assertGlobalContext()

  muEndWindow(muGlobalContext, title, isOpen)

template muWindow*(muCtx: var ref MUContext, title: string, rect: MURect, isOpen: var bool, body: untyped) =
  if muBeginWindow(muCtx, title, rect, isOpen, 0):
    try:
      body
    finally:
      muEndWindow(muCtx, title, isOpen)

template muWindow*(muCtx: var ref MUContext, title: string, rect: MURect, isOpen: var bool, opt: int, body: untyped) =
  if muBeginWindow(muCtx, title, rect, isOpen, opt):
    try:
      body
    finally:
      muEndWindow(muCtx, title, isOpen)

template muWindow*(title: string, rect: MURect, isOpen: var bool, body: untyped) =
  assertGlobalContext()

  muWindow(muGlobalContext, title, rect, isOpen, body)

template muWindow*(title: string, rect: MURect, isOpen: var bool, opt: int, body: untyped) =
  assertGlobalContext()
  
  muWindow(muGlobalContext, title, rect, isOpen, opt, body)