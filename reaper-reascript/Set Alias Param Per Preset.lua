dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")

reaper.ClearConsole()

section_name = "SetAliasParamPerPresetSection"
plugins_section_key = "plugins"
presets_section_key = "presets"
plugins_section_key_value = "plugin"
presets_section_key_value = "preset"

table_of_plugins = {}
table_of_plugin_presets = {}
table_of_param_ids = {}


if false then -- IF 'TRUE' HERE TO RESET.
  table_of_plugins_string = ""
  table_of_plugin_presets_string = ""
  reaper.SetExtState(section_name, plugins_section_key, table_of_plugins_string, true)
  reaper.SetExtState(section_name, presets_section_key, table_of_plugin_presets_string, true)
  reaper.ShowConsoleMsg("RESET\n")
  return
end



track = reaper.GetSelectedTrack(0, 0)
if track == nil then 
  reaper.ShowConsoleMsg("Error: Is A Track added and selected?\n")
  return 
end

retval, _, _, current_fx_index = reaper.GetFocusedFX()
if not retval then 
  reaper.ShowConsoleMsg("Error: Couldn't get focued fx\n")
  return
end
retval, current_fx_name = reaper.TrackFX_GetFXName(track, current_fx_index)
if not retval then
  reaper.ShowConsoleMsg("Error: Couldn't get fx_name\n")
  return
else 
  reaper.ShowConsoleMsg("current_fx_index: "..current_fx_index..", FX Name: "..current_fx_name.."\n")
end


function GetStoredData() 
  stored_plugins = reaper.GetExtState(section_name, plugins_section_key)
  if stored_plugins then
    for val in string.gmatch(stored_plugins, "([^,]+)") do
      table.insert(table_of_plugins, val)
    end
  end

  stored_presets = reaper.GetExtState(section_name, presets_section_key)
  if stored_presets then
    for val in string.gmatch(stored_presets, "([^,]+)") do
      table.insert(table_of_plugin_presets, val)
    end
  end
  reaper.ShowConsoleMsg("presets table size: "..#table_of_plugin_presets.."\n")
  reaper.ShowConsoleMsg("plugins table size: "..#table_of_plugins.."\n")
    
end

function SetStoredData()
  
  if not TableContains(table_of_plugins, current_fx_name) then
    table_of_plugins[#table_of_plugins + 1] = current_fx_name
  end
  if not TableContains(table_of_plugin_presets, current_preset_name) then
    table_of_plugin_presets[#table_of_plugin_presets + 1] = current_preset_name
  end
  
  table_of_plugins_string = table.concat(table_of_plugins, ",")
  table_of_plugin_presets_string = table.concat(table_of_plugin_presets, ",")
  reaper.SetExtState(section_name, plugins_section_key, table_of_plugins_string, true)
  reaper.SetExtState(section_name, presets_section_key, table_of_plugin_presets_string, true)

end


function SetFXParameterAlias(track, current_fx_index, alias_name)
  
  retval, track_state_chunk = reaper.GetTrackStateChunk(track, "", false)
  altered_fx_chunk = ""
  for new_param_idx = 1, reaper.TrackFX_GetNumParams(track, current_fx_index) do 
  
    local fx_state_chunk = ultraschall.GetFXStateChunk(track_state_chunk)
    
    local success, altered_fx_chunk = ultraschall.AddParmAlias_FXStateChunk(fx_state_chunk, current_fx_index + 1, new_param_idx, "Test")
    if not success then -- if already has alias, make new.
        success, altered_fx_chunk = ultraschall.SetParmAlias2_FXStateChunk(fx_state_chunk, current_fx_index + 1, new_param_idx, "Test")
    end
    
    _, track_state_chunk = ultraschall.SetFXStateChunk(track_state_chunk, altered_fx_chunk)
  end
  
  reaper.SetTrackStateChunk(track, track_state_chunk)
  
end






function GetPresetName(track, current_fx_index) -- needs A preset to be selected in dropdown.
  local retval, current_preset_name = reaper.TrackFX_GetPreset(track, current_fx_index)
  if not retval then
    reaper.ShowConsoleMsg("Error: Does FX have any presets?\n")
    return
  elseif current_preset_name == "" then
    reaper.ShowConsoleMsg("Error: Is A preset selected?\n")
    return
  else
    reaper.ShowConsoleMsg("current preset name: "..current_preset_name.."\n")
    return current_preset_name
  end
end

function GetNumPresets(track, current_fx_index)
  _, num_presets = reaper.TrackFX_GetPresetIndex(track, current_fx_index)
  reaper.ShowConsoleMsg("preset count: "..num_presets.."\n")
  return num_presets
end

function TableContains(tbl, x)
    for _, value in ipairs(tbl) do
        if value == x then return true end
    end
    return false
end

function GetFXParams()
  num_params = reaper.TrackFX_GetNumParams(track, current_fx_index)
  reaper.ShowConsoleMsg("num_params: "..num_params.."\n")
  for i = 0, num_params - 1 do
    local retval, param_name = reaper.TrackFX_GetParamName(track, current_fx_index, i)
    if retval then

      table.insert(table_of_param_ids, param_name)
    else
      reaper.ShowConsoleMsg("Error getting params!\n")
      return
    end
  end
end



--GetNumPresets(track, current_fx_index) -- not needed?

--GetStoredData()

--[[GetFXParams(track, fx_id)
for index, value in ipairs(table_of_param_ids) do
  reaper.ShowConsoleMsg("index: "..index..", name: "..value.."\n")
end ]]



--[[current_preset_name = GetPresetName(track, current_fx_index) 
if current_preset_name == "" then
  reaper.ShowConsoleMsg("Error: current_preset_name is empty before setting alias\n")
  return
end]]



--param_idx = 1 -- in reasynth param_idx is 1 for attack, starts at 1. Should loop in getFxParams below
--retval, _, _ = reaper.TrackFX_GetParam(track, current_fx_index, param_idx)

-- if in table_of_presets
--[[if current_preset_name == "Loud" then
  SetFXParameterAlias(track, current_fx_index, param_idx, "Loud!")
elseif cuurrent_preset_name == "Quiet" then
  SetFXParameterAlias(track, current_fx_index, param_idx, "Quiet...")
end]]


-- Only if all functions succeded.
--SetStoredData()



SetFXParameterAlias(track, current_fx_index, nil, "Test")






