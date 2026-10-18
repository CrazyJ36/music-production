--[[ Load and FX Chain for Windows by CrazyJ36 ]]
-- don't open again while add_fx/select button is still pressed
if reaper.GetExtState("reopen", "file") == "false" then
  reaper.SetExtState("reopen", "file", "true", true)
  return
end

help_text = "Use mouse wheel, MIDI CC, or key up/down to select.\nUse click, another MIDI button or enter key to launch.\n"
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

  track = reaper.GetSelectedTrack2(0, 0, true)
  if track == nil then
    reaper.Main_OnCommand(40702, 0) -- add track at end than it will be selected.
    track = reaper.GetTrack(0, reaper.GetNumTracks() - 1)   
  end
  
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

button_height = 24
button_width = 64
button_radius = 15
button_start_y = 42
gfx.init("Load FX Chain", 500, 200)
window_height = gfx.h
gfx.setfont(1, "Arial", 16)
fx_list_start_y = 48
refresh_button_graph = {0, button_start_y, button_width, button_height, button_radius}
scroll_button_cc_graph = {68, button_start_y, button_width, button_height, button_radius}
select_button_cc_graph = {136, button_start_y, button_width, button_height, button_radius}
total_sleep_time = os.clock() + 4
selected_fx = 1
scroll_button_cc = -1
select_button_cc = -1
max_scroll = -1
button_pressed = false
last_inputValue = -1
last_inputCC = -1
scroll_y = 0
scrollbar_start = 0

-- set nav button CCs
if reaper.GetExtState("scroll_button_cc", "file") ~= nil then
  scroll_button_cc = reaper.GetExtState("scroll_button_cc", "file")
else 
  scroll_button_cc = 0
end
if reaper.GetExtState("select_button_cc", "file") ~= nil then
  select_button_cc = reaper.GetExtState("select_button_cc", "file")
else 
  select_button_cc = 0
end

function mainLoop()
  
  -- get last midi input
  currentInputEvent = {reaper.MIDI_GetRecentInputEvent(0)}
  inputSuccess = currentInputEvent[1] > 0
  isCC = currentInputEvent[2]:byte(1) & 0xF0 == 176
  cc = currentInputEvent[2]:byte(2)
  inputValue = currentInputEvent[2]:byte(3)
  
  if inputValue ~= last_inputValue or cc ~= last_inputCC then
    button_pressed = false
  end
  
  -- window closed
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
    -- draw butons
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
    gfx.x = select_button_cc_graph[1] + 3
    gfx.y = select_button_cc_graph[2] + 4 + scroll_y
    gfx.drawstr("Select CC")
    -- draw lines around fx selection
    gfx.line(
      0, 
      fx_chains[selected_fx].bottom + fx_list_start_y + scroll_y,
      gfx.measurestr(fx_chains[selected_fx].friendly_name),
      fx_chains[selected_fx].bottom + fx_list_start_y + scroll_y
    ) -- bottom
    gfx.line(
      0,
      fx_chains[selected_fx].top + fx_list_start_y+ scroll_y,
      0,
      fx_chains[selected_fx].bottom + fx_list_start_y + scroll_y
    ) -- side

    -- draw fx list and catch mouse
    mouse_state = gfx.mouse_cap & 1 == 1
    for i = 1, #fx_chains, 1 do
      gfx.x = 1
      gfx.y = fx_chains[i].top + fx_list_start_y + scroll_y
      gfx.drawstr(fx_chains[i].friendly_name)
      
      -- left mouse button clicks.
      if mouse_state and not last_mouse_state then
        mx = gfx.mouse_x
        my = gfx.mouse_y
        
        -- refresh clicked
        if mx < refresh_button_graph[3] and
        mx > refresh_button_graph[1] and
        my > refresh_button_graph[2] + scroll_y and
        my < refresh_button_graph[4] + refresh_button_graph[2] then
          getFxChains()
          break
        
        -- scroll_button_cc setter clicked
        elseif mx < (scroll_button_cc_graph[3] + scroll_button_cc_graph[1]) and 
        mx > scroll_button_cc_graph[1]  and 
        my > scroll_button_cc_graph[2] + scroll_y and
        my < scroll_button_cc_graph[4] + scroll_button_cc_graph[2] then
          retval, scroll_cc_input = reaper.GetUserInputs("Desired Scroll CC:", 1, "", reaper.GetExtState("scroll_button_cc", "file"))
          if retval == true then
            scroll_button_cc = scroll_cc_input
            reaper.SetExtState("scroll_button_cc", "file", scroll_cc_input, true)
          end
          break
          
        -- select_button_cc setter clicked
        elseif mx < (select_button_cc_graph[1] + select_button_cc_graph[3]) and
        mx > select_button_cc_graph[1]  and
        my > select_button_cc_graph[2] + scroll_y and
        my < select_button_cc_graph[4] + select_button_cc_graph[3] then
          retval, select_cc_input = reaper.GetUserInputs("Number Entry", 1, "Desired Select CC: ", reaper.GetExtState("select_button_cc", "file"))
          if retval == true then
            select_button_cc = select_cc_input
            reaper.SetExtState("select_button_cc", "file", select_cc_input, true)
          end
          break
        end
          
      end -- end checking mouse state
     
    end -- end of for loop
    last_mouse_state = mouse_state
    
    -- highlight next fx and scroll if at end of window
    if button_pressed == false and
    cc == tonumber(scroll_button_cc) and
    inputSuccess and isCC and inputValue == 127 then
      if fx_chains[selected_fx + 1] ~= nil then
        selected_fx = selected_fx + 1
        
        fx_height_difference = math.abs(fx_chains[selected_fx].bottom - fx_chains[selected_fx].top)
        if fx_chains[selected_fx].bottom + 36 > gfx.h then
          scroll_y = scroll_y - fx_height_difference
          scrollbar_start = math.abs(scroll_y)
        end
        
      else
        selected_fx = 1
        scroll_y = 0
        scrollbar_start = 0
      end
      button_pressed = true
      last_inputCC = tonumber(scroll_button_cc)
      last_inputValue = inputValue
      
    -- select fx button
    elseif button_pressed == false and cc == tonumber(select_button_cc) and
    inputSuccess and isCC and inputValue == 127 then
      startFxLoad(selected_fx)
      reaper.SetExtState("reopen", "file", "false", true)
      button_pressed = true
      last_inputCC = tonumber(select_button_cc)
      last_inputValue = inputValue
      return
    end
  
    gfx.rect(gfx.w - 8, scrollbar_start, 8, gfx.h)

  end

  reaper.defer(mainLoop)
  
end

mainLoop()
 
function atExit()
  gfx.quit()
end
reaper.atexit(atExit)
