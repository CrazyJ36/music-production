reaper.ClearConsole()

stored_section_name = "SetAliasParamPerPresetSection"
stored_settings_key = "settings"

if false then -- IF 'TRUE' HERE TO RESET.
  reaper.DeleteExtState(stored_section_name, stored_settings_key, false)
  reaper.ShowConsoleMsg("RESET!\n")
  return
end

dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")
dofile(reaper.GetResourcePath().."/UserPlugins/reagirl.lua")
package.path = package.path .. ";" .. reaper.GetResourcePath().."/Scripts/crazyj36-reaper-reascript/" .. "?.lua"
json = require("json")




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


if reaper.HasExtState(stored_section_name, stored_settings_key) then
  reaper.ShowConsoleMsg("Loading stored data.\n")
  stored_settings_string = reaper.GetExtState(stored_section_name, stored_settings_key)
  settings_table = json.decode(stored_settings_string)
  for key, value in pairs(settings_table) do
    reaper.ShowConsoleMsg("FX: "..key.."\n")
    for key2, value2 in pairs(value) do
      reaper.ShowConsoleMsg("PRESET: "..key2.."\n")
      for key3, value3 in pairs(value2) do
        reaper.ShowConsoleMsg("PARAM: "..key3.."\n")
      end
    end
  end
else 
  settings_table = {}
  reaper.ShowConsoleMsg("No stored data.\n")
end

settings_table[current_fx] = settings_table[current_fx] or {}
settings_table[current_fx][current_preset] = settings_table[current_fx][current_preset] or {}
for i = 0, num_params - 1 do
  local retval, param = reaper.TrackFX_GetParamName(track, current_fx_index, i)
  if retval then
    settings_table[current_fx][current_preset][param] = param or {}
  else 
    reaper.ShowConsoleMsg("Error: Couldn't get param names.\n")
    return
  end
end

json_string = json.encode(settings_table)
reaper.SetExtState(stored_section_name, stored_settings_key, json_string, true)



input_ids = {}
function ButtonApply_Run(pressed_button_id)
 
  local retval, track_state_chunk = reaper.GetTrackStateChunk(track, "", false)
  for index, input_id in ipairs(input_ids) do
    local fx_state_chunk = ultraschall.GetFXStateChunk(track_state_chunk)
      
    local input_text = reagirl.Inputbox_GetText(input_id)
    
    local success, altered_fx_chunk = ultraschall.AddParmAlias_FXStateChunk(fx_state_chunk, current_fx_index + 1, index, "TEST")
    if not success then -- if already has alias, make new.
        success, altered_fx_chunk = ultraschall.SetParmAlias2_FXStateChunk(fx_state_chunk, current_fx_index + 1, index, "TEST" )
    end
    
    _, new_track_state_chunk = ultraschall.SetFXStateChunk(track_state_chunk, altered_fx_chunk)
    
    retval, param = reaper.TrackFX_GetParamName(track, current_fx_index, index)
    settings_table[current_fx][current_preset][param] = input_text
  end
  reaper.SetTrackStateChunk(track, new_track_state_chunk, true)
  
  reaper.MB("Check your control surface!", "Done", 0)
end

reagirl.Gui_New()
reagirl.Button_Add(nil, nil, 0, 0, "Apply", "Apply changes and close dialog.", ButtonApply_Run)

input_box_description = "Set new alias name for param "
for i = 0, num_params - 1 do
  reagirl.NextLine()
  default_param = "Default "..i..": "
  retval, param = reaper.TrackFX_GetParamName(track, current_fx_index, i)
  input_id = reagirl.Inputbox_Add(nil, nil, 300, default_param, 150, input_box_description..i..".", param, nil, nil)
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
end
RunParamsDialog() -- TODO: run this if midi button pressed. Show on script load 'you don't have A midi button assigned to set custom names, set one?'





