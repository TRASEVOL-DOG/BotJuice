
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
  
  draw_title(scrnw/2 - 136/2, 6)
--  draw_title(16,8)
  
  draw_credits(scrnw/2, 50)
  
  draw_minimap(scrnw-8, 0.53*scrnh-20, 2, 1, true)
  
  
  local x = 16
  local y = 0.53*scrnh - 68--64
  draw_lobby_connection(x, y)
  draw_countdown(scrnw/2, y - 12)
  y = y + 32
  
  draw_player_list(x, y)
  y = y + 64
  
  draw_instructions(scrnw/2, 0.53*scrnh - 60)
  
  draw_menu()
end



function set_self_ready()
  client.home[4] = not client.home[4]
end

function start_game()
  in_lobby = false
  
  sfx("start")
  
  if server_only then
    castle_print("Starting game!")
    activate_map()
    close_server()
  else
    castle_print("Starting game!")
    menu_back()
    menu_back()

    gameover_names = {}
    for id,fac in pairs(client.share[14]) do
      gameover_names[fac] = client.share[7][id]
    end
  end
  
end



function draw_title(x,y)
  spritesheet("title")
  palt(13, true)
  
  local wider = {[1] = true, [4] = true}
  local offsets = {0,1,-1,0,0,0,-2,1}
  
  local s = 0
  local xx = 0
  for i = 1,8 do
    local w = wider[i] and 3 or 2
    local x = x + xx + offsets[i] + w*4
    local y = y + 4.5 * cos(x/96 - love.timer.getTime()*0.75)
    
    if i == 4 and my_faction then
      faction_pal(my_faction)
    end
    
    spr(s, x, y + 16, w, 4)
    
    s = s + w
    xx = xx + w*8 - 1
  end
  
  faction_pal()
  
  spritesheet("sprites")
end

function draw_credits(x,y)
  
  font("big")
  local str = "A Castle game by Remy \"Trasevol_Dog\" Devaux"
  
  local w = str_width(str) + 40
  
  draw_text(str, x-w/2+40, y, 0, 0, 22)
  
  all_colors_to(0)
  spr(268, x-w/2+16-1, y+4, 4, 3)
  spr(268, x-w/2+16+1, y+4, 4, 3)
  spr(268, x-w/2+16, y+4-1, 4, 3)
  spr(268, x-w/2+16, y+4+1, 4, 3)
  if my_faction then
    faction_pal(my_faction)
    pal(23,23)
  else
    all_colors_to()
  end
  spr(268, x-w/2+16, y+4, 4, 3)
  all_colors_to()
  
  
  local scrnw, scrnh = screen_size()
  font("small")
  
  draw_text("Thank you to my Patreon supporters!",4,scrnh-18,0, 21, 22)
  local str = "   ~~~   ^Joseph White^,  ^Spaceling^,  rotatetranslate,  Anne Le Clech,  Wojciech Rak,  HJS,  slono,  Austin East,  Zachary Cook,  Jefff,  Meru,  Bitzawolf,  Paul Nguyen,  Dan Lewis,  Christian Östman,  Dan Rees-Jones,  Reza Esmaili,  Andreas Bretteville,  Joel Jorgensen,  Marty Kovach,  Giles Graham,  Flo Devaux,  Cole Smith,  Thomas Wright,  HERVAN,  berkfrei,  Tim and Alexandra Swast,  Jearl,  Chris McCluskey,  Sam Loeschen,  Pat LaBine,  Collin Caldwell,  Andrew Reitano,  Qristy Overton,  Finn Ellis,  amy,  Brent Werness,  yunowadidis-musik,  Max Cahill,  hushcoil,  Jacel the Thing,  Gruber,  Pierre B.,  Sean S. LeBlanc,  Andrew Reist,  vaporstack,  Jakub Wasilewski"
  local w = str_width(str)
  local x = 4-((t*50)%w)
  draw_text(str,x,scrnh-8,0, 0, 22)
  draw_text(str,x+w,scrnh-8,0, 0, 22)
end

function draw_instructions(x,y)
  font("small")
  
  local c = 22
  if my_faction then
    c = c_lit[faction_color[my_faction]]
  end
  
  draw_text("cover as much of", x, y, 1, 0, c, 23) y = y + 12
  draw_text("the board as you", x, y, 1, 0, c, 23) y = y + 12
  draw_text("can with your"   , x, y, 1, 0, c, 23) y = y + 12
  draw_text("bot juice"       , x, y, 1, 0, c, 23)
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
        c = colors[flr(love.timer.getTime()*4)%#colors+1]--22
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