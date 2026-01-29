## nim-microui - SDL2
## License: MIT

import ../ui
import sdl2

const
  BUFFER_SIZE = 16384
include "atlas"

var
  atlasSdlTexture*: TexturePtr = nil
  atlasSdlRgba*: seq[uint8]

template sdlFailIf(condition: typed, reason: string) =
  if condition: raise newException(Exception, reason & ": " & $getError())

template sdlFailCheck(code: typed) =
  sdlFailIf code == SdlError, "Error"

proc sdlRect(r: MURect): Rect =
  result = rect(r.x.cint, r.y.cint, r.w.cint, r.h.cint)

proc initRenderer*(window: WindowPtr): RendererPtr =
  discard setHint(HINT_RENDER_SCALE_QUALITY, "linear")
  let renderer = createRenderer(
    window = window,
    index = -1,
    flags = Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture
  )
  sdlFailIf renderer.isNil: "Error initialising SDL2 Renderer"

  atlasSdlRgba = newSeq[uint8](ATLAS_WIDTH * ATLAS_HEIGHT * 4)
  for i in 0 ..< atlas_texture.len:
    let rgbaIdx = i * 4
    let alpha = atlas_texture[i]
    atlasSdlRgba[rgbaIdx + 0] = alpha
    atlasSdlRgba[rgbaIdx + 1] = alpha
    atlasSdlRgba[rgbaIdx + 2] = alpha
    atlasSdlRgba[rgbaIdx + 3] = alpha

  atlasSdlTexture = renderer.createTexture(
    SDL_PIXELFORMAT_RGBA8888,
    SDL_TEXTUREACCESS_STATIC,
    ATLAS_WIDTH.cint,
    ATLAS_HEIGHT.cint
  )
  
  sdlFailCheck atlasSdlTexture.updateTexture(
    nil,
    unsafeAddr atlasSdlRgba[0],
    ATLAS_WIDTH.cint * 4 
  )
  
  sdlFailCheck atlasSdlTexture.setTextureBlendMode(BlendMode_Blend)
  
  return renderer

proc renderTexture(renderer: RendererPtr, dst: ptr Rect, src: MURect, color: MUColor) = 
  dst.w = src.w.cint
  dst.h = src.h.cint

  if atlasSdlTexture.isNil:
    return

  setTextureAlphaMod(atlasSdlTexture, color.a)
  if setTextureColorMod(atlasSdlTexture, color.r, color.g, color.b) == SdlError:
    sdlFailIf true: "Error setting atlas texture color"
  
  let srcRect = sdlRect(src)

  renderer.copy(
    atlasSdlTexture,
    addr srcRect,
    dst
  )

proc drawRect*(renderer: RendererPtr, r: MURect, color: MUColor) =
  discard renderer.setDrawColor(color.r, color.g, color.b, color.a)
  var rect = sdlRect(r)
  discard renderer.fillRect(addr rect)

proc drawText*(renderer: RendererPtr, pos: MUVec2, str: string, color: MUColor) =
  var dst = sdlRect(rect(pos.x, pos.y, 0, 0))
  for ch in str:
    if (ord(ch) and 0xc0) == 0x80:
      continue
    let r = min(ord(ch), 127)
    let src = atlas[AtlasFont.Font.int + r]
    renderTexture(renderer, addr dst, src, color)
    dst.x += dst.w

proc drawIcon*(renderer: RendererPtr, id: int, r: MURect, color: MUColor) =
  let src = atlas[id]
  let x = r.x + (r.w - src.w) div 2
  let y = r.y + (r.h - src.h) div 2
  # # pushQuad(renderer, rect(x, y, src.w, src.h), src, color)
  # discard
  let dstRect = sdlRect(rect(x, y, src.w, src.h))
  renderTexture(
    renderer,
    addr dstRect,
    src,
    color
  )

proc drawImage*(renderer: RendererPtr, id: int, r: MURect, color: MUColor, image: pointer) =
  ## TODO: see if can reduce texture creation overhead every time
  ## maybe integrate with texBuf
  discard
  # var textureId: GLuint
  # glGenTextures(1, addr textureId)

  # glBindTexture(GL_TEXTURE_2D, textureId)
  # glTexImage2D(GL_TEXTURE_2D, 0.GLint, GL_RGBA.GLint, r.w.GLsizei, r.h.GLsizei, 0.Glint, GL_RGBA, GL_UNSIGNED_BYTE, image)

proc getTextWidth*(text: string, len: int): int =
  result = 0
  var remaining = len
  for c in text:
    if c == '\0' or (len >= 0 and remaining <= 0):
      break
    if (ord(c) and 0xc0) == 0x80:
      continue
    let chr = min(ord(c), 127)
    result += atlas[AtlasFont.Font.int + chr].w
    if len >= 0:
      remaining -= 1

proc getTextHeight*(): int =
  return 18

proc setClipRect*(renderer: RendererPtr, r: MURect) =
  var rect = sdlRect(r)
  discard renderer.setClipRect(addr rect)

proc clear*(renderer: RendererPtr, clr: MUColor) =
  var viewport: Rect
  discard renderer.getRendererOutputSize(addr viewport.w, addr viewport.h)
  viewport.x = 0
  viewport.y = 0

  discard renderer.setViewport(addr viewport)
  discard renderer.setClipRect(addr viewport)

  discard renderer.setDrawColor(clr.r, clr.g, clr.b, clr.a)
  discard renderer.clear()

proc setSize*(renderer: RendererPtr, w, h: int) =
  discard renderer.setLogicalSize(w.cint, h.cint)

proc handleMuEvents*(muCtx: var ref MUContext, renderer: RendererPtr) =
  var cmd: ptr MUBaseCommand = nil
  while muNextCommand(muCtx, cmd):
    case cmd.kind
    of MUCommandType.Text:
      drawText(renderer, cmd.textPos, cmd.textStr, cmd.textColor)
    of MUCommandType.Rect:
      drawRect(renderer, cmd.rectRect, cmd.rectColor)
    of MUCommandType.Icon:
      drawIcon(renderer, cmd.iconId, cmd.iconRect, cmd.iconColor)
    of MUCommandType.Clip:
      setClipRect(renderer, cmd.clipRect)
    of MUCommandType.Image:
      drawImage(renderer, cmd.imageId, cmd.imageRect, cmd.imageColor, cmd.imageData)
    else:
      discard