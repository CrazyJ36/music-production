reaper.ClearConsole()

dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")
dofile(reaper.GetResourcePath().."/UserPlugins/reagirl.lua")
package.path = package.path .. ";" .. reaper.GetResourcePath().."/Scripts/crazyj36-reaper-reascript/" .. "?.lua"
json = require("json")

stored_section_name = "SetAliasParamPerPresetSection"
stored_settings_key = "settings"
if false then -- IF 'TRUE' HERE TO RESET.
  reaper.SetExtState(stored_section_name, stored_settings_key, "", true)
  reaper.ShowConsoleMsg("RESET!\n")
  return
end

settings_table = {}
stored_settings_string = reaper.GetExtState(stored_section_name, stored_settings_key)
if stored_settings_string and stored_settings_string ~= "" then
  settings_table = json.decode(stored_settings_string)
  reaper.ShowConsoleMsg("Loading your settings. Stored size: "..#settings_table.."\n")
  
  for index, value in ipairs(settings_table) do
    reaper.ShowConsoleMsg("stored settings "..index..": "..value.."\n")
  end
else 
  reaper.ShowConsoleMsg("No stored settings found.\n")
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
retval, current_fx = reaper.TrackFX_GetFXName(track, current_fx_index)
if not retval then
  reaper.ShowConsoleMsg("Error: Is an FX Added to track?\n")
  return
else 
  reaper.ShowConsoleMsg("FX Index: "..current_fx_index..", FX Name: "..current_fx.."\n")
end
retval, num_presets = reaper.TrackFX_GetPresetIndex(track, current_fx_index)
if retval then
  if num_presets > 0 then
    reaper.ShowConsoleMsg("num presets: "..num_presets.."\n")
  else 
    reaper.ShowConsoleMsg("Error: Does this FX have any presets?\n")
    return
  end
else
  reaper.ShowConsoleMsg("Error: Couldn't get number of presets\n")
  return
end
retval, current_preset = reaper.TrackFX_GetPreset(track, current_fx_index)
if current_preset ~= "" then 
  reaper.ShowConsoleMsg("Current preset: "..current_preset.."\n")
else
 reaper.ShowConsoleMsg("Error: Is A preset selected?\n")
 return
end
num_params = reaper.TrackFX_GetNumParams(track, current_fx_index)


settings_table[current_fx] = settings_table[current_fx] or {}
settings_table[current_fx][current_preset] = settings_table[current_fx][current_preset] or {}
for i = 0, num_params - 1 do
  local retval, param = reaper.TrackFX_GetParamName(track, current_fx_index, i)
  if retval then
    settings_table[current_fx][current_preset][param] = param
  else 
    reaper.ShowConsoleMsg("Error: Couldn't get param names.\n")
    return
  end
end

json_string = json.encode(settings_table)
reaper.ShowConsoleMsg("Saving: "..json_string.."\n")
reaper.SetExtState(stored_section_name, stored_settings_key, json_string, true)

--[[settings_json = json.encode(settings_table)
reaper.(stored_section_name, stored_settings_key, settings_json, true)
for item in string.gmatch(default_params_string, "([^;]+)") do
  table.insert(default_params, item)
end]]

--[[function GetCurrentPresetIndex() 
  index, number_of_presets = reaper.TrackFX_GetPresetIndex(track, current_fx_index)
  if index ~= -1 then
    reaper.ShowConsoleMsg("current preset index: "..retval..", num presets: "..number_of_presets.."\n")
  else 
    reaper.ShowConsoleMsg("Error: Couldn't get current preset index\n")
    exit = true
  end
end]]


--[[function GetNumPresets(track, current_fx_index)
  _, num_presets = reaper.TrackFX_GetPresetIndex(track, current_fx_index)
  reaper.ShowConsoleMsg("preset count: "..num_presets.."\n")
  return num_presets
end]]

--[[function GetFXParams()
  reaper.ShowConsoleMsg("num_params: "..num_params.."\n")
  for i = 0, num_params - 1 do
    local _, param_name = 
    table.insert(plugins_table.presets, reaper.TrackFX_GetParamName(track, current_fx_index, i))
  end
  return table_of_params
end]]



--[[input_ids = {}
function ButtonApply_Run(pressed_button_id)
  for index, input_id in ipairs(input_ids) do
    table.insert(current_params, reagirl.Inputbox_GetText(input_id))
  end
  for index, custom_param in ipairs(current_params) do
    reaper.ShowConsoleMsg("Custom: "..custom_param.."\n")
  end
  reaper.MB("Check your control surface!", "Done", 0)
end

reagirl.Gui_New()
reagirl.Button_Add(nil, nil, 0, 0, "Apply", "Apply changes and close dialog.", ButtonApply_Run)

input_box_description = "Set new alias name for param "
for i = 1, num_params do
  reagirl.NextLine()
  input_id = reagirl.Inputbox_Add(nil, nil, 300, default_params[i]..": ", 150, input_box_description..i..".", current_params[i], nil, nil)
  table.insert(input_ids, input_id)
end

params_dialog_title = "Customize param names for current FX and preset."
params_dialog_desc = "This dialog allows to enter custom aliases for FX params per-preset."
reagirl.Gui_Open("Set Alias Param Per Preset", false, params_dialog_title, params_dialog_desc, 350, 600)
function RunParamsDialog() 
  reagirl.Gui_Manage()
  if reagirl.Gui_IsOpen() then
    reaper.defer(RunParamsDialog)
  end
end]]
--RunParamsDialog() -- TODO: run this if midi button pressed. Show on script load 'you don't have A midi button assigned to set custom names, set one?'




--[[function SetFXParameterAlias(track, current_fx_index, alias_name)
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

--plugins = {}
function SetTables()

  plugins[current_fx_name] = {}
  plugins[current_fx_name][current_preset_name] = {}
  plugins[current_fx_name][current_preset_name][current_params] = {}
  
  for index, value in ipairs(current_params) do 
    plugins[current_fx_name][current_preset_name][value] = value
  end
  
  for plugin, presets in pairs(plugins) do
    reaper.ShowConsoleMsg("table plugin: "..plugin..":\n")
    for preset, params in pairs(presets) do
      reaper.ShowConsoleMsg("table preset: "..preset.."\n")
      for index, param in ipairs(current_params) do 
        reaper.ShowConsoleMsg("table param: "..param.."\n")
      end
    end
  end
  
  settings_table.presets.params = GetFxParams()
  
  --current_params_string = table.concat(current_params, ";")
  --reaper.SetExtState(section_name, section_plugins_key, current_params_string)
end]]






