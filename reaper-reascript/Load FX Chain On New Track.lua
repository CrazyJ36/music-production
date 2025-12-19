--[[ Load, read reaper FXChains path, click to load and FX Chain. For Windows by CrazyJ36 ]]
reaper.ClearConsole()

fx_chains = {}
fx_chains_dir = os.getenv("APPDATA") .. "\\REAPER\\FXChains\\" -- change this if you're on Linux or Mac.

item_height = 16
function getFxChains()
  local dir_line_index = 0
  local next_item_top = 18
  local dir = io.popen('dir "' .. fx_chains_dir .. '" /b')
  for line in dir:lines() do
    dir_line_index = dir_line_index + 1
    next_item_top = next_item_top + item_height
    fx_chains[dir_line_index] = {
      file = line, 
      friendly_name = "- " .. line:sub(1, -10),
      top = next_item_top,
      bottom = next_item_top + item_height
    }
  end
  dir:close()
end
getFxChains()

function startFxLoad(chain)
  os.execute('start "" ' .. -- change this if you're on Linux or Mac
    '"' .. fx_chains_dir .. fx_chains[chain].file .. '"'
  )
end

window_width = 500
window_height = 200
gfx.init("Load FX Chain", window_width, window_height)
gfx.setfont(1, "Arial", 16)
refreshButton = {0, 0, 52, 16, 50}
total_sleep_time = os.clock() + 4
selected_fx = 1
function mainLoop()
  local char = gfx.getchar()
  if char == -1 then
    return
  end

  if #fx_chains == 0 then
    local remaining_time = total_sleep_time - os.clock()
    local seconds = math.floor(string.format("%.4f", remaining_time))
    if seconds == 0 then
      return
    end
    gfx.x = 0
    gfx.y = 0
    gfx.drawstr("No FX Chains... " .. seconds, 1 | 4, gfx.w, gfx.h)
  else
    gfx.y = 0
    gfx.x = 0
    gfx.drawstr("Help: Click or press Keyboard Up/Down, Enter.", 2, gfx.w, gfx.h)
    gfx.x = 5
    gfx.y = 0
    gfx.roundrect(
      refreshButton[1],
      refreshButton[2],
      refreshButton[3],
      refreshButton[4],
      refreshButton[5]
    )
    gfx.drawstr("Refresh")
    
    if char == 1685026670 and fx_chains[selected_fx + 1] ~= nil then -- down
      selected_fx = selected_fx + 1
    elseif char == 30064 and fx_chains[selected_fx - 1] ~= nil then -- up
      selected_fx = selected_fx - 1
    elseif char == 13 then
      startFxLoad(selected_fx)
      return
    end
    
    for i = 1, #fx_chains, 1 do
      gfx.x = 1
      gfx.y = fx_chains[i].top
      gfx.drawstr(fx_chains[i].friendly_name)
      
      if gfx.mouse_cap & 1 == 1 and 
        gfx.mouse_y > fx_chains[i].top and
        gfx.mouse_y < fx_chains[i].bottom then
          startFxLoad(i) 
          return
      elseif gfx.mouse_cap & 1 == 1 and 
        gfx.mouse_x < refreshButton[3] and
        gfx.mouse_y < refreshButton[4] then
          getFxChains()
          break
      end
    end
    
    gfx.line(0, fx_chains[selected_fx].bottom, gfx.measurestr(fx_chains[selected_fx].friendly_name), fx_chains[selected_fx].bottom) -- bottom
    gfx.line(0, fx_chains[selected_fx].top,  0, fx_chains[selected_fx].bottom) -- side
    
  
  end
  
  reaper.defer(mainLoop)
end
mainLoop()

function atExit()
  gfx.quit()
  reaper.ShowConsoleMsg("Killed\n")
end
reaper.atexit(atExit)
