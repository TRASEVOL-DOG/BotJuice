
network_t = 0
update_id = 0
delay = 0

my_faction = nil

function init_network()
  if server_only then
    entity_type_int = {
      unit = 1,
      building = 2,
      buildingresource = 3,
      buildingunit = 4,
      res = 5
    }
  
    faction_clients = {}
  
    update_ids = {}
    server.share[4] = {}
    server.share[5] = {0,0,0,0}
    
    server.share[6] = {}
--    server.share[6]:__relevance(function(self, client_id) return {[client_id] = true} end)
  else
    update_id = 1
    client.home[2] = {}
  end
end

function update_network()
  network_t = network_t - delta_time
  if network_t > 0 then
    return
  end
  
  if server_only then
    server_output()
  else
    client_output()
  end
  
  network_t = 0.05
end



function client_input(diff)
  debuggg = "getting stuff"
--  if not (client and client.connected) then
--    return
--  end
  
  if client.share[1] then
    local timestamp = client.share[1][client.id]
    if timestamp then
      delay = (love.timer.getTime() - timestamp) / 2
    end
  end
  
  board_changes = diff[3]
  if board_changes then
    for y,line in pairs(board_changes) do
      local b_line = board[y]
      for x,n in pairs(line) do
        if n < 0 then
          b_line[x].wall = true
          update_tilesprite(x, y, -1)
        elseif n > 0 then
          color_tile(x, y, n)
        end
      end
    end
  end
  
  local entity_data = client.share[4]
  for id,s in pairs(entities) do
    if not entity_data[id] then
      s:die()
    end
  end
  
  local entity_changes = diff[4]
  if entity_changes then
    for id,_ in pairs(entity_changes) do
      sync_entity(id, entity_data[id])
    end
  end
  
  if client.share[5] then
    faction_res = copy_table(client.share[5])
  end
  
  if client.share[6] then
    my_faction = my_faction or client.share[6][client.id]
  end

  countdown = client.share[9] or 10
  if in_lobby and countdown <= 0 then
    start_game()
  end
  
--  if client.share[11] == 1 and not in_lobby then
--    end_game("The other players dropped out!")
--  end
  
  game_timer = client.share[10] - delay
  if client.share[10] < 0 then
    end_game("Time's up!")
  end
end

function client_output()
--  if not (client and client.connected) then
--    return
--  end
  
  client.home[1] = love.timer.getTime()
  client.home[3] = my_name
end

function client_connect()
  castle_print("Connected to server!")
  client.home[2] = {}
end

function client_disconnect()
  castle_print("Disconnected from server!")
  
  if not in_lobby then
    end_game("You were disconnected. :S")
  end
end

function client_add_task(s, task_type, info)
  local entry = {s.id, task_type, info}
  client.home[2][update_id] = entry
  
  update_id = update_id + 1
end

function sync_entity(id, data)
  if dead_ids[id] then return end

  local s = entities[id]
  if not s then
    if data.type == 1 then
      s = create_unit(data.x, data.y, data.faction, id)
    elseif data.type == 5 then
      s = create_resource(data.x, data.y, data.rate, id)
    else
      local produce = ({[3] = "resource", [4] = "unit"})[data.type]
      s = create_building(data.x, data.y, produce, data.faction, id)
    end
  else
    if s.x ~= data.x or s.y ~= data.y then
      board[s.y][s.x].unit, board[data.y][data.x].unit = nil, s
      s.x = data.x
      s.y = data.y
    end
  end
  
  if data.type == 5 then
    s.hoard = data.hoard
  else
    s.hp = data.hp
    
    if data.task ~= 0 and not same_task(data.task, s.task) then
      s.task = copy_task(data.task)
    end
    s.task_t = data.task_t + delay
    
    s.task_queue = {}
    for i,t in pairs(data.task_queue) do
      s.task_queue[i] = copy_task(t)
    end
  end
  
--  if data.next_task ~= 0 and not same_task(data.next_task, s.task_queue[1]) then
--    assign_task(s, copy_task(data.next_task), false)
--  end
  
--  if data.next_task ~= 0 then
--    debuggg = data.next_task.type..(data.next_task.path and (" : "..#data.next_task.path) or "")
--  end
  
end



function server_input()
--  if not server then
--    return
--  end
  

  for id,h in pairs(server.homes) do
    if h[2] then
      local u_id = update_ids[id]
      while h[2][u_id] do
        process_task(h[2][u_id])
        u_id = u_id+1
      end
      update_ids[id] = u_id
    end
  end
  
  
  
end

function server_output()
--  if not server then
--    return
--  end
  
  server.share[1] = {} -- timestamps
  server.share[7] = {} -- names
  server.share[8] = {} -- ready
  for id,h in pairs(server.homes) do
    server.share[1][id] = h[1]
    server.share[7][id] = h[3]
    server.share[8][id] = h[4]
  end
  
  server.share[2] = update_ids

  server.share[3] = server_board
  
  local server_entities = server.share[4]
  for id,s in pairs(server_entities) do
    if not entities[id] then
      server_entities[id] = nil
    end
  end
  
  for id,s in pairs(entities) do
    local ss = server_entities[id] or {}
    
    ss.faction = s.faction
    ss.type = entity_type_int[s.type..(s.produce or "")]
    ss.x = s.x
    ss.y = s.y
    ss.hp = s.hp
    ss.task_t = s.task_t
    ss.task = simplify_task(s.task)
    --ss.next_task = simplify_task(s.task_queue[1])
    
    if s.task_queue then
      ss.task_queue = {}
      for i,t in pairs(s.task_queue) do
        ss.task_queue[i] = simplify_task(t)
      end
    end
    
    ss.hoard = s.hoard
    
    server_entities[id] = ss
  end
  
  server.share[5] = faction_res
  
  server.share[9] = countdown or 10
  server.share[10] = game_timer
  server.share[11] = client_count
end

client_count = 0
function server_new_client(id)
  castle_print("New client: #"..id)
  
  client_count = client_count + 1

  update_ids[id] = 1
  
  local fac = 1
  while faction_clients[fac] do
    fac = fac + 1
  end
  
  faction_clients[fac] = id
  server.share[6][id] = fac
end

function server_lost_client(id)
  castle_print("Client #"..id.." disconnected.")
  
  faction_clients[server.share[6][id] or 0] = nil
  
  client_count = client_count - 1
  
  if server_closed then
    server.maxClients = client_count
  end
end

function process_task(data)
  local s = entities[data[1]]
  
  castle_print("Received task command: "..data[2])
  
  if in_lobby then
    castle_print("Ignoring - game hasn't started yet.")
    return
  elseif game_over then
    castle_print("Ignoring - game is over.")
    return
  end
  
  if data[2] == -1 then
    cancel_last_task(s)
  elseif data[2] == -2 then
    clear_task_queue(s)
  else
    assign_task(s, new_task(data[2], data[3]), true)
  end
end

function simplify_task(task)
  if not task then return 0 end
  
  if task.type == "walk" then
    if #task.path == 1 then
      return {type = "walk", path = {task.path[1]}}
    else
      return {type = "walk_to", to = task.path[#task.path]}
    end
  end
  
  return copy_task(task)
end

function close_server()
  if DEBUG_KEEP_SERVER_OPEN then return end
  
  castle_print("Closing server.")

  server.maxClients = client_count
  server_closed = true
end


-- client.home = {
--   [1] = local_time,
--   [2] = ordered_tasks,
--   [3] = my_name,
--   [4] = ready
-- }
-- 
-- server.share = {
--   [1] = client_times,
--   [2] = client_update_ids,
--   [3] = board_data,
--   [4] = game_entities,
--   [5] = faction_resources,
--   [6] = client_faction,
--   [7] = client_names,
--   [8] = client_readies,
--   [9] = lobby_countdown,
--   [10]= game_timer,
--   [11]= client_count
-- }

