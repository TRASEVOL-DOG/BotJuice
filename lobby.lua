
local countdown_t = 5

function init_lobby()
  if DEBUG_SKIP_LOBBY then return end

  in_lobby = true
  
  countdown = countdown_t
  
  if not server_only then
    menu("lobby")
  end
end

function update_lobby()
  if server_only then
    update_lobby_server()
    return
  end
  
  local ready
  if client.connected and client.share[8] and client.share[1] then
    ready = true
    local i = 0
    for id,_ in pairs(client.share[1]) do
      ready = ready and client.share[8][id]
      i = i + 1
    end
    
    ready = ready and (i >= 2)
  end
  
  if ready then
    countdown = countdown - delta_time
  else
    countdown = countdown_t
  end
  
  update_menu()
  
  cursor:update()
end

function draw_lobby()
  cls(23)
  
  local scrnw,scrnh = screen_size()
  
  draw_title()
  
  draw_minimap(scrnw-8, 0.4*scrnh, 2, 1, true)
  
  local x = 16
  local y = 64
  draw_lobby_connection(x, y)
  draw_countdown(scrnw/2, y)
  y = y + 32
  
  draw_player_list(x, y)
  y = y + 64
  
  
  draw_menu()
end



function set_self_ready()
  client.home[4] = not client.home[4]
end

function start_game()
  in_lobby = false
  
  if server_only then
    castle_print("Starting game!")
    activate_map()
    close_server()
  else
    castle_print("Starting game!")
    menu_back()
    menu_back()
  end
end



function draw_title()

end

function draw_lobby_connection(x, y)
  local c0,c1,c2 = 0,22,23
  
  font("big")
  if client.connected then
    draw_text("In Lobby:", x, y, 0, c0,c1,c2)
    font("small")
    draw_text("(ping: "..client.getPing()..")", x+4, y+10, 0, 21,c1,c2)
  elseif castle and not castle.isLoggedIn then
    draw_text("Please sign into Castle to play!", x, y, 0, c0,c1,c2)
  else
    draw_text("Not connected", x, y, 0, c0,c1,c2)
  end
end

function draw_player_list(x, y)
  if not (client.connected and client.share[6] and client.share[7] and client.share[8]) then return end

  font("big")
  
  local rows = {}
  
  for id, name in pairs(client.share[7]) do
    local fac   = client.share[6][id]
    local ready = client.share[8][id]
    
    if name and fac then
      rows[fac] = true
    
      local c   = faction_color[fac]
      local x   = x - 6 + (fac-1)*4
      local y   = y + (fac-1) * 14
      local str = fac.." - "..name..(id == client.id and " (You)" or "")..(ready and " [READY]" or "")
      
      draw_text(str, x, y, 0, 0, c, 23)
    end
  end
  
  for i = 1,4 do
    if not rows[i] then
      local c   = 22
      local x   = x - 6 + (i-1)*4
      local y   = y + (i-1) * 14
      local str = i.." - Empty"
      
      draw_text(str, x, y, 0, 21, c, 23)
    end
  end
  
end

function draw_countdown(x, y)
  if countdown >= countdown_t then return end
  
  font("big")
  draw_text("Game starts in", x, y, 1, 0, 22, 23)
  draw_text(""..max(ceil(countdown), 0), x, y+12, 1, 0, 22, 23)
end

function draw_minimap(x, y, h_align, v_align, title)
  local w = 3*GRID_WN
  local h = 3*GRID_HN
  
  x = x - (h_align or 0) * w/2
  y = y - (v_align or 0) * h/2
  
  if title then
    font("small")
    draw_text("Map Preview", x+w/2, y-10, 1, 0, 22, 23)
  end
  
  local yy,xx = y,x

  for j = 0,GRID_HN-1 do
    local line = board[j]
    for i = 0,GRID_WN-1 do
      local b_d = line[i]
      local c
      if b_d.wall then
        c = 20
      elseif b_d.resource then
        c = faction_color[flr(love.timer.getTime()*4)%4+1]--22
      elseif b_d.faction then
        c = faction_color[b_d.faction]
      else
        c = 22
      end
      
      local ca = c_lit[c]
      local cb = c_lit[ca]
      
      --rectfill(xx, yy, xx+3, yy+3, c)
      --pset(xx+1, yy, ca)
      --pset(xx, yy+1, ca)
      rectfill(xx, yy, xx+3, yy+3, ca)
      pset(xx+2, yy+2, c)
      pset(xx, yy, cb)
      
      xx = xx + 3
    end
    yy = yy + 3
    xx = x
  end
end


function update_lobby_server()
  local ready
  
  if client_count and client_count >= 2 then
    ready = true
    for _,ho in pairs(server.homes) do
      ready = ready and ho[4]
    end
  end
  
  if ready then
    countdown = countdown - delta_time
    if countdown < 0 then -- starting game!
      start_game()
    end
  else
    countdown = countdown_t
  end
end