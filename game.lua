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

require("game_elements")
require("game_board")
require("game_ui")
require("gameover")
require("lobby")

GAME_TIME = 256
--DEBUG_SKIP_LOBBY = true
--DEBUG_NO_GAMEOVER = true
--DEBUG_KEEP_SERVER_OPEN = true

mini_menu = nil
my_name = "Hello!"

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
    "control_ui",
    "ui_button",
    "resource"
  )

  shkx,shky = 0,0
  xmod,ymod = 0,0
  
  t = 0
  
  if not server_only then
    cursor = create_cursor()
  end
  
--  init_task_sys()
  
  init_game()
  
  game_timer = GAME_TIME
  
  init_lobby()
end

network_t = 0
fx_t = 0
function _update(dt)
  if btnp(6) then
    refresh_spritesheets()
  end
  
  if btnp(11) then
    show_connection = not show_connection
  end

  t = t + dt
  fx_t = fx_t - dt

  update_shake()
  
  if in_lobby then
    update_lobby()
  elseif game_over then
    update_gameover()
  else
    update_game()
  end
  
  if fx_t <= 0 then
    fx_t = 0.05
  end
  
  update_network()
end

debuggg = ""
function _draw()
  cls(23)

  xmod=shkx
  ymod=shky
  
  camera(0,0)
  
  if in_lobby then
    draw_lobby()
  elseif game_over then
    draw_gameover()
  else
    draw_game()
  end
  
--  spr(32, 32, 32, 2, 2)
  draw_debug()
  
  palt(0, false)
  palt(13, true)
  cursor:draw()
end

function _on_resize()
  local scrnw, scrnh = screen_size()

  local x = flr(scrnw/2-400/2)
  
  UI_X = x+8
  UI_Y = 12
  
  GRID_X = x+400-GRID_W-8
  GRID_Y = flr(scrnh/2-GRID_H/2)

  init_control_ui()
  refresh_control_ui()
end



function update_game()
  update_objects()
  
  game_timer = game_timer - delta_time
  
  if server_only and game_timer < 0 then
    end_game("Time's up!")
  end
  
end

function draw_game()
  camera(xmod,ymod)
  
  draw_board()
  
  palt(0, false)
  palt(13, true)
  
  draw_objects()
  draw_taskprevision(selected)
  
  font("small")
  for s in group("task_doer") do
    local x,y = board_to_screen(s.x, s.y)
    local hover = abs(x-cursor.x)<4 and abs(y-cursor.y)<4
    
    local y = y-8
    if s.hp < s.maxhp or hover then
      draw_healthbar(s,x,y)
      y = y-5
    end
    draw_task_timer(x,y,s.task,s.task_t)
    
    if hover then
      local c = faction_color[s.faction]
      font("small")
      draw_text(s.player_name, x, y-5, 1, c_drk[c], c_lit[c], 23)
    end
  end
  
  for s in group("resource") do
    local x,y = board_to_screen(s.x, s.y)
    draw_text(""..s.hoard, x, y-9, 1, 0, 22, 23)
  end
  
  camera(0,0)
  
--  draw_factioninfo()

  draw_ui()
  draw_connection()
  
  draw_tooltip()
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
        if selected.faction == my_faction and (s.board_x ~= selected.x or s.board_y ~= selected.y) then
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
  
    if mouse_btnp(0) then
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
  else
    if not mini_menu then
      selected = nil
    end
  end
  
  if selected then sfx("select") end
  
  refresh_control_ui(selected)
end

function draw_cursor(s)
  draw_selected()

  --circfill(s.x, s.y, 2, 21)
  --circfill(s.x, s.y, 1, 23)
  
  if s.board_x then
    local is_my_unit = selected and selected.type == "unit" and selected.faction == my_faction
  
    if is_my_unit then
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
    end
    
    local b_d = board[s.board_y][s.board_x]
    if tooltips and not b_d.wall then
      local o = b_d.unit or b_d.building
      
      font("small")
      local str
      
      if o then
        if o.faction == my_faction then
          str = "Left-Click to select"
        elseif is_my_unit then
          str = "Right-Click to attack!"
        end
      elseif is_my_unit then
        str = "Right-Click to go there"
      end
      
      if str then
        local x,y = GRID_X + GRID_W/2, GRID_Y - 3
        local w = str_width(str)+8
        local h = 18
        
        draw_frame(328, x-w/2-4, y-h/2-4, x+w/2+4, y+h/2+4, true)
        draw_text(str, x, y-4, 1, 0, 22, 23)
      end
    end
  end
  
  spr(260, s.x-1, s.y-1, 1, 2, 0, false, false, 0, 0)
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


function draw_debug()
  if #debuggg == 0 then return end

  local scrnw, scrnh = screen_size()
  
  font("small")
  draw_text("debug: "..debuggg, scrnw, scrnh-8, 2, 21)
end

function draw_connection()
  if not show_connection then return end
  
  local scrnw, scrnh = screen_size()
  
  font("small")
  if client.connected then
    draw_text("Connected as client #"..client.id.." - ping: "..client.getPing().." - faction #"..(my_faction or "?"), scrnw-4, 1, 2, 21, 23, 23)
--    draw_text("client #"..client.id.." - ping: "..client.getPing(), scrnw-4, 1, 2, 21)
  else
    draw_text("Not connected", scrnw-4, 1, 2, 21)
  end
end


function init_game()
  selected = nil
  
  board = {}
  if server_only then
    server_board = {}
--    gen_board()
  else
    reset_board()
    
    init_control_ui()
    refresh_control_ui()
    init_board_rendering()
  end
  
  entities = {}
  entity_id = 1
  
  dead_ids = {}
  
  faction_res = {30,30,30,30}
  faction_tiles = {0,0,0,0}
  
  if server_only then
    load_new_map()
--    for j=-1,1 do
--      for i=-1,1 do
--        color_tile(4+i, 4+j, 1)
--        color_tile(GRID_WN-4+i, 4+j, 2)
--        color_tile(4+i, GRID_HN-4+j, 3)
--        color_tile(GRID_WN-4+i, GRID_HN-4+j, 4)
--      end
--    end
--    
--    create_unit(3,5,1)
--    create_unit(5,3,1)
--    
----    create_unit(7,4,1)
----    create_unit(6,6,1)
--    
--    create_unit(GRID_WN-3,5,2)
--    create_unit(GRID_WN-5,3,2)
--    
--    create_unit(3,GRID_HN-5,3)
--    create_unit(5,GRID_HN-3,3)
--    
--    create_unit(GRID_WN-3,GRID_HN-5,4)
--    create_unit(GRID_WN-5,GRID_HN-3,4)
--    
--    create_resource(7,7)
  end
end


function faction_pal(faction, lit)
  if faction then
    local c = faction_color[faction]
    
    c = c * 1
    
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
    lobby={
      {"Name", function(str) if str then my_name = str end return my_name end, "text_field", 16},
      {"Ready", set_self_ready},
      {"Change color", demand_new_color},
      {"Settings", function() menu("settings") end},
--      {"Join the Castle Discord!", function() love.system.openURL("https://discordapp.com/invite/4C7yEEC") end}
    },
    cancel={
      {"Go Back", function() connecting=false main_menu() end}
    },
    settings={
--      {"Fullscreen", fullscreen},
--      {"Master Volume", master_volume,"slider",100},
--      {"Music Volume", music_volume,"slider",100},
      {"Sfx Volume", sfx_volume,"slider",100},
      {"Back", menu_back}
    },
    gameover={
      {"Back to lobby", function() if castle then portal.parent:newChild(portal.path) else love.event.push("quit") end end}
    }
  }
  
  set_menu_linespace("lobby", 11)
  set_menu_linespace("settings", 11)
  set_menu_linespace("gameover", 11)
  
  menu_position("lobby",0.5,0.75)
  menu_position("settings",0.5,0.75)
  menu_position("gameover",0.8,0.9)
  
  if not (castle or network) then
--    add(menus.lobby, {"Quit", function() love.event.push("quit") end})
  end
  
  return menus
end


function chance(a) return rnd(100)<a end
