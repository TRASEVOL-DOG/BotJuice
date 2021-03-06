-- BLAST FLOCK source files
-- by TRASEVOL_DOG (https://trasevol.dog/)

require("maths")
require("shader")

c_drk = {[0]=0, 0, 1, 2, 3, 8, 5, 6, 2, 8, 9, 14, 11, 12, 1, 14, 15, 14, 17, 18, 1, 20, 21, 22}
c_lit = {[0]=1, 20, 3, 4, 7, 6, 7, 23, 9, 10, 23, 12, 13, 23, 15, 16, 23, 18, 19, 10, 21, 22, 23, 23}

function init_graphics(w,h)
  local fonts={
    small={"EffortsPro.ttf",16},
    big={"Marksman.ttf",16}
    --big={"TeapotPro.ttf",16}
  }
  
  local ww,hh
  local ow,oh = w,h
  local scx,scy
  if castle or network then
    ww,hh = love.graphics.getDimensions()
  else
    ww,hh = 800, 600
    love.window.setMode(ww,hh,{resizable=true})
  end
  local scale = min(flr(ww/w), flr(hh/h))
  scx, scy = scale, scale
  w, h = ceil(ww/scx), ceil(hh/scy)
  render_canvas=love.graphics.newCanvas(w,h)
  render_canvas:setFilter("nearest","nearest")
  
  love.window.setTitle(window_title or "~ Untitled ~")
  
  init_palette()
  
  love.mouse.setVisible(false)
  
  love.graphics.setDefaultFilter("nearest","nearest",0)
  love.graphics.setPointSize(1)
  love.graphics.setLineWidth(1)
  love.graphics.setLineStyle("rough")
  love.graphics.setLineJoin("bevel")
  love.graphics.setColor(0,0,0,255)
  
  graphics = {}
  graphics.wind_w = w*scx
  graphics.wind_h = h*scy
  graphics.scrn_w = w
  graphics.scrn_h = h
  graphics.scrn_scalex = scx
  graphics.scrn_scaley = scy
  graphics.scrn_setw = ow
  graphics.scrn_seth = oh
  graphics.camx = 0
  graphics.camy = 0
  graphics.collock = false
  graphics.curcol = 0
  
  fts={}
  for name,info in pairs(fonts) do
    fts[name]=love.graphics.newFont("assets/"..info[1],info[2])
    fts[name]:setFilter("nearest", "nearest", 0)
  end
  graphics.fonts=fts
  
  init_sprite_mgr()
  
  --graphics.textdrk={[0]=1,0,1,1,2,1,5,13,2,4,9,3,1,1,2,5}
  graphics.textdrk={}
  for i=0,28 do
    graphics.textdrk[i] = c_drk[i]
  end
end

function drawstep()
  predraw()
  _draw()
  flip()
end

function predraw()
  love.graphics.setCanvas(render_canvas)
  __in_draw = true
end

function afterdraw()
  love.graphics.setCanvas()
  love.graphics.setColor(1,1,1,1)
  love.graphics.origin()
  love.graphics.draw(render_canvas,0,0,0,graphics.scrn_scalex,graphics.scrn_scaley)
  __in_draw = false
end

function flip()
  afterdraw()
  love.graphics.present()
end


function camera(x,y)
  local x=x and round(x) or 0
  local y=y and round(y) or 0
 
  love.graphics.origin()
  love.graphics.translate(-x+0.01,-y+0.01)
  
  graphics.camx=x
  graphics.camy=y
end


function color(c)
  if graphics.collock then return end
 
  local col=palette_norm[palswaps[c]]
  love.graphics.setColor(col)
  graphics.curcol=c
  return col
end

function clip(x, y, w, h)
  if x and y then
    love.graphics.setScissor(flr(x-graphics.camx), flr(y-graphics.camy), w, h)
  else
    love.graphics.setScissor()
  end
end

function pal(c1,c2)
  if c1 then
    palswaps[c1] = c2 or c1
    
    if c1==graphics.curcol then
      color(graphics.curcol)
    end
  else
    local k=#palette
    
    for i=0,k-1 do
      palswaps[i] = i
    end
    
    if sprite then
      for i=0,k-1 do
        sprite.paltrsp[i]=false
      end
      sprite.paltrsp[0]=true
    end
    
    color(graphics.curcol)
  end
end


function cls(c)
  local c=c or 0
  love.graphics.clear(color(c))
end

function circ(x,y,r,c)
  if c then color(c) end
  love.graphics.circle("line",x,y,r)
end

function circfill(x,y,r,c)
  if c then color(c) end
--  x,y=flr(x),flr(y)
  love.graphics.circle("fill",x,y,r)
end

function rect(x1,y1,x2,y2,c)
  if c then color(c) end
  
--  x1,y1=flr(x1)+0.2,flr(y1)+0.2
  
  love.graphics.line(x1,y1,x1,y2)
  love.graphics.line(x2,y1,x2,y2)
  love.graphics.line(x1,y1,x2,y1)
  love.graphics.line(x1,y2,x2,y2)
end

function rectfill(x1,y1,x2,y2,c)
  if c then color(c) end
  love.graphics.rectangle("fill",x1,y1,x2-x1,y2-y1)
end

function line(x1,y1,x2,y2,c)
  if c then color(c) end
  love.graphics.line(x1,y1,x2,y2)
end

function lines(...) --might not work
  love.graphics.line({...})
end

function pset(x,y,c)
  if c then color(c) end
--  x,y=x+0.05,y+0.05
  love.graphics.points(x,y)
end

function psets(...)
  love.graphics.points({...})
end


function font(name)
  local font=graphics.fonts[name]
  love.graphics.setFont(font)
  graphics.curfont=font
end

castle_print = print
function print(str,x,y,c)
  if c then color(c) end
  love.graphics.print(str,x,y)
end

function super_print(str,x,y,c0,c1,c2,w)
  local c0 = c0 or 23
  local c1 = c1 or graphics.textdrk[c0]
--  local c2 = c2 or 0
--  local w  = w or graphics.curfont:getWidth(str)

  if c2 then
    print(str,x,y+2,c2)
    print(str,x+1,y+1,c2)
    print(str,x-1,y+1,c2)
    print(str,x+1,y,c2)
    print(str,x-1,y,c2)
    print(str,x,y-1,c2)
  end
  
  print(str,x,y+1,c1)
  
  print(str,x,y,c0)
end

function super_print_2(str,x,y,c0,c1,c2,c3,c4,w)
  local c0 = c0 or 0
  local c1 = c1 or 22
  local c2 = c2 or graphics.textdrk[c1]
  local w  = w or graphics.curfont:getWidth(str)

  print(str,x,y+2,c0)
  print(str,x+1,y+1,c0)
  print(str,x-1,y+1,c0)
  print(str,x+1,y,c0)
  print(str,x-1,y,c0)
  print(str,x,y-1,c0)
  
  clip(x,y,w,9)
  print(str,x,y+1,graphics.textdrk[c2])
  print(str,x,y,c2)
  clip(x,y+6,w,3)
  print(str,x,y,c1)
  clip(x,y+8,w,1)
  print(str,x,y,c_lit[c1])
  
  clip(x,y+9,w,9)
  print(str,x,y+1,graphics.textdrk[c4])
  print(str,x,y,c4)
  clip(x,y+9,w,3)
  print(str,x,y,c3)
  clip(x,y+9,w,1)
  print(str,x,y,c_lit[c3])
  
  clip()
end

function draw_text(str,x,y,al,c0,c1,c2)
  local al=al or 1
 
  local w = graphics.curfont:getWidth(str)
  if al==1 then x=x-w/2
  elseif al==2 then x=x-w end
  
  y = y - 6
  
  if c1 then
    super_print(str,x,y,c0,c1,c2,w)
  else
    print(str,x,y,c0)
  end
end

function draw_text2(str,x,y,al,c0,c1,c2)
  local al=al or 1
 
  local w = graphics.curfont:getWidth(str)
  if al==1 then x=x-w/2
  elseif al==2 then x=x-w end
  
  y = y - 6
  
  if c2 then print(str,x,y+2,c2) end
  if c1 then print(str,x,y+1,c1) end
  print(str,x,y,c0)
end

function draw_text_bicolor(str,x,y,al,c0, c1a,c2a, c1b,c2b)
  local al=al or 1
 
  local w = graphics.curfont:getWidth(str)
  if al==1 then x=x-w/2
  elseif al==2 then x=x-w end
  
  y = y - 4
  
  super_print_2(str,x,y,c0,c1a,c2a,c1b,c2b,w)
end


-- to check that a font support all glyphs in a string
-- if 'font' is nil, will check all fonts
function safe_glyphs(str, font)
  if font then
    local f = graphics.fonts[font]
    if f then
      return f:hasGlyphs(str)
    else
      error("Attempt to check glyph safety for inexistant font")
    end
  else
    for _,f in pairs(graphics.fonts) do
      if not f:hasGlyphs(str) then
        return false
      end
    end
    
    return true
  end
end

function str_width(str, fnt)
  if fnt then
    fnt = graphics.fonts[fnt]
  else
    fnt = graphics.curfont
  end
  
  return fnt:getWidth(str)
end


function draw_outline(draw,c,arg)
  local c=c or 25
  local camx,camy=graphics.camx,graphics.camy
  
  all_colors_to(c)
  --graphics.collock=true
  
  camera(camx-1,camy)
  draw(arg)
  camera(camx+1,camy)
  draw(arg)
  camera(camx,camy-1)
  draw(arg)
  camera(camx,camy+1)
  draw(arg)
  
  camera(camx,camy)
  all_colors_to()
  --graphics.collock=false
end

function all_colors_to(c)
  if c then
    for i=0,#palette do
      pal(i,c)
    end
  else
    for i=0,#palette do
      pal(i,i)
    end
  end
end

function apply_pal_map(map)
  for c1,c2 in pairs(map) do
    pal(c1,c2)
  end
end

function darker(c, n)
  if n<0 then
    return lighter(c, -n)
  end
  
  for i=1,n do
    c = c_drk[c]
  end
  
  return c
end

function lighter(c, n)
  if n<0 then
    return darker(c, -n)
  end

  for i=1,n do
    c = c_lit[c]
  end
  
  return c
end


function screen_size()
  if server_only then
    return 0,0
  end

  return graphics.scrn_w,graphics.scrn_h
end

function screen_scale()
  if server_only then
    return 0,0
  end

  return graphics.scrn_scalex,graphics.scrn_scaley
end


function new_surface(w,h)
  return love.graphics.newCanvas(w,h)
end

function draw_to(surf)
  if not surf then
    if __in_draw then
      love.graphics.setCanvas(render_canvas)
    else
      love.graphics.setCanvas()
    end
    return
  end
  
  love.graphics.setCanvas(surf)
end

function surface_size(surf)
  return surf:getDimensions()
end

function draw_surface(surf,x,y,sx,sy,sw,sh)
  plt_shader()
  if sx then
    local quad=love.graphics.newQuad(sx,sy,sw,sh,surface_size(surf))
    love.graphics.draw(surf,quad,x,y)
  else
    love.graphics.draw(surf,x,y)
  end
  set_shader()
end


function plt_shader()
  set_shader("palswap")
  local ar={palette_norm[0],unpack(palette_norm)}-- add(ar,0)
  shader_send("opal",ar)
  ar={palswaps[0],unpack(palswaps)} --add(ar,0)
  shader_send("swaps",ar)
  ar={}
  for i=0,#palette do if sprite.paltrsp[i] then ar[i+1]=1 else ar[i+1]=0 end end
--  add(ar,0)
-- ar={sprite.paltrsp[0],unpack(sprite.paltrsp)} add(ar,0)
  shader_send("trsps",ar)
end


function init_palette()
  palette = mail24_palette()
  
  palette_norm = {}
  for i = 0,#palette do
    local c = palette[i]
    local col = {}
    for j,v in ipairs(c) do
      col[j] = v/255
    end
    palette_norm[i] = col
  end
  
  palswaps={}
  for i=0,#palette do
    palswaps[i]=i
  end
end

function get_palette(norm)
  if norm then
    return palette_norm
  else
    return palette
  end
end

function pico8_palette()
  return {
[0]={0,0,0},
    {29,43,83},
    {126,37,83},
    {0,135,81},
    {171,82,54},
    {95,87,79},
    {194,195,199},
    {255,241,232},
    {255,0,77},
    {255,163,0},
    {255,236,39},
    {0,228,54},
    {41,173,255},
    {131,118,156},
    {255,119,168},
    {255,204,170}
  }
end

function arcade29_palette()
  return {
[0]={255,77,77},
    {159,30,49},
    {255,196,56},
    {240,108,0},
    {241,194,132},
    {201,126,79},
    {151,63,63},
    {87,20,46},
    {114,203,37},
    {35,133,49},
    {10,75,77},
    {48,197,173},
    {47,126,131},
    {105,222,255},
    {51,165,255},
    {50,89,226},
    {40,35,123},
    {201,92,209},
    {108,52,157},
    {255,170,188},
    {229,93,172},
    {241,240,238},
    {150,165,171},
    {88,108,121},
    {42,55,71},
    {23,25,27},
    {185,165,136},
    {126,99,82},
    {65,47,47}
  }
end

function mail24_palette()
  return {
[0]={23, 17, 26},
    {55, 37, 56},
    {122, 33, 58},
    {225, 65, 65},
    {255, 160, 112},
    {196, 77, 41},
    {255, 191, 54},
    {255, 242, 117},
    {117, 57, 57},
    {207, 121, 87},
    {255, 209, 171},
    {57, 133, 90},
    {131, 224, 76},
    {220, 255, 112},
    {36, 59, 97},
    {56, 152, 255},
    {110, 238, 255},
    {104, 43, 130},
    {191, 63, 179},
    {255, 128, 170},
    {62, 55, 92},
    {120, 132, 171},
    {178, 188, 194},
    {255, 255, 255}
  }
end

function scorched_palette()
  return {
[0]={0x59, 0x08, 0x2f},
    {0xa1, 0x25, 0x38},
    {0xde, 0x60, 0x49},
    {0xf0, 0xec, 0xd5}
  }
end

function sunscorched_palette()
  return {
[0]={0x40, 0x1e, 0x2e},
    {0xab, 0x35, 0x35},
    {0xff, 0x83, 0x4a},
    {0xff, 0xff, 0xa6}
  }
end


function fullscreen()
  love.window.setFullscreen(not love.window.getFullscreen(),"desktop")
end

--function love.resize(w,h)
--  render_canvas=love.graphics.newCanvas(w,h)
--  render_canvas:setFilter("nearest","nearest")
--  local scx,scy=screen_scale()
--  
--  graphics.wind_w=w
--  graphics.wind_h=h
--  graphics.scrn_w=flr(w/scy)
--  graphics.scrn_h=flr(h/scx)
--end


function splash_screen()
  t=0
  local dog=get_dog()
  local scrnw,scrnh=screen_size()
   
  flip()
  camera(0)
  local introt=2.8
  while t<introt do
    predraw()
    
    t=t+0.01
    local kt=t*5
    
    camera(shkx,shky)
    
    color(0)

    -- clear outer screen surface
    rectfill(0, 0, scrnw/2-128+1, scrnh)
    rectfill(scrnw/2+128-1, 0, scrnw, scrnh)
    rectfill(scrnw/2-128, 0, scrnw/2+128, scrnh/2-128)
    rectfill(scrnw/2-128, scrnh/2+128, scrnw/2+128, scrnh)
    
    for i=0,3999 do
      local x,y=rnd(256),rnd(256)
      local sx,sy=flr(x/4),flr(y/4)
      
      local c=dog[sy*64+sx]
      
      if c~=7 or kt<1 then
        if c>=16-kt*2 then
          if rnd(2)<1 then
            c=drk[c]
          end
        else
          c=0
        end
      end
      
      local a=atan2(x-128,y-128)
      local l=rnd(8)
      
      x=x+scrnw/2-128+l*cos(a)
      y=y+scrnh/2-128+l*sin(a)
      color(c)
      points(x-1,y,x+1,y,x,y-1,x,y+1)
    end
    
    if kt>=6 then
     font("pico16")
     
     local c1,c2
     if kt<6.2 then
      c1=flr(t*50)%8+8
      c2=drk[c1]
     else
      c1,c2=7,13
     end
     
     draw_text("TRASEVOL_DOG",scrnw/2,scrnh/2+100,1,0,c1,c2)
     
     if kt>=7 then
      local c1,c2
      if kt<7.2 then
       c1=flr(t*50)%8+8
       c2=drk[c1]
      else
       c1,c2=7,13
      end
      draw_text("PRESENTS",scrnw/2,scrnh/2+124,1,0,c1,c2)
     end
    end
    
    if (kt%1<0.05 and kt<4) or (kt%0.5<0.05 and kt<4.5 and kt>1) then
     add_shake(48)
     sfx("dog")
    end
    
    if t>introt-0.2 then
     add_shake(32)
     sfx("dog")
    end
    
    flip()
    step()
    eventpump()
    update_shake()
  end
end

function get_dog()
  return {
    [0]=0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,0,0,0,0,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,8,8,8,8,8,8,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,8,8,8,8,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,9,9,9,9,9,9,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,9,9,9,9,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,10,10,10,10,10,10,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,10,10,10,10,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,11,11,11,11,11,11,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,11,11,11,11,12,12,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,12,12,12,12,12,12,12,12,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,13,13,12,12,12,12,13,13,12,12,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,13,13,13,13,13,13,13,13,13,13,12,12,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,13,13,7,7,13,13,13,13,7,7,13,13,12,12,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,13,13,7,7,7,7,7,7,7,7,7,7,13,13,12,12,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,11,12,12,13,13,7,7,7,7,7,7,7,7,13,13,12,12,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,12,12,13,13,7,7,7,7,7,7,7,7,13,13,12,12,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,12,13,13,13,7,7,7,7,7,7,7,7,7,13,13,12,12,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,13,13,13,13,7,7,7,7,7,7,7,7,7,7,13,13,12,12,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,13,13,13,7,7,7,7,7,7,7,7,7,7,7,13,13,12,12,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,13,13,7,7,7,7,7,7,7,7,7,7,7,7,13,13,12,12,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,13,13,7,7,7,7,7,7,7,7,7,7,7,7,7,13,13,12,12,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,13,13,7,7,7,7,7,7,7,7,7,7,7,7,7,13,13,12,12,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,13,13,7,7,7,7,7,7,7,7,7,7,7,7,7,7,13,13,12,12,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,13,13,7,7,7,7,7,7,7,7,7,7,7,7,7,13,13,12,12,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,13,13,7,7,7,7,7,7,7,7,7,7,7,7,7,7,13,13,12,12,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,13,13,7,7,7,7,7,7,7,7,7,7,7,7,7,7,13,13,12,12,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,13,13,7,7,7,7,7,7,7,7,7,7,7,7,7,7,13,13,12,12,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,13,13,7,7,7,7,7,7,7,7,7,7,13,7,7,7,13,13,12,12,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,13,13,7,7,7,7,7,7,7,7,7,7,13,7,7,7,7,13,13,12,12,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,13,13,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,13,13,12,12,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,13,13,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,13,13,12,12,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,13,13,7,7,7,7,7,7,7,7,7,7,13,7,7,7,7,7,7,13,13,12,12,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,13,13,7,7,7,7,7,7,7,7,13,13,13,13,13,13,7,7,7,7,13,13,12,12,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,13,13,7,7,7,13,13,13,13,13,13,13,13,12,13,13,13,13,13,13,13,12,12,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,13,13,7,7,7,7,7,7,7,7,7,13,13,12,12,12,13,13,13,13,12,12,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,13,13,7,7,7,7,7,7,7,7,7,7,13,13,12,12,12,12,12,12,12,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,13,13,7,7,7,7,7,7,7,7,13,13,12,12,11,12,12,12,12,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,13,13,13,13,13,13,13,13,13,13,12,12,11,11,11,11,11,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,13,13,13,13,13,13,13,13,12,12,11,11,10,11,11,11,11,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,12,12,12,12,12,12,12,12,11,11,10,10,10,10,10,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,12,12,12,12,12,12,12,12,11,11,10,10,9,10,10,10,10,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,11,11,11,11,11,11,11,11,10,10,9,9,9,9,9,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,11,11,11,11,11,11,11,11,10,10,9,9,8,9,9,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,10,10,10,10,10,10,10,10,9,9,8,8,8,8,8,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,10,10,10,10,10,10,10,10,9,9,8,8,0,8,8,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,9,9,9,9,9,9,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,9,9,9,9,9,9,9,9,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,8,8,8,8,8,8,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,8,8,8,8,8,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  }
end
