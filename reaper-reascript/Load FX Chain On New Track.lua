--[[ Load, read reaper FXChains path, click to load and FX Chain. For Windows by CrazyJ36 ]]

fx_chains_dir = os.getenv("APPDATA") .. "\\REAPER\\FXChains\\" -- change this if you're on Linux or Mac.
fx_chains = {}
gfx.y = 10

line_index = 0
function getFxChains() 
  dir = io.popen('dir "' .. fx_chains_dir .. '" /b')
  for line in dir:lines() do
    line_index = line_index + 1
    gfx.y = gfx.y + 20
    fx_chains[line_index] = {
      file = line, top = gfx.y - 19, bottom = gfx.y
    }
  end
  dir:close()
end
getFxChains()


gfx.init("Load FX Chain", 600, 300)
function main()
  mouseState = gfx.mouse_cap & 1 == 1
  if gfx.getchar() == -1 then -- kill script on window close.
    return
  end
  
  if line_index > 0 then
    for i = 1, #fx_chains, 1 do
      gfx.x = 0
      gfx.y = fx_chains[i].top
      gfx.drawstr(fx_chains[i].file)
      if mouseState and
        not lastMouseState and
        gfx.mouse_y > fx_chains[i].top and
        gfx.mouse_y < fx_chains[i].bottom then
        os.execute('start "" ' .. '"' .. fx_chains_dir .. fx_chains[i].file .. '"') -- change this if you're on Linux or Mac
        return
      end
    end
    lastMouseState = mouseState
  else 
    gfx.x = 0
    gfx.y = 0
    gfx.drawstr("No FX Chains.")
  end
  
  reaper.defer(main)
end
main()

function atExit()
  gfx.quit()
  return
end
reaper.atexit(atExit)
