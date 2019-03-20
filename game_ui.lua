
UI_X = 8
UI_Y = 12


function draw_ui()
  local x = UI_X
  local y = UI_Y
  local scrnw,scrnh = screen_size()
  local xb = GRID_X - 8
  local midx = lerp(x, xb, 0.5)
  
  font("big")
  
  -- Timer
  local str = max(ceil(game_timer), 0)..'" before end of game'
  draw_text(str, GRID_X + GRID_W/2, 2, 1, 0, 22, 23)
  
  
  -- Current scores
  local strs = {}
  local total_owned = 0
  for i = 1,4 do
    total_owned = total_owned + faction_tiles[i]
  end
  
  for i=1,4 do
    local c = faction_color[i]
    local xx = midx + (i-2.5)*22
    local n = flr((faction_tiles[i]/total_owned)*1000)/10
    local str = n.."%"
    
    draw_text2(str, xx, y-(i%2)*12+6, 1, 0, c, c_lit[c])
  end
  
  y = y + 16
  line(midx - 48, y, midx+48, y, 22)
  y = y + 14
  
  -- Available resources
  local fac = my_faction or 1
  local c = faction_color[fac]
  local cl,cd = c_lit[c], c_drk[c]
  
  xx = midx
  draw_text2(faction_res[fac].." $", xx, y, 1, 0, c, cl)
  
  y = y + 14
  local n = group_size("unit"..fac)
  draw_text2(n.." unit"..(n>1 and "s" or ""), xx, y, 1, 0, c, cl)
  
  y = y + 16
  line(midx - 48, y, midx+48, y, 22)
  y = y + 33
  
  -- Selected unit panel
  if selected then
--    selected:draw(midx,y)
    
    local w,h = 40, 40
    local sx,sy = board_to_screen(selected.x, selected.y)
    
    palt(13,false)
    draw_to(slct_surf)
    draw_surface(render_canvas, 0, 0, sx-w/2, sy-h/2, w, h)
    draw_to()
    draw_surface(slct_surf, midx-w/2, y-h/2)
    palt(13,true)
    
    --draw_frame(320, midx-w/2-4, y-h/2-4, midx+w/2+4, y+h/2+4, true)
    draw_frame(320, midx-w/2, y-h/2, midx+w/2, y+h/2)
  end
  
  
  if selected and selected.faction == my_faction then
    --font("small")
    y = task_log_y+6
    function log_task(task)
      local info = task_lib[task.type]
      local sp = info.sprite
      pal(0, 22) spr(sp, x+12, y+2+2)
      pal(0, 21) spr(sp, x+12, y+2+1)
      pal(0, 0)  spr(sp, x+12, y+2)
      
      local str
      if info.cost then
        str = task.type.."( "..info.cost.."$ )"
      else
        str = task.type.."()"
      end
      
      draw_text2(str, x+20, y, 0, 0, 21, 22)
      y = y + 12
    end
    
    if selected.task then
      --local anim = {'\\','|','/','-','>','|','<','-'}
      --local anim = {'\\','|','/','-','>','|','>','-'}
      local anim = {'>','|','>','-'}
      local c = anim[flr(t*9)%#anim+1]
      draw_text2(c, x+2, y, 1, 21, 22, 23)
      log_task(selected.task)
    end
    
    for t in all(selected.task_queue) do
      log_task(t)
    end
  end
end



function init_control_ui()
  if select_buttons then
    for s in all(select_buttons) do
      deregister_object(s)
    end
  end

  local x = UI_X
  local y = UI_Y + 69
  local scrnw,scrnh = screen_size()
  local xb = GRID_X - 8
  local midx = lerp(x, xb, 0.5)

  local w,h = 32, 24
  select_buttons = {
    create_button(x,    y+h/2,     w, h, nil, {"prev", "unit"}, function() select_next_entity("unit", true) end, 'q'),
    create_button(xb-w, y+h/2,     w, h, nil, {"next", "unit"}, function() select_next_entity("unit") end, 'e'),
--    create_button(x,    y+h+4, w, h, nil, {"prev", "build."}, function() select_next_entity("building", true) end, 'z'),
--    create_button(xb-w, y+h+4, w, h, nil, {"next", "build."}, function() select_next_entity("building") end, 'x')
  }
end

function select_next_entity(ty, prev)
  local oi
  if selected then oi = selected.id
  else oi = 1 end

  local i = oi
  local k = entity_id
  local di = prev and -2 or 0
  
  i = (i+di)%k+1
  while oi ~= i do
    local s = entities[i]
    
    if s and s.faction == my_faction and s.type == ty then
      selected = s
      refresh_control_ui(s)
      sfx("select")
      return
    end
    
    i = (i+di)%k+1
  end
end

holding = {}
function refresh_control_ui(s)
  eradicate_group("control_ui")
  
  if not s then return end
  if s.faction ~= my_faction then return end
  
  local x = UI_X
  local y = UI_Y + 118
  local scrnw,scrnh = screen_size()
  local xb = GRID_X - 8
  local midx = lerp(x, xb, 0.5)
  
  if s.type == "unit" then
    local walk = function(dir)
      if holding.build_wall then
        client_add_task(s, "build_wall")
      elseif holding.juice then
        client_add_task(s, "juice")
      end
      client_add_task(s, "walk_"..dir)
    end
  
    local w,h = 16, 16
    create_button(x+w/2+1, y, w, h, 162, nil, function() walk("up") end, 'w', "control_ui", "walk")
    create_button(x, y+h+2, w, h, 160, nil, function() walk("left") end, 'a', "control_ui", "walk")
    create_button(x+w+2, y+h+2, w, h, 161, nil, function() walk("right") end, 'd', "control_ui", "walk")
    create_button(x+w/2+1, y+2*h+4, w, h, 163, nil, function() walk("down") end, 's', "control_ui", "walk")
    
    local x = x + w*2 + 8
    local w = 80
    create_button(x, y, w, h, 169, {"juice"}, function() client_add_task(s, "juice") end, 'r', "control_ui", "juice")
--    create_button(x, y, w, h, 166, {"wall"}, function() client_add_task(s, "build_wall") end, 'r', "control_ui")
    create_button(x, y+h+2, w, h, 166, {"wall"}, function() client_add_task(s, "build_wall") end, 'f', "control_ui", "build_wall")
--    create_button(x, y+h+2, w, h, 166, {"$$$ factory"}, function() client_add_task(s, "build_prod", {produce = "resource"}) end, 'f', "control_ui")
    create_button(x, y+2*h+4, w, h, 170, {"duplicate"}, function() client_add_task(s, "duplicate") end, 'v', "control_ui", "duplicate")
--    create_button(x, y+2*h+4, w, h, 166, {"unit factory"}, function() client_add_task(s, "build_prod", {produce = "unit"}) end, 'v', "control_ui")
    
    y = y+3*h+10
    
    x = x - 8 - 32
    local w = 120
    create_button(x, y, w, h, 174, {"cancel last task"}, function() client_add_task(s, -1) end, 'backspace', "control_ui")
    create_button(x, y+h+2, w, h, 175, {"clear task queue"}, function() client_add_task(s, -2) end, 'tab', "control_ui")
    
    y = y + 2*h + 8
    
    task_log_y = y
  elseif s.type == "building" then
    if s.produce == "unit" then
      local w,h = 76, 16
      create_button(x, y, w, h, 166, {"create unit"}, function() client_add_task(s, "prod_unit") end, 'a', "control_ui")
      y = y + h + 10
    end
  
    task_log_y = y
  end
end

function update_button(s)
  local cx, cy = cursor.x, cursor.y
  
  local opressed = s.pressed
  local callb = false
  
  if cx > s.x and cx < s.x+s.w and cy > s.y and cy < s.y+s.h then
    s.hovered = true
    
    if mouse_btn(0) then
      s.pressed = true
    else
      s.pressed = false
    end
    
    if mouse_btnr(0) then
      s.callback()
      callb = true
    end
  else
    s.hovered = false
    s.pressed = false
  end
  
  if btn(s.key) then
    s.pressed = true
  end
  
  if btnr(s.key) then
    s.callback()
    callb = true
  end
  
  if s.pressed and not opressed then
    sfx("button", nil, nil, 0.5)
  end
  
  if callb then
    sfx("button", nil, nil, 1)
    
    if s.cost and faction_res[my_faction] < s.cost then
      sfx("nomoney")
    end
  end
  
  if s.task_type then
    holding[s.task_type] = s.pressed
  end
end

function draw_button(s)
  local fac = my_faction or 1
  local fc = faction_color[fac]
  
  local lit
  if s.pressed then lit = -1
  elseif s.hovered then lit = 1 end
  
  local c,cl,cd
  if lit then
    c, cl, cd = lighter(fc, lit), lighter(fc, lit+1), lighter(fc, lit-1)
  else
    c, cl, cd = fc, c_lit[fc], c_drk[fc]
  end
  
  local yy = s.y + (s.pressed and 3 or s.hovered and 1 or 0)
  local hh = s.h
  
  --rectfill(s.x, yy, s.x+s.w, yy+hh, c)
  
  clip(s.x, s.y, s.w, s.h)
  
  faction_pal(fac, lit)
  pal(23, lighter(fc, (lit or 0)+2))
  draw_frame(256, s.x, yy, s.x+s.w, yy+hh, true)
  faction_pal()
  pal(23,23)
  clip()
--  line(s.x+1, s.y+s.h, s.x+s.w-1, s.y+s.h, 0)
  sspr(8, 152, 8, 2, s.x+1, s.y+s.h, s.w-2, 2, 0, 0, 0)
  
  hh = hh-3
  
  font("small")
  if s.sprite then
    if s.strs then
      pal(0,c)
      spr(s.sprite, s.x+8, yy+hh/2-1)
      --pal(0,cl)
      --spr(s.sprite, s.x+8, yy+hh/2+1)
      pal(0,0)
      spr(s.sprite, s.x+8, yy+hh/2)
      
      local x = s.x + 16
      local y = yy + hh/2 - (#s.strs-1)*0.5*8 - 2
      
      for _,str in ipairs(s.strs) do
        draw_text(str, x, y-1, 0, c)
        --draw_text(str, x, y+1, 0, cl)
        draw_text(str, x, y, 0, 0)
        y = y + 8
      end
      
      if s.cost then
        local x = s.x+s.w-2
        local y = yy+hh/2 - 2
        local str = s.cost.."$"
        draw_text(str, x, y-1, 2, c)
        draw_text(str, x, y, 2, 0)
      end
    else
      local x = s.x + s.w/2
      local y = yy + hh/2
      
      local sp = s.sprite
      if s.task_type == "walk" then
        if holding.build_wall then
          sp = 166
        elseif holding.juice then
          sp = 169
        end
      end
      
      pal(0, c)
      spr(sp, x, y-1)
      --pal(0,cl)
      --spr(s.sprite, x, y+1)
      pal(0, 0)
      spr(sp, x, y)
    end
  else
    local x = s.x + s.w/2
    local y = yy + hh/2 - (#s.strs - 1) * 0.5 * 8 - 2
    for _,str in ipairs(s.strs) do
      draw_text(str, x, y-1, 1, c)
      --draw_text(str, x, y+1, 1, cl)
      draw_text(str, x, y, 1, 0)
      y = y + 8
    end
  end

  if s.hovered and s.key_str then
    font("small")
    local x = lerp(8, GRID_X-8, 0.5)
    local y = 77
    local str = "Shortcut: ['"..string.upper(s.key_str).."']"
    draw_text(str, x, y+1, 1, 22)
    draw_text(str, x, y, 1, 20)
  end
end

function create_button(x, y, w, h, s, strs, callback, key, reg, task_type)
  local s = {
    x = x,
    y = y,
    w = w,
    h = h,
    sprite = s,
    strs = strs,
    callback = callback,
    task_type = task_type,
    hovered = false,
    pressed = false,
    update = update_button,
    draw = draw_button,
    regs = {"to_update", "to_draw3", reg}
  }
  
  if task_type then
    s.cost = task_lib[task_type].cost
  end
  
  if key then
    s.key_str = key
    s.key = get_key_id(key)
  end
  
  register_object(s)
  
  return s
end

