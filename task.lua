
task_lib = {
  ["walk"] = {
    t = 0.5,
    show_time = true,
    sprite = 175,
    
    task_done = function(s, task)
      local pos = task.path[1]
      board[s.y][s.x].unit = nil
      s.x, s.y = pos.x, pos.y
      color_tile(s.x, s.y, s.faction)
    end,
    
    start_task = function(s, task)
      local npos = task.path[1]
      if not npos then return false end
      
      local b_d = board[npos.y][npos.x]
      if b_d.unit or (b_d.building and b_d.building.faction ~= s.faction) then
        task.type = "walk_to"
        task.to = task.path[#task.path]
        task.path = nil
        do_remove_task = false
        return true
      end
      
      s.task = new_task("walk", {path = {npos}})
      table.remove(task.path, 1)
      
      if #task.path > 0 then
        do_remove_task = false
      end
      
      --board[npos.y][npos.x].unit = s

      return true
    end
  },
  
  ["walk_to"] = {
    t = 0.0,
    show_time = false,
    sprite = 164,

    start_task = function(s, task)
      local way = get_path(s.x, s.y, task.to.x, task.to.y, s.faction, s)
      
      if #way == 0 then
        return false
      end

      do_remove_task = false
      task.type = "walk"
      task.to = nil
      task.path = way

      return false
    end
  },
  
  ["walk_left"] = {
    t = 0.5,
    show_time = true,
    sprite = 160,
    
    condition = function(s, task)
      if s.x <= 0 then return false end
      local b_d = board[s.y][s.x-1]
      return not (b_d.wall or b_d.unit or (b_d.building and b_d.building.faction ~= s.faction))
    end,
    
    task_done = function(s, task)
      board[s.y][s.x].unit = nil
      s.x = s.x-1
      board[s.y][s.x].unit = s
      color_tile(s.x, s.y, s.faction)
    end,
  },
  
  ["walk_right"] = {
    t = 0.5,
    show_time = true,
    sprite = 161,
    
    condition = function(s, task)
      if s.x >= GRID_W-1 then return false end
      local b_d = board[s.y][s.x+1]
      return not (b_d.wall or b_d.unit or (b_d.building and b_d.building.faction ~= s.faction))
    end,
    
    task_done = function(s, task)
      board[s.y][s.x].unit = nil
      s.x = s.x+1
      board[s.y][s.x].unit = s
      color_tile(s.x, s.y, s.faction)
    end,
  },
  
  ["walk_up"] = {
    t = 0.5,
    show_time = true,
    sprite = 162,
    
    condition = function(s, task)
      if s.y <= 0 then return false end
      local b_d = board[s.y-1][s.x]
      return not (b_d.wall or b_d.unit or (b_d.building and b_d.building.faction ~= s.faction))
    end,
    
    task_done = function(s, task)
      board[s.y][s.x].unit = nil
      s.y = s.y-1
      board[s.y][s.x].unit = s
      color_tile(s.x, s.y, s.faction)
    end,
  },
  
  ["walk_down"] = {
    t = 0.5,
    show_time = true,
    sprite = 163,
    
    condition = function(s, task)
      if s.y >= GRID_H-1 then return false end
      local b_d = board[s.y+1][s.x]
      return not (b_d.wall or b_d.unit or (b_d.building and b_d.building.faction ~= s.faction))
    end,
    
    task_done = function(s, task)
      board[s.y][s.x].unit = nil
      s.y = s.y+1
      board[s.y][s.x].unit = s
      color_tile(s.x, s.y, s.faction)
    end,
  },
  
  
  ["attack"] = {
    t = 0,
    show_time = false,
    sprite = 165,
    
    condition = function(s, task)
      return not dead_ids[task.target]
    end,
    
    start_task = function(s, task)
      local target = entities[task.target]
      if not target then return false end
      
      if abs(target.x-s.x)+abs(target.y-s.y)>1 then
        local way = get_path(s.x, s.y, target.x, target.y, s.faction, s)
        if #way == 0 then
          return false
        end
        
        local npos = way[1]
        local b_d = board[npos.y][npos.x]
        if b_d.unit or (b_d.building and b_d.building.faction ~= s.faction) then
          s.task = nil
          do_remove_task = false
          return true
        end
        
        board[npos.y][npos.x].unit = s
        s.task = new_task("walk", { path = {npos}})
      else
        s.task = new_task("hit", { target = task.target })
      end
      
      do_remove_task = false
      return true
    end
  },
  
  ["hit"] = {
    t = 0.5,
    shot_time = true,
    sprite = 165,
    
    task_done = function(s, task)
      local target = entities[task.target]
      if (not target) or abs(target.x-s.x)+abs(target.y-s.y)>1 then
        return
      else
        do_damage(s, target)
      end
    end
  },
  
  ["build_wall"] = {
    t = 1.0,
    show_time = true,
    cost = 10,
    sprite = 166,
    
    condition = function(s, task)
      local b_d = board[s.y][s.x]
      return (b_d.building == nil and not b_d.wall)
    end,
    
    task_done = function(s, task)
      create_building(s.x, s.y, nil, s.faction)
      add_shake(1)
    end
  },
  
  ["build_prod"] = {
    t = 10,
    show_time = true,
    cost = 50,
    sprite = 166,

    condition = function(s, task)
      local b_d = board[s.y][s.x]
      return (b_d.building == nil and not b_d.wall)
    end,
    
    task_done = function(s, task)
      create_building(s.x, s.y, task.produce, s.faction)
      add_shake(3)
    end
  },
  
  
  ["prod_res"] = {
    t = 0.5,
    show_time = true,
    cost = 20,
    sprite = 168,
    
    task_done = function(s, task)
      faction_res[s.faction] = faction_res[s.faction] + 1
      assign_task(s, task, true)
    end
  },
  
  ["prod_unit"] = {
    t = 5,
    show_time = true,
    sprite = 167,
    
    task_done = function(s, task)
      create_unit(s.x, s.y, s.faction)
      castle_print("Created unit for faction "..s.faction.."at x"..s.x.." y"..s.y)
    end
  },
  
  
  ["ressource_tile"] = {
    t = 2,
    show_time = true,
    sprite = 175
  }
}

function update_task(s)
  if s.task then
    -- task progress
    local info = task_lib[s.task.type]
    s.task_t = s.task_t + delta_time
    if s.task_t >= info.t then
      info.task_done(s, s.task)
      s.task = nil
      s.task_t = s.task_t - info.t
    end
  end
  
  if not s.task then
    ::process_next_task::
    
    local ntask = s.task_queue[1]
    if ntask then
      local info = task_lib[ntask.type]
      
      if (not info.condition) or info.condition(s, ntask) then
        do_remove_task = true
        if info.start_task then
          if not info.start_task(s, ntask) then
            if do_remove_task then
              table.remove(s.task_queue, 1)
            end
            goto process_next_task
          end
        else
          s.task = ntask
        end
      
        if do_remove_task then
          table.remove(s.task_queue, 1)
        end
      else
        table.remove(s.task_queue, 1)
        goto process_next_task
      end
    else
      s.task_t = 0
    end
  end
end

function assign_task(s, task, in_queue)
  if not task then return false end
  
  local info = task_lib[task.type]
--  if (not info.condition) or info.condition(s, task) then
    if in_queue then
      add(s.task_queue, task)
    else
      s.task_queue = {task}
    end
--    return true
--  else
--    return false
--  end
end

function new_task(type, info)
  local task = { type = type }
  if info then
    for n,v in pairs(info) do
      task[n] = v
    end
  end
  
  return task
end

function copy_task(task)
  if not task then return nil end

  local new_task = {}
  for n,v in pairs(task) do
    if n == "path" then
      new_task.path = copy_table(v)
    else
      new_task[n] = v
    end
  end
  
  return new_task
end

function clear_task_queue(s)
  s.task_queue = {}
end

function cancel_last_task(s)
  local n = #s.task_queue
  if n > 0 then
    table.remove(s.task_queue, n)
  end
end

function is_task_possible(s, task)
  local info = task_lib[task.type]
  return ((not info.condition) or info.condition(s, task))
end

function same_task(ta, tb)
  if not ta or not tb then
    return (ta == tb)
  end

  if ta.type ~= tb.type then
    return false
  end
  
  if ta.type == "walk" then
    if not tb.path then error("on tb path") end
    if not ta.path then error("on ta path") end
    if not tb.path[1] then error("on tb path 1 : "..#tb.path) end
    if not ta.path[1] then error("on ta path 1 : "..#ta.path) end
    return (ta.path[1].x == tb.path[1].x and ta.path[1].y == tb.path[1].y) 
  elseif ta.type == "walk_to" then
    return (ta.to.x == tb.to.x and ta.to.y == tb.to.y)
  elseif ta.type == "attack" or ta.type == "hit" then
    return (ta.target == tb.target)
  elseif ta.type == "build_prod" then
    return (ta.produce == tb.produce)
  end
end
