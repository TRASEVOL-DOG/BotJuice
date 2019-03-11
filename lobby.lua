


function init_lobby()
  in_lobby = true
  
  countdown = 10
end

function update_lobby()
  if server_only then
    update_lobby_server()
    return
  end
end

function draw_lobby()
  cls(23)
end



function update_lobby_server()

end