import std/[unicode]

import sdl2

import ../../src/microui
import ../../src/microui/renderer/sdl

const
  WINDOW_WIDTH = 800
  WINDOW_HEIGHT = 600
  CLEAR_COLOR = color(90, 95, 100, 255)

## UI state
var
  muCtx: ref MUContext

  input: string

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
      if (muTextbox(input) and (1 shl ord(MUResult.Submit))) != 0:
        muCtx.muSetFocus(muCtx.lastId)

proc main() =
  sdl2.init(INIT_VIDEO or INIT_EVENTS)
  
  let window = createWindow(
    "Nim microui SDL2",
    SDL_WINDOWPOS_CENTERED,
    SDL_WINDOWPOS_CENTERED,
    WINDOW_WIDTH,
    WINDOW_HEIGHT,
    SDL_WINDOW_SHOWN
  )

  if window.isNil:
    quit("Failed to create SDL2 window")
  defer: window.destroy()

  let renderer = initRenderer(window)
  defer: renderer.destroy()
  
  muInit(muCtx)
  muCtx.text_width = textWidth

  var running = true
  
  while running:
    let (w, h) = window.getSize()
    renderer.setSize(w, h) ## adjust rendering size (if we change the window size)
    
    var event = defaultEvent

    while pollEvent(event):
      case event.kind:
      of QuitEvent:
        running = false
      of MouseMotion:
        muCtx.muInputMouseMove(event.motion.x, event.motion.y)
      of MouseButtonDown, MouseButtonUp:
        let muFn: proc (muCtx: var ref MUContext, btn: MUMouse) = if event.kind == MouseButtonDown: muInputMouseDown else: muInputMouseUp
        case event.button.button
        of BUTTON_LEFT:
          muCtx.muFn(MUMouse.Left)
        of BUTTON_MIDDLE:
          muCtx.muFn(MUMouse.Middle)
        of BUTTON_RIGHT:
          muCtx.muFn(MUMouse.Right)
        else:
          discard
      of TextInput:
        muCtx.muInputText($event.text.text[0])
      of KeyDown, KeyUp:
        let muFn: proc (muCtx: var ref MUContext, key: int) = if event.kind == KeyDown: muInputKeyDown else: muInputKeyUp

        case event.key.keysym.scancode
        of SDL_SCANCODE_LSHIFT, SDL_SCANCODE_RSHIFT:
          muCtx.muFn(MUControlKey.Shift.ord)
        of SDL_SCANCODE_LCTRL, SDL_SCANCODE_RCTRL:
          muCtx.muFn(MUControlKey.Ctrl.ord)
        of SDL_SCANCODE_LALT, SDL_SCANCODE_RALT:
          muCtx.muFn(MUControlKey.Alt.ord)
        of SDL_SCANCODE_RETURN:
          muCtx.muFn(MUControlKey.Return.ord)
        of SDL_SCANCODE_BACKSPACE:
          muCtx.muFn(MUControlKey.Backspace.ord)
        else:
          discard
      else:
        discard
    
    processFrame()
    renderer.clear(CLEAR_COLOR)
    
    handleMuEvents(muCtx, renderer)
    
    renderer.present()

when isMainModule:
  main()
