

gameover_str = "Game Over"

function end_game(reason)
  if game_over then return end

  gameover_str = reason or "Game Over"

  game_over = true
  go_t = 0
  
  if server_only then
  
  else
    menu("gameover")
    
    total_score = 0
    max_score = 0
    final_scores = {}
    for id,fac in pairs(client.share[6]) do
      local score = faction_tiles[fac]
      
      final_scores[fac] = score
      total_score = total_score + score
      max_score = max(max_score, score)
    end
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
  
  draw_gameover_stats(scrnw/2, 0.4 * scrnh)
  
  draw_minimap(scrnw/2, 0.65 * scrnh, 1, 1)
  
  draw_menu()
  
  cursor:draw()
end


function draw_gameover_message(x, y)
  font("big")
  local xx = x - str_width(gameover_str)/2
  for i=1,#gameover_str do
    local ch = gameover_str:sub(i,i)
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
      
      local per = flr(score/total_score*1000)/10
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


