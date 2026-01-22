import ../src/microui/ui
import glad/gl

const
  BUFFER_SIZE = 16384
include "atlas"

var
  texBuf: array[BUFFER_SIZE * 8, float32]
  vertBuf: array[BUFFER_SIZE * 8, float32]
  colorBuf: array[BUFFER_SIZE * 16, uint8]
  indexBuf: array[BUFFER_SIZE * 6, uint32]
  
  width = 800
  height = 600
  bufIdx = 0

proc initRenderer*() =
  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
  glDisable(GL_CULL_FACE)
  glDisable(GL_DEPTH_TEST)
  glEnable(GL_SCISSOR_TEST)
  glEnable(GL_TEXTURE_2D)
  glEnableClientState(GL_VERTEX_ARRAY)
  glEnableClientState(GL_TEXTURE_COORD_ARRAY)
  glEnableClientState(GL_COLOR_ARRAY)
  
  var id: GLuint
  glGenTextures(1, addr id)
  glBindTexture(GL_TEXTURE_2D, id)
  glTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA.GLint, ATLAS_WIDTH, ATLAS_HEIGHT, 0, GL_ALPHA, GL_UNSIGNED_BYTE, addr atlas_texture[0])
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST.GLint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.GLint)

proc flush() =
  if bufIdx == 0:
    return
  
  glViewport(0, 0, width.GLsizei, height.GLsizei)
  glMatrixMode(GL_PROJECTION)
  glPushMatrix()
  glLoadIdentity()
  glOrtho(0.0, width.GLdouble, height.GLdouble, 0.0, -1.0, 1.0)
  glMatrixMode(GL_MODELVIEW)
  glPushMatrix()
  glLoadIdentity()
  
  glTexCoordPointer(2, cGL_FLOAT, 0, addr texBuf[0])
  glVertexPointer(2, cGL_FLOAT, 0, addr vertBuf[0])
  glColorPointer(4, GL_UNSIGNED_BYTE, 0, addr colorBuf[0])
  glDrawElements(GL_TRIANGLES, (bufIdx * 6).GLsizei, GL_UNSIGNED_INT, addr indexBuf[0])
  
  glMatrixMode(GL_MODELVIEW)
  glPopMatrix()
  glMatrixMode(GL_PROJECTION)
  glPopMatrix()
  
  bufIdx = 0

proc pushQuad(dst, src: MURect, color: MUColor) =
  if bufIdx == BUFFER_SIZE:
    flush()
  
  let texvertIdx = bufIdx * 8
  let colorIdx = bufIdx * 16
  let elementIdx = bufIdx * 4
  let indexIdx = bufIdx * 6
  bufIdx += 1
  
  let x = src.x.float / ATLAS_WIDTH.float
  let y = src.y.float / ATLAS_HEIGHT.float
  let w = src.w.float / ATLAS_WIDTH.float
  let h = src.h.float / ATLAS_HEIGHT.float
  
  texBuf[texvertIdx + 0] = x
  texBuf[texvertIdx + 1] = y
  texBuf[texvertIdx + 2] = x + w
  texBuf[texvertIdx + 3] = y
  texBuf[texvertIdx + 4] = x
  texBuf[texvertIdx + 5] = y + h
  texBuf[texvertIdx + 6] = x + w
  texBuf[texvertIdx + 7] = y + h
  
  vertBuf[texvertIdx + 0] = dst.x.float32
  vertBuf[texvertIdx + 1] = dst.y.float32
  vertBuf[texvertIdx + 2] = (dst.x + dst.w).float32
  vertBuf[texvertIdx + 3] = dst.y.float32
  vertBuf[texvertIdx + 4] = dst.x.float32
  vertBuf[texvertIdx + 5] = (dst.y + dst.h).float32
  vertBuf[texvertIdx + 6] = (dst.x + dst.w).float32
  vertBuf[texvertIdx + 7] = (dst.y + dst.h).float32
  
  colorBuf[colorIdx + 0] = color.r
  colorBuf[colorIdx + 1] = color.g
  colorBuf[colorIdx + 2] = color.b
  colorBuf[colorIdx + 3] = color.a
  colorBuf[colorIdx + 4] = color.r
  colorBuf[colorIdx + 5] = color.g
  colorBuf[colorIdx + 6] = color.b
  colorBuf[colorIdx + 7] = color.a
  colorBuf[colorIdx + 8] = color.r
  colorBuf[colorIdx + 9] = color.g
  colorBuf[colorIdx + 10] = color.b
  colorBuf[colorIdx + 11] = color.a
  colorBuf[colorIdx + 12] = color.r
  colorBuf[colorIdx + 13] = color.g
  colorBuf[colorIdx + 14] = color.b
  colorBuf[colorIdx + 15] = color.a
  
  indexBuf[indexIdx + 0] = (elementIdx + 0).uint32
  indexBuf[indexIdx + 1] = (elementIdx + 1).uint32
  indexBuf[indexIdx + 2] = (elementIdx + 2).uint32
  indexBuf[indexIdx + 3] = (elementIdx + 2).uint32
  indexBuf[indexIdx + 4] = (elementIdx + 3).uint32
  indexBuf[indexIdx + 5] = (elementIdx + 1).uint32

proc drawRect*(r: MURect, color: MUColor) =
  pushQuad(r, atlas[AtlasFont.White.int], color)

proc drawText*(text: string, pos: MUVec2, color: MUColor) =
  var dst = rect(pos.x, pos.y, 0, 0)
  for c in text:
    if (ord(c) and 0xc0) == 0x80:
      continue
    let chr = min(ord(c), 127)
    let src = atlas[AtlasFont.Font.int + chr]
    dst.w = src.w
    dst.h = src.h
    pushQuad(dst, src, color)
    dst.x += dst.w

proc drawIcon*(id: int, r: MURect, color: MUColor) =
  let src = atlas[id]
  let x = r.x + (r.w - src.w) div 2
  let y = r.y + (r.h - src.h) div 2
  pushQuad(rect(x, y, src.w, src.h), src, color)

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

proc setClipRect*(r: MURect) =
  flush()
  glScissor(r.x.GLint, (height - (r.y + r.h)).GLint, r.w.GLsizei, r.h.GLsizei)

proc clear*(clr: MUColor) =
  flush()
  glViewport(0, 0, width.GLsizei, height.GLsizei)
  glScissor(0, 0, width.GLsizei, height.GLsizei)
  glClearColor(clr.r.float / 255.0, clr.g.float / 255.0, clr.b.float / 255.0, clr.a.float / 255.0)
  glClear(GL_COLOR_BUFFER_BIT)

proc present*() =
  flush()

proc setSize*(w, h: int) =
  width = w
  height = h

