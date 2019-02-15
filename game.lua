-- BLAST FLOCK source files
-- by TRASEVOL_DOG (https://trasevol.dog/)

require("drawing")
require("maths")
require("table")
require("object")
require("sprite")
require("audio")
require("task")

--require("nnetwork")

require("menu")

require("fx")


GRID_WN = 32
GRID_HN = 32
TILE_W = 8
TILE_H = 8

GRID_W = GRID_WN*TILE_W
GRID_H = GRID_HN*TILE_H

GRID_X = 400-GRID_W-8
GRID_Y = 150-GRID_H/2

faction_color = {15, 3, 12, 6}

mini_menu = nil

function _init()
--  fullscreen()
  init_network()

  eventpump()
  
  init_menu_system()
  
  init_object_mgr(
    "unit",
    "building",
    "task_doer",
    "unit1",
    "unit2",
    "unit3",
    "unit4",
    "res_building1",
    "res_building2",
    "res_building3",
    "res_building4",
    "control_ui"
  )

  shkx,shky = 0,0
  xmod,ymod = 0,0
  
  t = 0
  
  cursor = create_cursor()
  
--  init_task_sys()
  
  init_game()
  
  if server_only then
    create_unit(3,5,1)
    create_unit(5,3,1)
    
    create_unit(GRID_WN-3,5,2)
    create_unit(GRID_WN-5,3,2)
    
    create_unit(3,GRID_HN-5,3)
    create_unit(5,GRID_HN-3,3)
    
    create_unit(GRID_WN-3,GRID_HN-5,4)
    create_unit(GRID_WN-5,GRID_HN-3,4)
  end
end

network_t = 0
function _update(dt)
  if btnp(6) then
    refresh_spritesheets()
  end

  t = t + dt

  update_shake()
  
  update_objects()
  
  update_network()
end

debuggg = ""
function _draw()
  cls(23)

  xmod=shkx
  ymod=shky
  
  camera(0,0)
  
  camera(xmod,ymod)
  
  draw_board()
  
  palt(0, false)
  palt(13, true)
  
  draw_objects()
  
  camera(0,0)
  
--  draw_factioninfo()

  draw_ui()
  
--  spr(32, 32, 32, 2, 2)
  draw_debug()
  
  cursor:draw()
end

function _on_resize()
  local scrnw, scrnh = screen_size()

  GRID_X = scrnw-GRID_W-8
  GRID_Y = scrnh/2-GRID_H/2

  init_control_ui()
  refresh_control_ui()
end



function update_unit(s)
  s.animt = s.animt + delta_time
  update_task(s)
  
  board[s.y][s.x].unit = s
end

function get_path(ax, ay, bx, by, faction, s)
  if ax==bx and ay==by then return {} end
  
  -- check for impossible destination
  local b_d = board[by][bx]
  if b_d.wall or (b_d.unit and b_d.unit.faction == faction) then
    return {}
  end
  
  local way = {}
  
  local map={[ay*GRID_WN+ax]=0, [by*GRID_WN+bx]=128}
  local doors_a={{x=ax,y=ay,v=0}}
  local doors_b={{x=bx,y=by,v=128}}
  local found = nil
  
  local dirs={{x=-1,y=0},{x=1,y=0},{x=0,y=-1},{x=0,y=1}}
  while not found do
    local ndoors_a = {}
    local ndoors_b = {}
    for d in all(doors_a) do
      for di in all(dirs) do
        local x = d.x + di.x
        local y = d.y + di.y
        if x<0 or y<0 or x>=GRID_WN or y>=GRID_HN then
          -- edge of the world
        else
          local m = map[y*GRID_WN+x]
          if m then
            if m > 63 then
              local b
              for bb in all(doors_b) do
                if bb.x == x and bb.y == y then
                  b = bb
                  break
                end
              end
              found = {x=x, y=y, a=d, b=b}
              break
            end
          else
            local b_d = board[y][x]
            if not (b_d.wall or (b_d.unit and b_d.unit ~= s) or (b_d.building and b_d.building.faction ~= faction)) then
              add(ndoors_a, {x=x, y=y, v=d.v+1, p=d})
              map[y*GRID_WN+x]=d.v+1
            end
          end
        end
        
        if found then break end
      end
      if found then break end
    end
    doors_a = ndoors_a
    
    if not found then
      for d in all(doors_b) do
        for di in all(dirs) do
          local x = d.x + di.x
          local y = d.y + di.y
          if x<0 or y<0 or x>=GRID_WN or y>=GRID_HN then
            -- edge of the world
          else
            local m = map[y*GRID_WN+x]
            if m then
              if m < 64 then
                local a
                for aa in all(doors_a) do
                  if aa.x == x and aa.y == y then
                    a = aa
                    break
                  end
                end
                found = {x=x, y=y, a=a, b=d, v=(a and a.v or "a?")}
                break
              end
            else
              local b_d = board[y][x]
              if not (b_d.wall or (b_d.unit and b_d.unit ~= s) or (b_d.building and b_d.building.faction ~= faction)) then
                add(ndoors_b, {x=x, y=y, v=d.v-1, p=d})
                map[y*GRID_WN+x]=d.v-1
              end
            end
          end
          if found then break end
        end
        if found then break end
      end
    end
    doors_b = ndoors_b
    
    if not found and (#doors_a == 0 or #doors_b == 0) then
      return {}
    end
  end

  local a = found.a
  local halfa = {}
  while a.p do
    add(halfa, a)
    a = a.p
  end
  
  for i=#halfa,1,-1 do
    local a=halfa[i]
    a.p = nil
    --a.v = nil
    add(way, a)
  end
  
--  add(way, {x=found.x, y=found.y, v=found.v})
  local b = found.b
  while b do
    local p=b.p
    b.p = nil
    --b.v = nil
    add(way, b)
    b = p
  end
  
  return way
end

function do_damage(s, target)
  target.hp = target.hp - (2+irnd(3))
  
  if target.hp <= 0 then
    target:die()
    add_shake(2)
    --color_tile(target.x, target.y, s.faction)
  end
end

function draw_unit(s, x,y)
  if not x then
    x,y = board_to_screen(s.x, s.y)
  end
--  circfill(x,y+1,3,23)
--  circfill(x,y,3,faction_color[s.faction])
--  circfill(x,y,1,23)
  faction_pal(s.faction)
  spr(80, x, y, 2, 1)
  faction_pal()
  
  local y = y-6
  if s.hp < s.maxhp then
    draw_healthbar(s,x,y)
    y = y-5
  end
  draw_task_timer(x,y,s.task,s.task_t)
end

function create_unit(tx,ty,faction,id)
  if not id and not server_only then return end

  while board[ty][tx].unit do
    ty = ty + flr(rnd(3))-1
    tx = tx + flr(rnd(3))-1
  end

  local s = {
    animt       = 0,
    type        = "unit",
    name        = "unit",
    state       = "idle",
    x           = tx,
    y           = ty,
    task        = nil,
    task_t      = 0,
    task_queue  = {},
    maxhp       = 18,
    faction     = faction or 1,
    update      = update_unit,
    draw        = draw_unit,
    die         = destroy_unit,
    regs        = {"to_draw2", "to_update", "unit", "task_doer", "unit"..faction}
  }
  
  s.hp = s.maxhp
  
  board[ty][tx].unit = s
  
  if id then
    entities[id], s.id = s, id
    entity_id = max(entity_id, id+1)
  else
    entities[entity_id], s.id, entity_id = s, entity_id, entity_id + 1
  end
  
  register_object(s)
  
  castle_print("Unit [id:"..s.id.." - faction:"..s.faction.."] was created.")
  
  return s
end

function destroy_unit(s)
  board[s.y][s.x].unit = nil
  entities[s.id] = nil
  
  s.dead = true
  dead_ids[s.id] = true
  
  deregister_object(s)
  
  castle_print("Unit [id: "..s.id.." - faction: "..s.faction.."] died.")
end


function update_building(s)
  s.animt = s.animt + delta_time
  update_task(s)
end

function draw_building(s, x,y)
  local on_board
  if not x then
    on_board = true
    x,y = board_to_screen(s.x, s.y)
  end

--  rectfill(x-4,y-3,x+4,y+5,23)
--  rectfill(x-4,y-4,x+4,y+4,faction_color[s.faction])
--  rectfill(x-2,y-2,x+2,y+2,23)

  faction_pal(s.faction)
  if s.produce then
    -- production building
    local s = ({resource = 96, unit = 128})[s.produce]
    spr(s, x, y-4, 2, 2)
  else
    -- wall
    if not on_board then
      spr(65, x, y)
    end
  end
  faction_pal()
  
  local y = y-10
  if s.hp < s.maxhp then
    draw_healthbar(s,x,y)
    y = y-5
  end
  draw_task_timer(x,y,s.task,s.task_t)
end

function create_building(x, y, produce, faction, id)
  if not id and not server_only then return end

  local s = {
    animt       = 0,
    type        = "building",
    produce     = produce,
    state       = "idle",
    x           = x,
    y           = y,
    task        = nil,
    task_t      = 0,
    task_queue  = {},
    maxhp       = produce and 36 or 45,
    faction     = faction or 1,
    update      = update_building,
    draw        = draw_building,
    die         = destroy_building,
    regs        = {"to_update", "to_draw1", "building", "task_doer"}
  }
  
  s.hp = s.maxhp
  
  if produce == "resource" then
    assign_task(s, new_task("prod_res"))
    add(s.regs, "res_building"..faction)
  end
  
  local b_d = board[y][x]
  b_d.building = s
  
  if produce then
    for j = y-1, y+1 do
      for i = x-1, x+1 do
        color_tile(i, j, faction)
      end
    end
  else
    update_wallsurf(x, y, faction, true)
  end
  
  if id then
    entities[id], s.id = s, id
    entity_id = max(entity_id, id+1)
  else
    entities[entity_id], s.id, entity_id = s, entity_id, entity_id + 1
  end
  
  register_object(s)
  
  castle_print("Building [id:"..s.id.." - faction:"..s.faction.."] was created.")
  
  return s
end

function destroy_building(s)
  board[s.y][s.x].building = nil
  entities[s.id] = nil
  
  s.dead = true
  dead_ids[s.id] = true
  
  if not s.produce then
    update_wallsurf(s.x, s.y, s.faction, false)
  end
  
  deregister_object(s)
  
  castle_print("Building [id:"..s.id.." - faction:"..s.faction.."] died.")
end



function update_cursor(s)
  s.animt = s.animt + delta_time
  s.x, s.y = mouse_pos()
  s.board_x, s.board_y = screen_to_board(s.x, s.y)
  
--  if selected and mini_menu then
--    update_minimenu(selected)
--  end
  
  if s.board_x then
    if selected and selected.type == "unit" then
      if mouse_btnr(1) then
        if s.board_x == selected.x and s.board_y == selected.y then
          --open_minimenu(selected)
        else
          local b_d = board[s.board_y][s.board_x]
          local t = b_d.unit or b_d.building
          if t and t.faction ~= selected.faction then
            --assign_task(selected, new_task("attack", {target = t}), btn(10))
            client_add_task(selected, "attack", {target = t.id})
          elseif (not t) or t == b_d.building then
            --assign_task(selected, new_task("walk_to", {to = {x = s.board_x, y = s.board_y}}), btn(10))
            client_add_task(selected, "walk_to", {to = {x = s.board_x, y = s.board_y}})
          end
        end
      end
    end
  
    if mouse_btn(0) then
      select_at(s.board_x, s.board_y)
    end
  end
end

function select_at(x,y)
  local b_d = board[y][x]
  if b_d.unit then
    selected = b_d.unit
  elseif b_d.building then
    selected = b_d.building
    open_minimenu(selected)
  else
    if not mini_menu then
      selected = nil
    end
  end
  
  refresh_control_ui(selected)
end

function draw_cursor(s)
  draw_selected()

  --circfill(s.x, s.y, 2, 21)
  --circfill(s.x, s.y, 1, 23)
  
  if selected and selected.type == "unit" and selected.faction == my_faction then
    if s.board_x then
      if mouse_btn(1) then
        local way = get_path(selected.x, selected.y, s.board_x, s.board_y, selected.faction, selected)
        for w in all(way) do
          local x,y = board_to_screen(w.x, w.y)
          --circfill(x+3, y+3, 3, 23)
          --circfill(x+3, y+3, 2, 21)
          --print((w.v or "?"), x, y-4, 12)
          
          faction_pal(selected.faction)
          spr(261, x, y)
          faction_pal()
        end
      end
      
      local b_d = board[s.board_y][s.board_x]
      local o = b_d.unit or b_d.building
      
      if not b_d.wall and not (o and o.faction == selected.faction) then
        font("small")
        local str = "Right-Click to "
        if o then
          str = str.."attack!"
        else
          str = str.."go there"
        end
        
        local x,y = GRID_X + GRID_W/2, GRID_Y - 11
        draw_text(str, x, y+1, 1, 22)
        draw_text(str, x, y, 1, 0)
      end
    end
  end
  
  spr(260, s.x-1, s.y-1, 1, 2, 0, false, false, 0, 0)
end

function draw_selected()
  if not selected then return end
  
  local x,y = board_to_screen(selected.x, selected.y)
  --circ(x, y, 5+1.5*cos(t), 21)
  
  local d = round(6.5+1.5*cos(t*0.75))
  spr(262, x-d, y-d)
  spr(263, x+d+1, y-d)
  spr(278, x-d, y+d+1)
  spr(279, x+d+1, y+d+1)
  --rect(x-d, y-d, x+d, y+d, 23) d = d+2
  --rect(x-d, y-d, x+d, y+d, 23) d = d-1
  --rect(x-d, y-d, x+d, y+d, 0)
  
  selected:draw()
  
--  if mini_menu then
--    draw_minimenu(selected, x, y + 0.75*TILE_H)
--  end
end

function create_cursor()
  local s = {
    animt   = 0,
    update  = update_cursor,
    draw    = draw_cursor,
    regs    = {"to_update"}
  }
  
  s.x, s.y = mouse_pos()
  
  register_object(s)
  
  return s
end


function open_minimenu(s)
  if s.type == "unit" then
    mini_menu = {
      options = {
        { txt = "wander",                 cost = nil, need_empty = nil,        task = { type = "wander" }},
        { txt = "build resource factory", cost = 50,  need_empty = "building", task = { type = "build_prod", produce = "resource" }},
        { txt = "build unit factory",     cost = 50,  need_empty = "building", task = { type = "build_prod", produce = "unit" }},
        { txt = "build wall",             cost = 10,  need_empty = "building", task = { type = "build_wall" }}
      }
    }
  elseif s.type == "building" then
    if s.produce and s.produce == "unit" then
      mini_menu = {
        options = {
          { txt = "make unit", cost = 20, need_empty = "unit", task = { type = "prod_unit" }}
        }
      }
    else
      mini_menu = nil
    end
  end
  
  if not mini_menu then return end

  local wid = 0
  local hei = 0
  for o in all(mini_menu.options) do
    local needa, needb
    if o.cost then
      needa = o.cost.."$"
    end
    
    local task_info = task_lib[o.task.type]
    if task_info then
      needb = task_info.t.."s"
    end
    
    local need
    if needa and needb then
      need = "("..needa..", "..needb..")"
    elseif needa or needb then
      need = "("..(needa or needb)..")"
    end
    
    if need then
      o.txt = o.txt.." "..need
    end
    
    wid = max(wid, str_width(o.txt, "small"))
    hei = hei + 14
  end
  
  mini_menu.width = wid
  mini_menu.height = hei
end

function update_minimenu(s)
  local x, lx, rx, uy, dy = minimenu_pos(s)
  
  local i,o
  if cursor.x > lx and cursor.x < rx and cursor.y > uy and cursor.y < dy then
    i = flr((cursor.y - uy)/14)+1
    o = mini_menu.options[i]
  else
    if mouse_btnp(0) then
      mini_menu = nil
    end
    return
  end
  
  if mouse_btnr(0) then
    if (not o.cost or faction_res[s.faction] > o.cost) and is_task_possible(s, o.task) then
      --assign_task(s, o.task)
      client_add_task(selected, o.task.type, o.task)
      
      if o.cost then
        faction_res[s.faction] = faction_res[s.faction] - o.cost
      end
    end
  end
end

function draw_minimenu(s)
  local x, lx, rx, yy = minimenu_pos(s)
  
  font("small")
  for i,o in ipairs(mini_menu.options) do
    if cursor.x > lx and cursor.x < rx and cursor.y > yy and cursor.y < yy+14 then
      if mouse_btn(0) then
        rectfill(lx, yy, rx, yy+13, 16)
        rectfill(lx+1, yy+1, rx-1, yy+12, 13)
      else
        rectfill(lx, yy, rx, yy+13, 15)
        rectfill(lx+1, yy+1, rx-1, yy+12, 16)
      end
    else
      rectfill(lx, yy, rx, yy+13, 15)
    end
    
    draw_text(o.txt, x, yy+3, 1, 0)
   
    yy = yy + 14
  end
end

function minimenu_pos(s)
  local x,y = board_to_screen(s.x, s.y)
  y = y + 0.75 * TILE_W

  local lx = x - mini_menu.width/2
  local rx = x + mini_menu.width/2
  local uy = y
  
  local scrnw, scrnh = screen_size()
  if lx < 0 then
    x, rx, lx = x - lx, rx - lx, 0
  elseif rx > scrnw then
    x, lx, rx = x - (rx-scrnw), lx - (rx-scrnw), scrnw
  end
  
  if uy + mini_menu.height > scrnh then
    uy = y - 1.5*TILE_H - mini_menu.height
  end
  
  return x, lx, rx, uy, uy+mini_menu.height
end


function init_control_ui()
  if select_buttons then
    for s in all(select_buttons) do
      deregister_object(s)
    end
  end

  local x = 8
  local y = 86
  local scrnw,scrnh = screen_size()
  local xb = GRID_X - 8
  local midx = lerp(x, xb, 0.5)

  local w,h = 32, 24
  select_buttons = {
    create_button(x,    y,     w, h, nil, {"prev", "unit"}, function() select_next_entity("unit", true) end, 'q'),
    create_button(xb-w, y,     w, h, nil, {"next", "unit"}, function() select_next_entity("unit") end, 'e'),
    create_button(x,    y+h+4, w, h, nil, {"prev", "build."}, function() select_next_entity("building", true) end, 'z'),
    create_button(xb-w, y+h+4, w, h, nil, {"next", "build."}, function() select_next_entity("building") end, 'x')
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
      return
    end
    
    i = (i+di)%k+1
  end
end

function refresh_control_ui(s)
  eradicate_group("control_ui")
  
  if not s then return end -- /?\
  if s.faction ~= my_faction then return end
  
  local x = 8
  local y = 142
  local scrnw,scrnh = screen_size()
  local xb = GRID_X - 8
  local midx = lerp(x, xb, 0.5)
  
  if s.type == "unit" then
    local w,h = 16, 16
    create_button(x+w/2+1, y, w, h, 162, nil, function() client_add_task(s, "walk_up") end, 'w', "control_ui")
    create_button(x, y+h+2, w, h, 160, nil, function() client_add_task(s, "walk_left") end, 'a', "control_ui")
    create_button(x+w+2, y+h+2, w, h, 161, nil, function() client_add_task(s, "walk_right") end, 'd', "control_ui")
    create_button(x+w/2+1, y+2*h+4, w, h, 163, nil, function() client_add_task(s, "walk_down") end, 's', "control_ui")
    
    local x = x + w*2 + 8
    local w = 72
    create_button(x, y, w, h, 166, {"wall"}, function() client_add_task(s, "build_wall") end, 'r', "control_ui")
    create_button(x, y+h+2, w, h, 166, {"$$$ factory"}, function() client_add_task(s, "build_prod", {produce = "resource"}) end, 'f', "control_ui")
    create_button(x, y+2*h+4, w, h, 166, {"unit factory"}, function() client_add_task(s, "build_prod", {produce = "unit"}) end, 'v', "control_ui")
    
    local y = y+3*h+10
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
  
  if cx > s.x and cx < s.x+s.w and cy > s.y and cy < s.y+s.h then
    s.hovered = true
    
    if mouse_btn(0) then
      s.pressed = true
    else
      s.pressed = false
    end
    
    if mouse_btnr(0) then
      s.callback()
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
    else
      local x = s.x + s.w/2
      local y = yy + hh/2
      
      pal(0,c)
      spr(s.sprite, x, y-1)
      --pal(0,cl)
      --spr(s.sprite, x, y+1)
      pal(0,0)
      spr(s.sprite, x, y)
    end
  else
    local x = s.x + s.w/2
    local y = yy + hh/2 - (#s.strs-1)*0.5*8 - 2
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
    local y = 80
    local str = "['"..string.upper(s.key_str).."']"
    draw_text(str, x, y+1, 1, 22)
    draw_text(str, x, y, 1, 20)
  end
end

function create_button(x, y, w, h, s, strs, callback, key, reg)
  local s = {
    x = x,
    y = y,
    w = w,
    h = h,
    sprite = s,
    strs = strs,
    callback = callback,
    hovered = false,
    pressed = false,
    update = update_button,
    draw = draw_button,
    regs = {"to_update", "to_draw3", reg}
  }
  
  if key then
    s.key_str = key
    s.key = get_key_id(key)
  end
  
  register_object(s)
  
  return s
end


function color_tile(x, y, faction)
  if x < 0 or y < 0 or x >= GRID_WN or y>= GRID_HN then
    return
  end

  local b_d = board[y][x]
  
  if b_d.wall or b_d.building then return end
  
  local fac = b_d.faction
  if fac then
    if fac == faction then
      return
    else
      faction_tiles[fac] = faction_tiles[fac]-1
    end
  end
  
  b_d.faction = faction
  faction_tiles[faction] = faction_tiles[faction]+1

  update_tilesprite(x, y, faction, true)
  faction_pal()
  
  if server_only then
    server_board[y][x] = faction
  end
end

function update_wallsurf(x, y, faction, new_wall)
  if server_only then return end

  draw_to(wall_surf)
  
  if not new_wall then
    palt(13,false)
    pal(13,1)
    spr(48, x*TILE_W+4, y*TILE_H+4)
    pal(13,13)
  end
  
  palt(0,false)
  palt(13,true)
  
  
  other_factions = {}

  local foo = function(xx,yy,fac,list_fac)
    local n = 0
    
    if xx >= 0 and yy>=0 then
      local b_d = board[yy][xx]
      if b_d.building and not b_d.building.produce then
        if b_d.building.faction == fac then
          n = n + 1
        elseif list_fac then
          other_factions[b_d.building.faction] = true
        end
      end
    end
    
    xx = xx+1
    if xx < GRID_WN and yy>=0 then
      local b_d = board[yy][xx]
      if b_d.building and not b_d.building.produce then
        if b_d.building.faction == fac then
          n = n + 2
        elseif list_fac then
          other_factions[b_d.building.faction] = true
        end
      end
    end
    
    xx = xx-1
    yy = yy+1
    if xx >= 0 and yy < GRID_HN then
      local b_d = board[yy][xx]
      if b_d.building and not b_d.building.produce then
        if b_d.building.faction == fac then
          n = n + 4
        elseif list_fac then
          other_factions[b_d.building.faction] = true
        end
      end
    end
    
    xx = xx+1
    if xx < GRID_WN and yy < GRID_HN then
      local b_d = board[yy][xx]
      if b_d.building and not b_d.building.produce then
        if b_d.building.faction == fac then
          n = n + 8
        elseif list_fac then
          other_factions[b_d.building.faction] = true
        end
      end
    end

    if n == 0 then
      if list_fac then
        pal(22, 13)
        spr(48+15, xx*TILE_W, yy*TILE_H)
      end
    else
      faction_pal(fac)
      spr(48+n, xx*TILE_W, yy*TILE_H)
    end
    
  end
  
  foo(x-1, y-1, faction, true)
  foo(x, y-1, faction, true)
  foo(x-1, y, faction, true)
  foo(x, y, faction, true)
  
  for fac,_ in pairs(other_factions) do
    foo(x-1, y-1, fac)
    foo(x, y-1, fac)
    foo(x-1, y, fac)
    foo(x, y, fac)
  end
  
  faction_pal()
  draw_to()
end

function update_tilesprite(x, y, faction, recursive)
  if server_only then return end

  if faction < 0 then -- wall
    draw_to(flor_surf)
    spr(31+irnd(2), 4+x*TILE_W, 4+y*TILE_H)
    draw_to()
    return
  end

  local n = 0
  
  if recursive then
    if x>0 then
      local nf = board[y][x-1].faction
      if nf then update_tilesprite(x-1, y, nf) if nf == faction then n = n + 1 end end
    end
    if x<GRID_WN-1 then
      local nf = board[y][x+1].faction
      if nf then update_tilesprite(x+1, y, nf) if nf == faction then n = n + 2 end end
    end
    if y>0 then
      local nf = board[y-1][x].faction
      if nf then update_tilesprite(x, y-1, nf) if nf == faction then n = n + 4 end end
    end
    if y<GRID_HN-1 then
      local nf = board[y+1][x].faction
      if nf then update_tilesprite(x, y+1, nf) if nf == faction then n = n + 8 end end
    end
  else
    if x>0 and board[y][x-1].faction == faction then n = n + 1 end
    if x<GRID_WN-1 and board[y][x+1].faction == faction then n = n + 2 end
    if y>0 and board[y-1][x].faction == faction then n = n + 4 end
    if y<GRID_HN-1 and board[y+1][x].faction == faction then n = n + 8 end
  end
  
  draw_to(flor_surf)
  faction_pal(faction)
  spr(16+n, x*TILE_W+4, y*TILE_H+4)
  draw_to()
end

function screen_to_board(x,y)
  x = flr((x - GRID_X) / TILE_W)
  y = flr((y - GRID_Y) / TILE_H)
  
  if x < 0 or y < 0 or x >= GRID_WN or y >= GRID_HN then
    return nil, nil
  else
    return x,y
  end
end

function board_to_screen(x,y)
  x = GRID_X + x * TILE_W+4
  y = GRID_Y + y * TILE_H+4
  return x,y
end


function draw_ui()
  local x = 8
  local y = 12
  local scrnw,scrnh = screen_size()
  local xb = GRID_X - 8
  local midx = lerp(x, xb, 0.5)
  
  font("big")
  local strs = {}
  for i=1,4 do
    strs[i] = (flr(faction_tiles[i]/(GRID_WN*GRID_HN)*1000)/10).."%"
  end
  local w = str_width(strs[1].." "..strs[2].." "..strs[3].." "..strs[4])
  
  local xx = midx - w/2
  for i=1,4 do
    local c = faction_color[i]
    draw_text2(strs[i], xx, y+(i%2)*8-4, 0, 0, c, c_lit[c])
    
    xx = xx + str_width(strs[i].." ")
  end
  
  y = y + 16
  line(midx - 48, y, midx+48, y, 22)
  y = y + 14
  
  local fac = my_faction or 1
  local c = faction_color[fac]
  local cl,cd = c_lit[c], c_drk[c]
  
  xx = midx
  draw_text2(faction_res[fac].." $", xx, y, 2, 0, c, cl)

  draw_text2(" (+"..(group_size("res_building"..fac)*2).."$/s)", xx, y, 0, 0, c, cl)
  
  y = y + 14
  local n = group_size("unit"..fac)
  draw_text2(n.." unit"..(n>1 and "s" or ""), xx, y, 1, 0, c, cl)
  
  y = y + 16
  line(midx - 48, y, midx+48, y, 22)
  y = y + 40
  
  if selected then
    selected:draw(midx,y)
    
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
      local sp = task_lib[task.type].sprite
      pal(0, 22) spr(sp, x+28, y+2+2)
      pal(0, 21) spr(sp, x+28, y+2+1)
      pal(0, 0)  spr(sp, x+28, y+2)
    
      draw_text2("  "..task.type.."()", x+24, y, 0, 0, 21, 22)
      y = y + 12
    end
    
    if selected.task then
      local anim = {'/','-','\\','|'}
      draw_text2(anim[flr(t*10)%4+1], x+16, y, 1, 21, 22, 23)
      log_task(selected.task)
    end
    
    for t in all(selected.task_queue) do
      log_task(t)
    end
  end
end

function draw_board()
--  rect(GRID_X-1, GRID_Y-1, GRID_X+GRID_WN*TILE_W+1, GRID_Y+GRID_HN*TILE_H+1, 20)
--  for iy=0, GRID_HN do
--    for ix=0, GRID_WN do
--      pset(GRID_X + ix * TILE_W,
--           GRID_Y + iy * TILE_H, 22)
--    end
--  end
  
--  for y=0, GRID_HN-1 do
--    local line = board[y]
--    for x=0, GRID_WN-1 do
--      local d = line[x]
--      local xx = GRID_X + x*TILE_W
--      local yy = GRID_Y + y*TILE_H
--      if d.wall then
--        rectfill(xx, yy, xx+TILE_W+1, yy+TILE_H+1, 21)
--      elseif d.faction then
--        rectfill(xx+1, yy+1, xx+TILE_W, yy+TILE_H, faction_color[d.faction])
--      end
--    end
--  end

  palt(13, false)
  draw_surface(flor_surf, GRID_X, GRID_Y)
  
  palt(13, true)
  draw_surface(grid_surf, GRID_X-3, GRID_Y-3)
  palt(13, false)
  palt(1, true)
  draw_surface(wall_surf, GRID_X, GRID_Y)
  palt(1, false)
  
  
  local mx,my = mouse_pos()
  local tmx = flr((mx - GRID_X) / TILE_W)
  local tmy = flr((my - GRID_Y) / TILE_H)
  
  if cursor.board_x then
    local x,y = GRID_X + cursor.board_x * TILE_W, GRID_Y + cursor.board_y * TILE_H
    rect(x, y, x+TILE_W, y+TILE_H, 22)
  end
end

function draw_task_timer(x,y,task,t)
  if not task then return end
  
  local t_d = task_lib[task.type]
  if not t_d.show_time then return end

  local w = 10
  local h = 4
  
  y = y-h/2
  x = x-w/2
  
  rectfill(x-1,y-1,x+w+1,y+h+1,23)
  
  local ww = (t/t_d.t)*(w-1)
  rectfill(x+1,y+1,x+1+ww,y+h,21)
  rect(x,y,x+w,y+h-1,20)
end

function draw_healthbar(s,x,y)
  local w = 10
  local h = 4
  
  y = y-h/2
  x = x-w/2
  
  local c = faction_color[s.faction]

  rectfill(x-1,y-1,x+w+1,y+h+1,23)
  
  local ww = (s.hp/s.maxhp)*(w-1)
  rectfill(x+1,y+1,x+1+ww,y+h-1,c)
  rect(x,y,x+w,y+h-1,c_drk[c])
end

function draw_factioninfo()
  local scrnw, scrnh = screen_size()

  local x = lerp(GRID_X + GRID_WN * TILE_W, scrnw, 0.5)
  local uy,dy = GRID_Y, GRID_Y + GRID_HN * TILE_H
  
  font("big")
  for i = 1,4 do
    local y = lerp(uy, dy, (i-1)*0.25 + 0.125)
    local c = faction_color[i]
    local txtc = c --c_lit[c]
    draw_text("Player "..i, x, y-16, 1, nil, txtc)
    draw_text("Resource: "..faction_res[i].."$", x, y, 1, nil, txtc)
    draw_text("Controls "..flr(faction_tiles[i]/(GRID_WN*GRID_HN)*100).."% of board", x, y+16, 1, nil, txtc)
  end
  
end

function draw_debug()
  local scrnw, scrnh = screen_size()
  
  font("small")
  if client.connected then
    draw_text("Connected as client #"..client.id.." - ping: "..client.getPing().." - faction #"..(my_faction or "?"), scrnw-4, 1, 2, 21)
  else
    draw_text("Not connected", scrnw-4, 1, 2, 21)
  end
  
  font("big")
  draw_text("debug: "..debuggg, scrnw, scrnh-8, 2, 21)
end


function init_game()
  selected = nil
  
  board = {}
  if server_only then
    server_board = {}
    gen_board()
  else
    for y = 0, GRID_HN-1 do
      local line = {}
      for x = 0, GRID_WN-1 do
        line[x] = {}
      end
      board[y] = line
    end
    
    init_control_ui()
    refresh_control_ui()
    init_board_rendering()
  end
  
  entities = {}
  entity_id = 1
  
  dead_ids = {}
  
  faction_res = {99,99,99,99}
  faction_tiles = {0,0,0,0}
end

grid_surf = nil
flor_surf = nil
wall_surf = nil
slct_surf = nil
function init_board_rendering()
  grid_surf = grid_surf or new_surface(GRID_W+TILE_W, GRID_H+TILE_H)
  draw_to(grid_surf)
  cls(23)
  
  for i = 1,GRID_HN-1 do
    spr(1, 4, 4+i*TILE_H)
    spr(2, 4+GRID_W, 4+i*TILE_H)
    for j = 1,GRID_WN-1 do
      spr(0, 4+j*TILE_W, 4+i*TILE_H)
    end
  end
  for j = 0,GRID_WN-1 do
    spr(3, 4+j*TILE_W, 4)
    spr(4, 4+j*TILE_W, 4+GRID_H)
  end
  
  spr(5, 4, 4)
  spr(6, 4+GRID_W, 4)
  spr(7, 4, 4+GRID_H)
  spr(8, 4+GRID_W, 4+GRID_H)
  
  flor_surf = flor_surf or new_surface(GRID_W, GRID_H)
  draw_to(flor_surf)
  cls(23)
  
  palt(0,false)
  for i = 0, GRID_HN-1 do
    local line = board[i]
    for j = 0, GRID_WN-1 do
      local b_d = line[j]
      if b_d.wall then
        spr(31+irnd(2), 4+j*TILE_W, 4+i*TILE_H)
      elseif chance(5) then
        spr(8+irnd(7), 4+j*TILE_W, 4+i*TILE_H)
      end
    end
  end
  
  wall_surf = wall_surf or new_surface(GRID_W, GRID_H)
  draw_to(wall_surf)
  cls(1)
  
  slct_surf = slct_surf or new_surface(40,40)
  
  draw_to()
end

function gen_board()
  -- should be called from server
  
  for y = 0,GRID_HN-1 do
    local line = {}
    local s_line = {}
    for x = 0,GRID_WN-1 do
      line[x] = {}
      if chance((y%8 == 0) and 66 or 3) then
        line[x].wall = true
        s_line[x] = -1
      else
        s_line[x] = 0
      end
    end
    board[y] = line
    server_board[y] = s_line
  end
end

function faction_pal(faction, lit)
  if faction then
    local c = faction_color[faction]
    if lit then
      pal(20, lighter(c,lit-1))
      pal(21, lighter(c,lit))
      pal(22, lighter(c,lit+1))
    else
      pal(20, c_drk[c])
      pal(21, c)
      pal(22, c_lit[c])
    end
  else
    pal(20, 20)
    pal(21, 21)
    pal(22, 22)
  end
end



function define_menus()
  local menus={
    mainmenu={
      {"Play", function() end},
      {"Player Name", function(str) end, "text_field", 16, my_name},
      {"Settings", function() menu("settings") end},
      {"Join the Castle Discord!", function() love.system.openURL("https://discordapp.com/invite/4C7yEEC") end}
    },
    cancel={
      {"Go Back", function() connecting=false main_menu() end}
    },
    settings={
      {"Fullscreen", fullscreen},
      {"Master Volume", master_volume,"slider",100},
      {"Music Volume", music_volume,"slider",100},
      {"Sfx Volume", sfx_volume,"slider",100},
      {"Back", menu_back}
    },
    pause={
      {"Resume", function() menu_back() end},
      {"Restart", function() end},
      {"Settings", function() menu("settings") end},
      {"Back to Main Menu", main_menu},
    }
  }
  
  if not (castle or network) then
    add(menus.mainmenu, {"Quit", function() love.event.push("quit") end})
  end
  
  return menus
end


function chance(a) return rnd(100)<a end
