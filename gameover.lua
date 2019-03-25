

gameover_str = "Game Over"

function end_game(reason)
  if DEBUG_NO_GAMEOVER then return end
  if game_over then return end
  
  sfx("over")

  gameover_str = reason or "Game Over"

  game_over = true
  go_t = 0
  
  if server_only then
  
  else
    menu("gameover")
    
    total_score = 0
    max_score = -1
    max_lscore = -1
    final_scores = {}
    --for id,fac in pairs(client.share[6]) do
    for fac = 1,4 do
      local score = faction_tiles[fac]
      
      final_scores[fac] = score
      total_score = total_score + score
      
      if score > max_lscore and faction_color[fac] ~= 21 then
        max_lscore = score
        winner = fac
      end
      
      if score > max_score then
        max_score = score
      end
    end
    
    local c_id = client.share[14][winner]
    win_col = faction_color[winner]
    
    winner_name = gameover_names[winner]
  end
end

function update_gameover()
  if server_only then return end
  
  go_t = go_t + delta_time

  update_menu()
  
  cursor:update()
end

function draw_gameover()
  local scrnw, scrnh = screen_size()

  draw_gameover_message(scrnw/2, 0.05 * scrnh)
  
  draw_gameover_stats(scrnw/2, 0.5 * scrnh)
  
  draw_minimap(scrnw * 0.25, 0.8 * scrnh, 1, 1)
  
  draw_menu()
  
  cursor:draw()
end


function draw_gameover_message(x, y)
  y = y - 10

  font("big")
  local xx = x - str_width(gameover_str)/2
  for i=1,#gameover_str do
    local ch = gameover_str:sub(i,i)
    local yy = y + 4.5*cos(-go_t+i*0.1)
    
    print(ch, xx, yy+1, 22)
    print(ch, xx, yy, 0)
  
    xx = xx + str_width(ch)
  end
  
  y = y + 20
  local str = winner_name.." wins!"
  
  local xx = x - str_width(str)/2
  for i=1,#str do
    local ch = str:sub(i,i)
    local yy = y + 4.5*cos(-go_t+i*0.1)
    
    print(ch, xx, yy+1, 22)
    print(ch, xx, yy, 0)
  
    xx = xx + str_width(ch)
  end
end

function draw_gameover_stats(x, y)
  local scrnw, scrnh = screen_size()

  local vk = 1- (1-sin(min(go_t/8,0.25))) * cos(go_t * 1.8)
  
  local ww = 32
  local space = 24
  local x = scrnw/2 - 2*ww - 1.5*space
  local xx = x
  
  local height = 80
  
  for i = 1,4 do
    local score = final_scores[i]
    if score then
      local dy = score/max_score * height
      local yy = y - vk * dy
      local c  = faction_color[i]
      
      rectfill(xx, yy, xx+ww, y, c)
      line(xx, yy, xx+ww, yy, c_lit[c])
      
      font("small")
      local name = gameover_names[i]
      if name then
        draw_text(name, xx+ww/2, yy - 8, 1, 0, c, 23)
      end
      
      local per = flr(score/total_score*1000)/10
      font("big")
      draw_text(per.."%", xx+ww/2, y + 6, 1, 0, c, 23)
      draw_text(score.." tiles", xx+ww/2, y + 18, 1, 0, c, 23)
    else
      local yy = y - 2
      rectfill(xx, yy, xx+ww, y, 21)
      line(xx, yy, xx+ww, yy, 22)
    end
  
    xx = xx + ww + space
  end
  
  line(x - space*0.5, y+1, x + ww*4 + space*3.5, y+1, 22)
  line(x - space*0.5, y, x + ww*4 + space*3.5, y, 0)
  

end


