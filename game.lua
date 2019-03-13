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
require("lobby")


mini_menu = nil
my_name = "Helloo"

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
  
  if not server_only then
    cursor = create_cursor()
  end
  
--  init_task_sys()
  
  init_game()
  
  game_timer = 256
  
  init_lobby()
end

network_t = 0
function _update(dt)
  if btnp(6) then
    refresh_spritesheets()
  end

  t = t + dt

  update_shake()
  
  if in_lobby then
    update_lobby()
  else
    update_game()
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
  
end

function draw_game()
  camera(xmod,ymod)
  
  draw_board()
  
  palt(0, false)
  palt(13, true)
  
  draw_objects()
  draw_taskprevision(selected)
  
  camera(0,0)
  
--  draw_factioninfo()

  draw_ui()
  draw_connection()
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
  local scrnw, scrnh = screen_size()
  
  font("small")
  
  draw_text("debug: "..debuggg, scrnw, scrnh-8, 2, 21)
end

function draw_connection()
  local scrnw, scrnh = screen_size()
  
  font("small")
  if client.connected then
    draw_text("Connected as client #"..client.id.." - ping: "..client.getPing().." - faction #"..(my_faction or "?"), scrnw-4, 1, 2, 21)
  else
    draw_text("Not connected", scrnw-4, 1, 2, 21)
  end
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
  
  if server_only then
    create_unit(3,5,1)
    create_unit(5,3,1)
    
--    create_unit(7,4,1)
--    create_unit(6,6,1)
    
    create_unit(GRID_WN-3,5,2)
    create_unit(GRID_WN-5,3,2)
    
    create_unit(3,GRID_HN-5,3)
    create_unit(5,GRID_HN-3,3)
    
    create_unit(GRID_WN-3,GRID_HN-5,4)
    create_unit(GRID_WN-5,GRID_HN-3,4)
    
    create_resource(7,7)
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
    lobby={
      {"Name", function(str) my_name = str end, "text_field", 16, my_name},
      {"Ready", set_self_ready},
      {"Settings", function() menu("settings") end},
--      {"Join the Castle Discord!", function() love.system.openURL("https://discordapp.com/invite/4C7yEEC") end}
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
  
  set_menu_linespace("lobby", 11)
  set_menu_linespace("settings", 11)
  
  menu_position("lobby",0.5,0.8)
  menu_position("settings",0.5,0.7)
  
  if not (castle or network) then
    add(menus.lobby, {"Quit", function() love.event.push("quit") end})
  end
  
  return menus
end


function chance(a) return rnd(100)<a end
