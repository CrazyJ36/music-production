dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")

reaper.ClearConsole()

section_name = "SetAliasParamPerPresetSection"
section_plugins_key = "plugins"
section_plugin_presets_key = "presets"
section_plugin_presets_params_key = "params"
default_params_key = "default_params"

if false then -- IF 'TRUE' HERE TO RESET.
  reaper.SetExtState(section_name, "", true)
  reaper.ShowConsoleMsg("RESET\n")
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

num_params = reaper.TrackFX_GetNumParams(track, current_fx_index)



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
    reaper.ShowConsoleMsg("current preset name: "..current_preset_name.."\n")
    return current_preset_name
  end
end

function GetFXParams()
  table_of_params = {}
  reaper.ShowConsoleMsg("num_params: "..num_params.."\n")
  for i = 0, num_params - 1 do
    local retval, param_name = reaper.TrackFX_GetParamName(track, current_fx_index, i)
    if retval then
      table.insert(table_of_params, param_name)
    else
      reaper.ShowConsoleMsg("Error getting params!\n")
      return
    end
  end
  return table_of_params
end

function GetDefaultParams()
  default_params_string = reaper.GetExtState(section_name, default_params_key)
  if default_params_string == nil or default_params_string == "" then
    reaper.ShowConsoleMsg("Setting default params...\n")
    for index, value in ipairs(GetFXParams()) do
      default_params_string = default_params_string..","..value
    end
    reaper.ShowConsoleMsg("default: "..default_params_string.."\n")
    reaper.SetExtState(section_name, default_params_key, default_params_string, true)
  else
    reaper.ShowConsoleMsg("default params alread set!\n")
  end
  default_params_table = {}
  for item in string.gmatch(default_params_string, "([^,]+)") do
    table.insert(default_params_table, item)
  end
  return default_params_table
end


params_dialog_title = "Customize param names for current FX and preset."
default_params = GetDefaultParams()
current_params = GetFXParams()
custom_params = {}
for index, item in ipairs(current_params) do
  table.insert(custom_params, item)
end
ctx = reaper.ImGui_CreateContext("Set Alias Param Per Preset")
function SetCustomNames() 
  --retval, custom_params_string = reaper.GetUserInputs(params_dialog_title, num_params, GetDefaultParams(), current_params_string) 
  
  local visible, open = reaper.ImGui_Begin(ctx, params_dialog_title, true)
  if visible then
    
    for i = 1, num_params do
      new_alias = current_params[i]
      changed, new_alias = reaper.ImGui_InputText(ctx, "Default: "..default_params[i], new_alias or current_params[i])
      if changed then
        custom_params[i] = new_alias
      else 
        custom_params[i] = current_params[i]
      end
    end
    
    if reaper.ImGui_Button(ctx, "Apply") then
      open = false
    end
    reaper.ImGui_End(ctx)
  end
  if open then 
    reaper.defer(SetCustomNames)
  end
end

reaper.defer(SetCustomNames)

current_params_string = table.concat(current_params, ";")
for index, custom_param in ipairs(custom_params) do
  reaper.ShowConsoleMsg("Old param: "..current_params[index]..", New Param: "..custom_param.."\n")
end
custom_params_string = ""
for item in string.gmatch(custom_params_string, "([^;]+)") do
  --table.insert(custom_params, item)
  reaper.ShowConsoleMsg("custom_param: "..item.."\n")
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
  plugins[current_fx_name] = {}
  for i = 1, GetNumPresets(track, current_fx_index) do
    new_preset_name = GetPresetName(track, current_fx_index)
    plugins[current_fx_name][new_preset_name] = GetFXParams()
  end
  for plugin, presets in pairs(plugins) do
    reaper.ShowConsoleMsg("plugin: "..plugin..":\n")
    for preset, params in pairs(presets) do
      reaper.ShowConsoleMsg("preset: "..preset.."\n")
      for index, param in ipairs(params) do 
        --reaper.ShowConsoleMsg(param.."\n")
      end
    end
  end
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






