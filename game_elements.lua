

faction_color = {15, 3, 12, 6}


function update_unit(s)
  s.animt = s.animt + delta_time
  
  if s.state == "idling" then
    local a,b,c = anim_step("unit", "idling", s.animt)
    if c > 0 then
      s.state = "idle"
    end
  end
  
  s.blinkt = s.blinkt - delta_time
  if s.blinkt < 0 then
    s.state = "idling"
    s.animt = 0
    if selected == s then
      s.blinkt = 0.5
    else
      s.blinkt = 1+rnd(1)
    end
  end
  
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
  draw_anim(x, y-5, "unit", s.state, s.animt)
--  spr(80, x, y, 2, 1)
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
    animt      = 0,
    blinkt     = 0,
    type       = "unit",
    name       = "unit",
    state      = "idle",
    x          = tx,
    y          = ty,
    task       = nil,
    task_t     = 0,
    task_queue = {},
    maxhp      = 18,
    faction    = faction or 1,
    update     = update_unit,
    draw       = draw_unit,
    die        = destroy_unit,
    regs       = {"to_draw2", "to_update", "unit", "task_doer", "unit"..faction}
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

function draw_taskprevision(s)
  if not s then return end
  if s.faction ~= my_faction then return end
  
  local steps = {}
  local x,y = s.x, s.y
  local do_step = function(task)
    if not task then return end
  
    local dx,dy
    if task.type == "walk_left"      then dx = -1
    elseif task.type == "walk_right" then dx = 1
    elseif task.type == "walk_up"    then dy = -1
    elseif task.type == "walk_down"  then dy = 1
    elseif task.type == "walk_to"    then x,y = task.to.x,task.to.y
    elseif task.type == "walk"    then x,y = task.path[#task.path].x, task.path[#task.path].y end
    if dx or dy then
      x = x + (dx or 0)
      y = y + (dy or 0)
    end
    
    local stp = steps[y*GRID_WN+x] or 0
    
    local c = faction_color[s.faction]
    local sp = task_lib[task.type].sprite
    local xx,yy = board_to_screen(x,y)
    yy = yy - stp*3
    
    pal(0,23)
    spr(sp, xx, yy+2)
    pal(0,c)
    spr(sp, xx, yy+1)
    pal(0,0)
    spr(sp, xx, yy)
    
    steps[y*GRID_WN+x] = stp+1
  end
  
  do_step(s.task)
  
  for _,task in ipairs(s.task_queue) do
    do_step(task)
  end
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
    animt      = 0,
    type       = "building",
    produce    = produce,
    state      = "idle",
    x          = x,
    y          = y,
    task       = nil,
    task_t     = 0,
    task_queue = {},
    maxhp      = produce and 36 or 45,
    faction    = faction or 1,
    update     = update_building,
    draw       = draw_building,
    die        = destroy_building,
    regs       = {"to_update", "to_draw1", "building", "task_doer"}
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



function update_resource(s)
  s.prodt = s.prodt - delta_time
  if s.prodt < 0 and s.hoard < 99 then
    s.hoard = s.hoard + 1
    s.prodt = s.prodt + s.prod
    
    local u = board[s.y][s.x].unit
    if u then
      harvest_resource(s, u)
    end
  end
end

function draw_resource(s)
  x,y = board_to_screen(s.x, s.y)
  
  spr(34+flr(s.prodt*8)%4, x, y)

  font("small")
  draw_text(""..s.hoard, x, y-8, 1, 0, 22, 23)
end

function harvest_resource(s, harvester)
  local fac = harvester.faction
  faction_res[fac] = faction_res[fac] + s.hoard
  
  local x,y = board_to_screen(s.x, s.y)
  create_floatingtxt(x, y-3, "+"..s.hoard, faction_color[fac])
  
  s.hoard = 0
end

function create_resource(x, y, rate_per_sec, id)
  local prod = 1/(rate_per_sec or 1)

  local s = {
    type   = "res",
    x      = x,
    y      = y,
    prod   = prod,
    prodt  = prod,
    hoard  = 0,
    update = update_resource,
    draw   = draw_resource,
    regs   = {"to_update", "to_draw2"}
  }
  
  local b_d = board[y][x]
  b_d.resource = s
  
  if id then
    entities[id], s.id = s, id
    entity_id = max(entity_id, id+1)
  else
    entities[entity_id], s.id, entity_id = s, entity_id, entity_id + 1
  end
  
  register_object(s)
  
  castle_print("Resource point [id:"..s.id.."] was created.")
  
  return s
end

