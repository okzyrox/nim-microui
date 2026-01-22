import ../src/microui/ui
import renderer
import glfw
import glad/gl

var
  muCtx: MUContext
  logbuf: string = ""
  logbufUpdated = false
  bg = [90.0, 95.0, 100.0]
  lastMouseDown = false

proc writeLog(text: string) =
  if logbuf.len > 0:
    logbuf.add("\n")
  logbuf.add(text)
  logbufUpdated = true

proc textWidth(font: MUFont, text: string, len: int): int =
  getTextWidth(text, len)

proc textHeight(font: MUFont): int =
  return 18

proc testWindow() =
  if muBeginWindow(muCtx, "Demo Window", rect(40, 40, 300, 450)):
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
      if muButton(muCtx, "Button 1") != 0:
        writeLog("Pressed button 1")
      if muButton(muCtx, "Button 2") != 0:
        writeLog("Pressed button 2")
      muLabel(muCtx, "Test buttons 2:")
      if muButton(muCtx, "Button 3") != 0:
        writeLog("Pressed button 3")
      if muButton(muCtx, "Popup") != 0:
        muOpenPopup(muCtx, "Test Popup")
      if muBeginPopup(muCtx, "Test Popup"):
        discard muButton(muCtx, "Hello")
        discard muButton(muCtx, "World")
        muEndPopup(muCtx)
    
    if muHeader(muCtx, "Tree and Text", (1 shl ord(MUWindowOption.Expanded))):
      muLayoutRow(muCtx, 2, @[140, -1], 0)
      muLayoutBeginColumn(muCtx)
      if muBeginTreenode(muCtx, "Test 1"):
        if muBeginTreenode(muCtx, "Test 1a"):
          muLabel(muCtx, "Hello")
          muLabel(muCtx, "world")
          muEndTreenode(muCtx)
        if muBeginTreenode(muCtx, "Test 1b"):
          if muButton(muCtx, "Button 1") != 0:
            writeLog("Pressed button 1")
          if muButton(muCtx, "Button 2") != 0:
            writeLog("Pressed button 2")
          muEndTreenode(muCtx)
        muEndTreenode(muCtx)
      muLayoutEndColumn(muCtx)
      
      muLayoutBeginColumn(muCtx)
      muLayoutRow(muCtx, 1, @[-1], 0)
      muText(muCtx, "Lorem ipsum dolor sit amet, consectetur adipiscing elit.")
      muLayoutEndColumn(muCtx)
    
    muEndWindow(muCtx)

proc logWindow() =
  if muBeginWindow(muCtx, "Log Window", rect(350, 40, 300, 200)):
    muLayoutRow(muCtx, 1, @[-1], -25)
    muBeginPanel(muCtx, "Log Output")
    let panel = muGetCurrentContainer(muCtx)
    muLayoutRow(muCtx, 1, @[-1], -1)
    muText(muCtx, logbuf)
    muEndPanel(muCtx)
    if logbufUpdated:
      panel.scroll.y = panel.contentSize.y
      logbufUpdated = false
    
    var buf = ""
    var submitted = false
    muLayoutRow(muCtx, 2, @[-70, -1], 0)
    if (muTextbox(muCtx, buf) and (1 shl ord(MUResult.Submit))) != 0:
      muSetFocus(muCtx, muCtx.lastId)
      submitted = true
    if muButton(muCtx, "Submit") != 0:
      submitted = true
    if submitted:
      writeLog(buf)
      buf = ""
    
    muEndWindow(muCtx)

proc processFrame() =
  muBegin(muCtx)
  testWindow()
  logWindow()
  muEnd(muCtx)

proc main() =
  glfw.initialize()
  
  var cfg = DefaultOpenglWindowConfig
  cfg.size = (w: 800, h: 600)
  cfg.title = "MicroUI Demo"
  cfg.resizable = true
  cfg.version = glv21
  
  let window = newWindow(cfg)
  
  if not gladLoadGL(getProcAddress):
    quit("Error initialising OpenGL")
  
  glfw.swapInterval(1)
  
  initRenderer()
  
  muInit(muCtx)
  muCtx.text_width = textWidth
  muCtx.text_height = textHeight
  
  while not glfw.shouldClose(window):
    let (w, h) = glfw.framebufferSize(window)
    setSize(w, h)
    
    glfw.pollEvents()
    
    let (mx, my) = glfw.cursorPos(window)
    muInputMouseMove(muCtx, mx.int, my.int)
    
    # let isMouseDown = glfw.getMouseButton(window, mbLeft) == Press
    # if isMouseDown and not lastMouseDown:
    #   muInputMouseDown(muCtx, mx.int, my.int, ord(MUMouse.Left))
    # elif not isMouseDown and lastMouseDown:
    #   muInputMouseUp(muCtx, mx.int, my.int, ord(MUMouse.Left))
    # lastMouseDown = isMouseDown
    
    processFrame()
    
    clear(color(bg[0].int, bg[1].int, bg[2].int, 255))
    
    for cmd in muCommands(muCtx):
      case cmd.kind
      of MUCommandType.Text:
        var str = ""
        let textPtr = cast[ptr UncheckedArray[char]](addr cmd.textStr)
        var i = 0
        while textPtr[i] != '\0':
          str.add(textPtr[i])
          i += 1
        drawText(str, cmd.textPos, cmd.textColor)
      of MUCommandType.Rect:
        drawRect(cmd.rectRect, cmd.rectColor)
      of MUCommandType.Icon:
        drawIcon(cmd.iconId, cmd.iconRect, cmd.iconColor)
      of MUCommandType.Clip:
        setClipRect(cmd.clipRect)
      else:
        discard
    
    present()
    glfw.swapBuffers(window)
  
  glfw.terminate()

when isMainModule:
  main()
