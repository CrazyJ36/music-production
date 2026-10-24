dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")

reaper.ClearConsole()

section_name = "SetAliasParamPerPresetSection"
section_plugins_key = "plugins"
section_plugin_presets_key = "presets"
section_plugin_presets_params_key = "params"

if false then -- IF 'TRUE' HERE TO RESET.
  reaper.SetExtState(section_name, "", true)
  reaper.ShowConsoleMsg("RESET\n")
  return
end

plugins = {}
--[[plugins.plugin1 = { 
  preset1 = { param11 = "preset1_test", param12 = "preset1_test2" }, 
  preset2 = { param21 = "preset2_test", param22 = "preset2_test2" } 
}]]

--[[for plugin, presets in pairs(plugins) do
  reaper.ShowConsoleMsg("plugin "..plugin..":\n")
  for preset, param in pairs(presets) do
    for param, value in pairs(param) do
      reaper.ShowConsoleMsg(param..": "..value.."\n")
    end
  end
end]]


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
  reaper.ShowConsoleMsg("Error: Is an FX Added to track?\n")
  return
else 
  reaper.ShowConsoleMsg("FX Index: "..current_fx_index..", FX Name: "..current_fx_name.."\n")
end



function TableContains(tbl, x)
    for _, value in ipairs(tbl) do
        if value == x then return true end
    end
    return false
end

function GetNumPresets(track, current_fx_index)
  _, num_presets = reaper.TrackFX_GetPresetIndex(track, current_fx_index)
  reaper.ShowConsoleMsg("preset count: "..num_presets.."\n")
  return num_presets
end

function GetPresetName(track, current_fx_index) -- needs A preset to be selected in dropdown.
  local retval, current_preset_name = reaper.TrackFX_GetPreset(track, current_fx_index)
  if not retval then
    reaper.ShowConsoleMsg("Error: Does FX have any presets?\n")
    reaper.atexit()
    return
  elseif current_preset_name == "" then
    reaper.ShowConsoleMsg("Error: Is A preset selected?\n")
    reaper.atexit()
  else
    --reaper.ShowConsoleMsg("current preset name: "..current_preset_name.."\n")
    return current_preset_name
  end
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

function SetFXParameterAlias(track, current_fx_index, alias_name)
  local retval, track_state_chunk = reaper.GetTrackStateChunk(track, "", false)
  
  for param_index = 1, reaper.TrackFX_GetNumParams(track, current_fx_index) do 
  
    local fx_state_chunk = ultraschall.GetFXStateChunk(track_state_chunk)
    
    local success, altered_fx_chunk = ultraschall.AddParmAlias_FXStateChunk(fx_state_chunk, current_fx_index + 1, param_index, alias_name..param_index)
    if not success then -- if already has alias, make new.
        success, altered_fx_chunk = ultraschall.SetParmAlias2_FXStateChunk(fx_state_chunk, current_fx_index + 1, param_index, alias_name..param_index)
    end
    
    _, track_state_chunk = ultraschall.SetFXStateChunk(track_state_chunk, altered_fx_chunk)
  end
  reaper.SetTrackStateChunk(track, track_state_chunk)
  
end

function SetTable()
 
  plugins[current_fx_name] = { }

  for i = 1, GetNumPresets(track, current_fx_index) do
    new_preset_name = GetPresetName(track, current_fx_index)
    example_param_string = "Example param string!"
    plugins[current_fx_name][new_preset_name] = { [example_param_string] = "param1", preset_param2 = "param2" }
  end
  
  for plugin, presets in pairs(plugins) do
    reaper.ShowConsoleMsg("plugin: "..plugin..":\n")
    for preset, params in pairs(presets) do
      reaper.ShowConsoleMsg("preset: "..preset.."\n")
      for param, value in pairs(params) do 
        reaper.ShowConsoleMsg(param..": "..value.."\n")
      end
    end
  end
 
 
 
  --[[if not TableContains(table_of_plugins, current_fx_name) then
    table.insert(table_of_plugins, current_fx_name)
  end
  table.insert(m_table, table_of_plugins)

  for i = 1, #table_of_plugins do
    reaper.ShowConsoleMsg("table of plugins: "..table_of_plugins[i].."\n")
  end
  
  
  m_table_string = table.concat(m_table, ",")
  reaper.SetExtState(section_name, m_table_section_key, m_table_string, true)]]
end

function GetStoredData() 
  stored_table_string = reaper.GetExtState(section_name, m_table_section_key)
  if stored_table_string then
    for val in string.gmatch(stored_table_string, "([^,]+)") do
      table.insert(m_table, val)
    end
  end
end



function main() 


  --[[current_preset_name = GetPresetName(track, current_fx_index)
  if current_preset_name == "" then
    reaper.ShowConsoleMsg("Error: Current preset was empty\n")
    return
  end]]

  SetTable()
  
    --[[for index, fx_name in ipairs(m_table) do
    
      table_of_presets = {}
      num_presets = reaper.TrackFX_GetPresetIndex(track, fx_name)
      for i = 0, num_presets do
        table.insert(table_of_presets, )
      end
    
      if fx_name == current_fx_name then
      
        for index, value in ipairs(table_of_presets) do
        
          if current_preset_name == GetPresetName(track, index) then
    
            --SetFXParameterAlias(track, current_fx_index, "Test")
            break
            
          end
          
        end
      end
    end]]

end


main()






