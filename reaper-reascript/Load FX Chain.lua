--[[ Load and FX Chain for Windows by CrazyJ36 ]]
help_text = "Click or press Keyboard Up/Down, Enter."
fx_chains_dir = os.getenv("APPDATA") .. "\\REAPER\\FXChains\\" -- change this if you're on Linux or Mac.

function getFxChains()
  fx_chains = {}
  local dir_line_index = 0
  local next_item_top = 4
  local item_height = 18
  local dir = io.popen('dir "' .. fx_chains_dir .. '" /b')
  for line in dir:lines() do
    dir_line_index = dir_line_index + 1
    next_item_top = next_item_top + item_height
    fx_chains[dir_line_index] = {
      file = line, 
      friendly_name = line:sub(1, -10),
      top = next_item_top,
      bottom = next_item_top + item_height
    }
  end
  dir:close()
end
getFxChains()

function startFxLoad(selected_fx)
  local track = reaper.GetSelectedTrack2(0, 0, true)
  --if track == nil then -- add track at end
    reaper.Main_OnCommand(40702, 0)
    local track = reaper.GetTrack(0, reaper.GetNumTracks() - 1)
  --end
  
  local old_chunk = select(2, reaper.GetTrackStateChunk(track, "", false))
    
  local fx_chain_block_start = "<FXCHAIN\n"
  local blocks_end = ">\n"
  
  local file = fx_chains_dir .. fx_chains[selected_fx].file
  local file_loader = io.open(file, 'r')
  local file_text = file_loader:read('*a')
  file_loader:close()
  
  local new_chunk = nil
  if old_chunk:find(fx_chain_block_start) ~= nill then
    new_chunk = old_chunk:gsub(blocks_end .. blocks_end, "") .. 
      file_text .. blocks_end .. blocks_end
  else
    new_chunk = old_chunk:sub(1, - 3) .. fx_chain_block_start .. 
      file_text .. blocks_end .. blocks_end
  end
  reaper.SetTrackStateChunk(track, new_chunk, true)
end

window_width = 500
window_height = 200
gfx.init("Load FX Chain", window_width, window_height)
gfx.setfont(1, "Arial", 16)
refresh_button = {0, 0, 64, 24, 15}
scroll_button_cc = {64, 0, 64, 24, 15}
total_sleep_time = os.clock() + 4
selected_fx = 1
cc = -1
triggered = false

scroll_cc = -1

function mainLoop()

  currentInputEvent = {reaper.MIDI_GetRecentInputEvent(0)}
  cc = currentInputEvent[2]:byte(2)
  
  if reaper.GetExtState("scroll_cc", "file") == nil then
    scroll_cc = 0
  else 
    scroll_cc = reaper.GetExtState("scroll_cc", "file")
  end
  
  if reaper.GetExtState("reopen", "file") == "false" then
    reaper.ShowConsoleMsg("not reopening")
    reaper.SetExtState("reopen", "file", "true", true)
    return
  end

  if currentInputEvent[2]:byte(3) == 0 then
    triggered = false
  end
  
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
    gfx.drawstr(help_text, 2, gfx.w, gfx.h)
    
    gfx.roundrect(
      refresh_button[1],
      refresh_button[2],
      refresh_button[3],
      refresh_button[4],
      refresh_button[5]
    )
    gfx.roundrect(
      scroll_button_cc[1],
      scroll_button_cc[2],
      scroll_button_cc[3],
      scroll_button_cc[4],
      scroll_button_cc[5]
    )
    gfx.x = refresh_button[1] + 10
    gfx.y = refresh_button[2] + 4
    gfx.drawstr("Refresh")
    
    
    gfx.x = scroll_button_cc[1] + 5
    gfx.y = scroll_button_cc[2] + 4
    gfx.drawstr("Scroll CC")
    
    gfx.line(
      0, 
      fx_chains[selected_fx].bottom,
      gfx.measurestr(fx_chains[selected_fx].friendly_name),
      fx_chains[selected_fx].bottom
    ) -- bottom
    gfx.line(
      0,
      fx_chains[selected_fx].top,
      0,
      fx_chains[selected_fx].bottom
    ) -- side

    for i = 1, #fx_chains, 1 do
      gfx.x = 1
      gfx.y = fx_chains[i].top
      gfx.drawstr(fx_chains[i].friendly_name)
      
      if gfx.mouse_cap & 1 == 1 then
        mx = gfx.mouse_x
        my = gfx.mouse_y
        
        if mx < gfx.measurestr(fx_chains[i].friendly_name) and
        my > fx_chains[i].top and
        my < fx_chains[i].bottom then
          selected_fx = i
          startFxLoad(i) 
          return
        
        elseif mx < refresh_button[3] and -- refresh under mouse
        mx > refresh_button[1] and
        my > refresh_button[2] and
        my < refresh_button[4] then
          getFxChains()
          break
        
        -- scroll_button_cc = {64, 0, 64, 24, 15}
        elseif mx < (scroll_button_cc[1] + scroll_button_cc[3]) and -- scroll_button_cc under mouse
          mx > scroll_button_cc[1] and
          my > scroll_button_cc[2] and
          my < scroll_button_cc[4] then
            retval, user_input = reaper.GetUserInputs("Desired Scroll CC:", 1, "", reaper.GetExtState("scroll_cc", "file"))
            scroll_cc = user_input
            reaper.SetExtState("scroll_cc", "file", user_input, true)
            break
        end
      end
    end
    
    
    
    if (char == 1685026670 or -- down
    (cc == tonumber(scroll_cc)) and
    currentInputEvent[1] ~= 0 and
    currentInputEvent[2]:byte(1) & 0xF0 == 176 and
    triggered == false and
    currentInputEvent[2]:byte(3) == 127) and 
    fx_chains[selected_fx + 1] ~= nil then -- down
      if selected_fx + 1 > reaper.CountTracks(0) then
        reaper.ShowConsoleMsg("looping")
        selected_fx = 1
      else 
        selected_fx = selected_fx + 1
      end
      triggered = true
      
    elseif char == 30064 and -- up
    fx_chains[selected_fx - 1] ~= nil then 
      selected_fx = selected_fx - 1
      
    elseif char == 13 or -- enter/select
    (cc == 115 and
    currentInputEvent[1] ~= 0 and
    currentInputEvent[2]:byte(1) & 0xF0 == 176 and
    triggered == false and
    currentInputEvent[2]:byte(3) == 127) then
      triggered = true
      startFxLoad(selected_fx)
      reaper.SetExtState("reopen", "file", "false", true)
      return
    end
    
  end

  reaper.defer(mainLoop)
  
end

 mainLoop()
 
function atExit()
  gfx.quit()
end
reaper.atexit(atExit)
