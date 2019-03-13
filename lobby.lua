
local countdown_t = 10

function init_lobby()
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
  draw_text(""..max(flr(countdown), 0), x, y+12, 1, 0, 22, 23)
end



function update_lobby_server()
  local ready
  
  if #server.homes >= 2 then
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