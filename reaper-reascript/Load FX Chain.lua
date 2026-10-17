--[[ Load and FX Chain for Windows by CrazyJ36 ]]
help_text = "Use mouse, MIDI button, or key up/down to select.\nUse click, another MIDI button or enter key to open ."
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
button_height = 24
button_width = 64
gfx.init("Load FX Chain", window_width, window_height)
gfx.setfont(1, "Arial", 16)
fxListStartY = 52
refresh_button_graph = {0, 42, button_width, button_height, 15}
scroll_button_cc_graph = {68, 42, button_width, button_height, 15}
select_button_cc_graph = {136, 42, button_width, button_height, 15}
total_sleep_time = os.clock() + 4
selected_fx = 1
triggered = false
scroll_button_cc = -1
select_button_cc = -1
scroll_y = 0
scroll_offset = 0
max_scroll = -1
scroll_pos = 0

function mainLoop()

  currentInputEvent = {reaper.MIDI_GetRecentInputEvent(0)}
  
  if reaper.GetExtState("scroll_button_cc", "file") == nil then
    scroll_button_cc = 0
  else 
    scroll_button_cc = reaper.GetExtState("scroll_button_cc", "file")
  end
  if reaper.GetExtState("select_button_cc", "file") == nil then
    select_button_cc = 0
  else 
    select_button_cc = reaper.GetExtState("select_button_cc", "file")
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
    gfx.y = scroll_y
    gfx.x = 0
    gfx.drawstr(help_text)
    gfx.line(0, 36 + scroll_y, gfx.w, 36 + scroll_y)
   
    gfx.roundrect(
      refresh_button_graph[1],
      refresh_button_graph[2] + scroll_y,
      refresh_button_graph[3],
      refresh_button_graph[4],
      refresh_button_graph[5]
    )
    gfx.roundrect(
      scroll_button_cc_graph[1],
      scroll_button_cc_graph[2] + scroll_y,
      scroll_button_cc_graph[3],
      scroll_button_cc_graph[4],
      scroll_button_cc_graph[5]
    )
    gfx.roundrect(
      select_button_cc_graph[1],
      select_button_cc_graph[2] + scroll_y,
      select_button_cc_graph[3],
      select_button_cc_graph[4],
      select_button_cc_graph[5]
    )
    gfx.x = refresh_button_graph[1] + 10
    gfx.y = refresh_button_graph[2] + 4 + scroll_y
    gfx.drawstr("Refresh")
    gfx.x = scroll_button_cc_graph[1] + 5
    gfx.y = scroll_button_cc_graph[2] + 4 + scroll_y
    gfx.drawstr("Scroll CC")
    gfx.x = select_button_cc_graph[1] + 5
    gfx.y = select_button_cc_graph[2] + 4 + scroll_y
    gfx.drawstr("Select CC")
    
    gfx.line(
      0, 
      fx_chains[selected_fx].bottom + fxListStartY + scroll_y,
      gfx.measurestr(fx_chains[selected_fx].friendly_name),
      fx_chains[selected_fx].bottom + fxListStartY + scroll_y
    ) -- bottom
    gfx.line(
      0,
      fx_chains[selected_fx].top + fxListStartY + scroll_y,
      0,
      fx_chains[selected_fx].bottom + fxListStartY + scroll_y
    ) -- side

    for i = 1, #fx_chains, 1 do
      gfx.x = 1
      gfx.y = fx_chains[i].top + fxListStartY + scroll_y
      gfx.drawstr(fx_chains[i].friendly_name)
      
      -- left mouse button clicked.
      if gfx.mouse_cap & 1 == 1 then
        mx = gfx.mouse_x
        my = gfx.mouse_y
        
        -- load fx
        if mx < gfx.measurestr(fx_chains[i].friendly_name) and
        my > fx_chains[i].top + fxListStartY + scroll_y and
        my < fx_chains[i].bottom + fxListStartY + scroll_y then
          selected_fx = i
          startFxLoad(selected_fx) 
          return
        
        -- refresh clicked
        elseif mx < refresh_button_graph[3] and
        mx > refresh_button_graph[1] and
        my > refresh_button_graph[2] and
        my < refresh_button_graph[4] then
          getFxChains()
          reaper.ShowConsoleMsg("clicked refresh")
          break
        
        -- scroll_button_cc clicked
        elseif mx < (scroll_button_cc_graph[1] + scroll_button_cc_graph[3]) and 
        mx > scroll_button_cc_graph[1] + scroll_y  and
        my > scroll_button_cc_graph[2] + scroll_y and
        my < scroll_button_cc_graph[4] + scroll_y then
          retval, scroll_cc_input = reaper.GetUserInputs("Desired Scroll CC:", 1, "", reaper.GetExtState("scroll_button_cc", "file"))
          scroll_button_cc = scroll_cc_input
          if retval == true then
            reaper.SetExtState("scroll_button_cc", "file", scroll_cc_input, true)
          end
          break
        elseif mx < (select_button_cc_graph[1] + select_button_cc_graph[3]) and -- select button
        mx > select_button_cc_graph[1] + scroll_y  and
        my > select_button_cc_graph[2] + scroll_y and
        my < select_button_cc_graph[4] + scroll_y  then
          reaper.ShowConsoleMsg("done")
        end
      end
    end
    
    -- down key
    down = char == 1685026670 or
    (currentInputEvent[2]:byte(2) == tonumber(scroll_button_cc) and
    currentInputEvent[1] ~= 0 and
    currentInputEvent[2]:byte(1) & 0xF0 == 176 and
    triggered == false and
    currentInputEvent[2]:byte(3) == 127)

    --reaper.ShowConsoleMsg("down: "..tostring(down).."\n")
    
    if down and fx_chains[selected_fx + 1] ~= nil then
      selected_fx = selected_fx + 1
      triggered = true
      
    -- loop selection down key.
    elseif down and fx_chains[selected_fx + 1] == nil then
      selected_fx = 1
      triggered = true
   
    -- up key
    elseif char == 30064 and
    fx_chains[selected_fx - 1] ~= nil then 
      selected_fx = selected_fx - 1
      
    -- enter/select
    elseif char == 13 or 
    (currentInputEvent[2]:byte(2) == 115 and
    currentInputEvent[1] ~= 0 and
    currentInputEvent[2]:byte(1) & 0xF0 == 176 and
    triggered == false and
    currentInputEvent[2]:byte(3) == 127) then
      triggered = true
      startFxLoad(sel-ected_fx)
      reaper.SetExtState("reopen", "file", "false", true)
      return
    end
    
    -- scroll
    max_scroll = math.max(0, fx_chains[#fx_chains].bottom - 144)
    if gfx.mouse_wheel ~= 0 then 
      
      scroll_y = scroll_y + (gfx.mouse_wheel / 120) * 20
      scroll_pos = scroll_pos + 10
      
      if gfx.mouse_wheel < 0 then
        scroll_pos = scroll_pos + gfx.h * (10 / 100)
      elseif gfx.mouse_wheel > 0 then
        scroll_pos = scroll_pos - gfx.h * (10 / 100)
      end
      
      if scroll_y > 0  then
         scroll_y = 0 
         scroll_pos = 0
      elseif scroll_y < -max_scroll then
        scroll_y = -max_scroll
        scroll_pos = window_height - 64
      end
      
      gfx.mouse_wheel = 0
    end
    
    gfx.rect(gfx.w - 8, scroll_pos, 8, 64)
  
      
  end

  reaper.defer(mainLoop)
  
end

 mainLoop()
 
function atExit()
  gfx.quit()
end
reaper.atexit(atExit)
