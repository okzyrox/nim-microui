import std/[strformat, unicode]

import glfw

import ../src/microui/ui
import ../src/microui/renderer/renderer_gl

var
  muCtx: ref MUContext

## UI state
var
  logbuf: string = ""
  logbufUpdated = false
  logInput: string = ""
  bg = [90.0, 95.0, 100.0]
  lastMousePos = vec2(0, 0)
  checks = [true, false, true]

proc writeLog(text: string) =
  if logbuf.len > 0:
    logbuf.add("\n")
  logbuf.add(text)
  logbufUpdated = true

proc textWidth(font: MUFont, text: string, len: int): int =
  getTextWidth(text, len)

proc uint8Slider(value: var byte): int =
  var tmp = value.float
  muPushIdStr(muCtx, $cast[int](addr value))
  let res = muSlider(muCtx, tmp, 0, 255, 0, 0)
  value = tmp.byte
  muPopId(muCtx)
  return res

proc testWindow() =
  muWindow(muCtx, "Demo Window", rect(40, 40, 300, 450)):
    let win = muGetCurrentContainer(muCtx)
    win.rect.w = max(win.rect.w, 240)
    win.rect.h = max(win.rect.h, 300)
    
    if muHeader(muCtx, "Window Info"):
      muLayoutRow(muCtx, 2, @[54, -1], 0)
      muLabel(muCtx, "Position:")
      muLabel(muCtx, $win.rect.x & ", " & $win.rect.y)
      muLabel(muCtx, "Size:")
      muLabel(muCtx, $win.rect.w & ", " & $win.rect.h)
    
    if muHeader(muCtx, "Test Buttons", (1 shl ord(MUWindowOption.Expanded))):
      muLayoutRow(muCtx, 3, @[86, -110, -1], 0)
      muLabel(muCtx, "Test buttons 1:")
      if muButton(muCtx, "Button 1"):
        writeLog("Pressed button 1")
      if muButton(muCtx, "Button 2"):
        writeLog("Pressed button 2")
      muLabel(muCtx, "Test buttons 2:")
      if muButton(muCtx, "Button 3"):
        writeLog("Pressed button 3")
      if muButton(muCtx, "Popup"):
        muOpenPopup(muCtx, "Test Popup")
      if muBeginPopup(muCtx, "Test Popup"):
        discard muButton(muCtx, "Hello")
        discard muButton(muCtx, "World")
        muEndPopup(muCtx)
    
    if muHeader(muCtx, "Tree and Text", (1 shl ord(MUWindowOption.Expanded))):
      muLayoutRow(muCtx, 2, @[140, -1], 0)
      muLayoutColumn(muCtx):
        muTreenode(muCtx, "Test 1"):
          muTreenode(muCtx, "Test 1a"):
            muLabel(muCtx, "Hello")
            muLabel(muCtx, "world")
          muTreenode(muCtx, "Test 1b"):
            if muButton(muCtx, "Button 1"):
              writeLog("Pressed button 1")
            if muButton(muCtx, "Button 2"):
              writeLog("Pressed button 2")

        muTreenode(muCtx, "Test 2"):
          muLayoutRow(muCtx, 2, @[54, 54], 0)
          if muButton(muCtx, "Button 3"):
            writeLog("Pressed button 3")
          if muButton(muCtx, "Button 4"):
            writeLog("Pressed button 4")
          if muButton(muCtx, "Button 5"):
            writeLog("Pressed button 5")
          if muButton(muCtx, "Button 6"):
            writeLog("Pressed button 6")

        muTreenode(muCtx, "Test 3"):
          discard muCheckbox(muCtx, "Checkbox 1", checks[0])
          discard muCheckbox(muCtx, "Checkbox 2", checks[1])
          discard muCheckbox(muCtx, "Checkbox 3", checks[2])
        
      muLayoutColumn(muCtx):
        muLayoutRow(muCtx, 1, @[-1], 0)
        let txt = "Lorem ipsum dolor sit amet, consectetur adipiscing " &
          "elit. Maecenas lacinia, sem eu lacinia molestie, mi risus faucibus " &
          "ipsum, eu varius magna felis a nulla."
        muText(muCtx, txt)

    if muHeader(muCtx, "Background Color", (1 shl ord(MUWindowOption.Expanded))):
      muLayoutRow(muCtx, 2, @[-78, -1], 74)
      muLayoutColumn(muCtx):
        muLayoutRow(muCtx, 2, @[46, -1], 0)
        muLabel(muCtx, "Red:")
        discard muSlider(muCtx, bg[0], 0, 255)
        muLabel(muCtx, "Green:")
        discard muSlider(muCtx, bg[1], 0, 255)
        muLabel(muCtx, "Blue:")
        discard muSlider(muCtx, bg[2], 0, 255)

      let r = muLayoutNext(muCtx)
      muDrawRect(muCtx, r, color(bg[0].int, bg[1].int, bg[2].int, 255))
      let buf = &"#{bg[0].int:02X}{bg[1].int:02X}{bg[2].int:02X}"
      muDrawControlText(muCtx, buf, r, ord(MUElementColor.ColorText), ord(MUWindowOption.AlignCenter))

proc logWindow() =
  muWindow(muCtx, "Log Window", rect(350, 40, 300, 200)):
    muLayoutRow(muCtx, 1, @[-1], -25)
    var panel: ptr MUContainer
    muPanel(muCtx, "Log Output"):
      panel = muGetCurrentContainer(muCtx)
      muLayoutRow(muCtx, 1, @[-1], -1)
      muText(muCtx, logbuf)

    if logbufUpdated:
      panel.scroll.y = panel.contentSize.y
      logbufUpdated = false
    
    var submitted = false
    muLayoutRow(muCtx, 2, @[-70, -1], 0)
    if (muTextbox(muCtx, logInput) and (1 shl ord(MUResult.Submit))) != 0:
      muSetFocus(muCtx, muCtx.lastId)
      submitted = true
    if muButton(muCtx, "Submit"):
      submitted = true
    if submitted:
      writeLog(logInput)
      logInput = ""

proc styleWindow() =
  let labels = [
    "text:",
    "border:",
    "windowbg:",
    "titlebg:",
    "titletext:",
    "panelbg:",
    "button:",
    "buttonhover:",
    "buttonfocus:",
    "base:",
    "basehover:",
    "basefocus:",
    "scrollbase:",
    "scrollthumb:"
  ]

  muWindow(muCtx, "Style Editor", rect(350, 250, 300, 240)):
    let sw = int(muGetCurrentContainer(muCtx).body.w.float * 0.14)
    muLayoutRow(muCtx, 6, @[80, sw, sw, sw, sw, -1], 0)
    var i = 0
    while i < labels.len:
      let idx = MUElementColor(i)
      muLabel(muCtx, labels[i])
      discard uint8Slider(muCtx.style.colors[idx].r)
      discard uint8Slider(muCtx.style.colors[idx].g)
      discard uint8Slider(muCtx.style.colors[idx].b)
      discard uint8Slider(muCtx.style.colors[idx].a)
      muDrawRect(muCtx, muLayoutNext(muCtx), muCtx.style.colors[idx])
      i += 1

proc processFrame() =
  mu(muCtx):
    styleWindow()
    testWindow()
    logWindow()


# glfw overhead
proc cursor_pos_cb(window: Window, pos: tuple[x,y: float64]) =
  let v = vec2(pos.x.int, pos.y.int)
  muInputMouseMove(muCtx, v.x, v.y)
  lastMousePos = v

proc mouse_button_cb(window: Window, b: MouseButton, pressed: bool, mods: set[ModifierKey]) =
  if b == mbLeft:
    if pressed:
      muInputMouseDown(muCtx, lastMousePos.x, lastMousePos.y, MUMouse.Left)
    else:
      muInputMouseUp(muCtx, lastMousePos.x, lastMousePos.y, MUMouse.Left)

proc scroll_cb(window: Window, offset: tuple[x, y: float64]) =
  muInputScroll(muCtx, 0, int(offset.y * -30.0))

proc key_cb(window: Window, key: Key, scanCode: int32, action: KeyAction, mods: set[ModifierKey]) =
  var mapped = 0
  case key
  of keyLeftShift, keyRightShift:
    mapped = ord(MUControlKey.Shift)
  of keyLeftControl, keyRightControl:
    mapped = ord(MUControlKey.Ctrl)
  of keyLeftAlt, keyRightAlt:
    mapped = ord(MUControlKey.Alt)
  of keyBackspace:
    mapped = ord(MUControlKey.Backspace)
  of keyEnter:
    mapped = ord(MUControlKey.Return)
  else:
    discard
  if mapped != 0:
    if action == kaDown:
      muInputKeyDown(muCtx, mapped)
    elif action == kaUp:
      muInputKeyUp(muCtx, mapped)

proc char_cb(window: Window, codePoint: Rune) =
  let s = $codePoint
  if s.len > 0:
    muInputText(muCtx, s)

proc main() =
  glfw.initialize()
  
  var cfg = DefaultOpenglWindowConfig
  cfg.size = (w: 1050, h: 750)
  cfg.title = "Nim microui Example"
  cfg.resizable = false
  cfg.version = glv21
  
  let window = newWindow(cfg)

  window.cursorPositionCb = cursor_pos_cb
  window.mouseButtonCb = mouse_button_cb
  window.scrollCb = scroll_cb
  window.keyCb = key_cb
  window.charCb = char_cb
  
  glfw.swapInterval(1)
  
  initRenderer()
  
  muInit(muCtx)
  muCtx.text_width = textWidth
  
  while not glfw.shouldClose(window):
    let (w, h) = glfw.framebufferSize(window)
    setSize(w, h)
    
    glfw.pollEvents()
    
    let (mx, my) = glfw.cursorPos(window)
    muInputMouseMove(muCtx, mx.int, my.int)
    
    processFrame()
    clear(color(bg[0].int, bg[1].int, bg[2].int, 255))
    
    handleMuEvents(muCtx)
    
    present()
    glfw.swapBuffers(window)
  
  glfw.terminate()

when isMainModule:
  main()
