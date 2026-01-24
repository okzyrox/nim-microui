import std/[unicode]

import glfw

import ../../src/microui
import ../../src/microui/renderer/opengl21

const
  WINDOW_WIDTH = 600
  WINDOW_HEIGHT = 400
  CLEAR_COLOR = color(90, 95, 100, 255)

## UI state
var
  muCtx: ref MUContext

## Renderer callback
proc textWidth(font: MUFont, text: string, len: int): int =
  getTextWidth(text, len)

## Frame contents
proc processFrame() =
  mu:
    when defined(extras):
      menuBar()
    
    muWindow("Minimal Window", rect(20, 20, 200, 100)):
      muText("Hello, world!")

# GLFW overhead
proc cursor_pos_cb(window: Window, pos: tuple[x, y: float64]) =
  let v = vec2(pos.x.int, pos.y.int)
  muInputMouseMove(muCtx, v.x, v.y)

proc mouse_button_cb(window: Window, b: MouseButton, pressed: bool, mods: set[ModifierKey]) =
  if b == mbLeft:
    if pressed:
      muInputMouseDown(muCtx, MUMouse.Left)
    else:
      muInputMouseUp(muCtx, MUMouse.Left)

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
  of keyEscape:
    window.shouldClose = true
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
  cfg.size = (w: WINDOW_WIDTH, h: WINDOW_HEIGHT)
  cfg.title = "Nim microui Example"
  cfg.resizable = false
  cfg.version = glv21
  
  let window = newWindow(cfg)

  ## GLFW window callbacks
  ## without them, microui has no idea of user input
  window.cursorPositionCb = cursor_pos_cb
  window.mouseButtonCb = mouse_button_cb
  window.scrollCb = scroll_cb
  window.keyCb = key_cb
  window.charCb = char_cb
  
  glfw.swapInterval(1)
  
  initRenderer(getProcAddress) ## Initialise under GLFW
  
  muInit(muCtx)
  muCtx.text_width = textWidth
  
  while not glfw.shouldClose(window):
    let (w, h) = glfw.framebufferSize(window)
    setSize(w, h) ## adjust rendering size (if we change the window size)
    
    glfw.pollEvents()
    
    let (mx, my) = glfw.cursorPos(window)
    muInputMouseMove(muCtx, mx.int, my.int)
    
    processFrame()
    clear(CLEAR_COLOR)
    
    handleMuEvents(muCtx)
    
    present()
    glfw.swapBuffers(window)
  
  glfw.terminate()

when isMainModule:
  main()
