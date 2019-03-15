

GRID_WN = 32
GRID_HN = 32
TILE_W = 8
TILE_H = 8

GRID_W = GRID_WN*TILE_W
GRID_H = GRID_HN*TILE_H

GRID_X = 400-GRID_W-8
GRID_Y = 150-GRID_H/2


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

  if not server_only then
    update_tilesprite(x, y, faction, true)
    faction_pal()
  end
  
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

  if faction < 0 then -- board wall
    draw_to(flor_surf)
    --spr(31+irnd(2), 4+x*TILE_W, 4+y*TILE_H)
    update_tilesprite_hole(x, y, true)
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

function update_tilesprite_hole(x, y, recursive)
  if server_only then return end

  local n = 0
  
  if recursive then
    if x>0 then
      local wll = board[y][x-1].wall
      if wll then update_tilesprite_hole(x-1, y) n = n + 1 end
    end
    if x<GRID_WN-1 then
      local wll = board[y][x+1].wall
      if wll then update_tilesprite_hole(x+1, y) n = n + 2 end
    end
    if y>0 then
      local wll = board[y-1][x].wall
      if wll then update_tilesprite_hole(x, y-1) n = n + 4 end
    end
    if y<GRID_HN-1 then
      local wll = board[y+1][x].wall
      if wll then update_tilesprite_hole(x, y+1) n = n + 8 end
    end
  else
    if x>0 and board[y][x-1].wall then n = n + 1 end
    if x<GRID_WN-1 and board[y][x+1].wall then n = n + 2 end
    if y>0 and board[y-1][x].wall then n = n + 4 end
    if y<GRID_HN-1 and board[y+1][x].wall then n = n + 8 end
  end
  
  draw_to(flor_surf)
  faction_pal(faction)
  spr(32+n, x*TILE_W+4, y*TILE_H+4)
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
