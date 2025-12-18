--[[ Load, read reaper FXChains path, click to load and FX Chain. For Windows by CrazyJ36 ]]

function getFxChains()
  fx_chains_dir = os.getenv("APPDATA") .. "\\REAPER\\FXChains\\" -- change this if you're on Linux or Mac.
  fx_chains = {}
  dir_line_index = 0
  next_item = 18
  dir = io.popen('dir "' .. fx_chains_dir .. '" /b')
  for line in dir:lines() do
    dir_line_index = dir_line_index + 1
    fx_chains[dir_line_index] = {
      file = line, 
      friendly_name = line:sub(1, -10),
      top = next_item,
      bottom = next_item + 16
    }
    next_item = next_item + 17
  end
  dir:close()
end
getFxChains()

window_width = 500
window_height = 200
gfx.init("Load FX Chain", window_width, window_height)
gfx.setfont(1, "Arial", 16)
refreshButton = {0, 0, 48, 16}
function mainLoop()
  if gfx.getchar() == -1 then
    return
  end
  
  if dir_line_index == 0 then
    gfx.x = 0
    gfx.y = 0
    gfx.drawstr("No FX Chains")
  else
    gfx.x = 1
    gfx.y = 0
    gfx.rect(
      refreshButton[1],
      refreshButton[2],
      refreshButton[3],
      refreshButton[4],
      false
    )
    gfx.drawstr("Refresh")
    
    for i = 1, #fx_chains, 1 do
      gfx.x = 0
      gfx.y = fx_chains[i].top
      gfx.drawstr(fx_chains[i].friendly_name)
      gfx.line(0, fx_chains[i].bottom, window_width, fx_chains[i].bottom)
    
      mouseState = gfx.mouse_cap & 1 == 1
      if mouseState and
        not lastMouseState and
        gfx.mouse_y > fx_chains[i].top and
        gfx.mouse_y < fx_chains[i].bottom then
          os.execute('start "" ' .. -- change this if you're on Linux or Mac
            '"' .. fx_chains_dir .. fx_chains[i].file .. '"'
          )
          return
      elseif mouseState and
        not lastMouseState and
        gfx.mouse_x < refreshButton[3] and
        gfx.mouse_y < refreshButton[4] then
          getFxChains()
          break
      end
      
    end
    lastMouseState = mouseState
  end
  
  reaper.defer(mainLoop)
end
mainLoop()

function atExit()
  gfx.quit()
end
reaper.atexit(atExit)
