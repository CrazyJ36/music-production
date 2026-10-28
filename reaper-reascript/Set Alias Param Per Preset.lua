reaper.ClearConsole()


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
if retval then 
 reaper.ShowConsoleMsg("FX Index: "..current_fx_index.."\n") 
else 
  reaper.ShowConsoleMsg("Error: Couldn't get focued fx\n")
  return
end
retval, current_fx = reaper.TrackFX_GetFXName(track, current_fx_index)
if retval then
  reaper.ShowConsoleMsg("FX Name: "..current_fx.."\n")
else 
  reaper.ShowConsoleMsg("Error: Is an FX Added to track?\n")
  return
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


stored_section_name = "SetAliasParamPerPresetSection"
stored_settings_key = "settings"
if false then -- IF 'TRUE' HERE TO RESET
  reaper.SetExtState(stored_section_name, stored_settings_key, "", true)
  reaper.ShowConsoleMsg("RESET!\n")
  return
end

param = {}
--alias = {}
settings_table = {}
settings_table[current_fx] = settings_table[current_fx] or {}
settings_table[current_fx][current_preset] = settings_table[current_fx][current_preset] or {}
settings_table[current_fx][current_preset][param] = settings_table[current_fx][current_preset][param] or {}
--settings_table[current_fx][current_preset][param][alias] = settings_table[current_fx][current_preset][param][alias] or {}

ext_state = reaper.GetExtState(stored_section_name, stored_settings_key)
if ext_state ~= nil and ext_state ~= "" then
  reaper.ShowConsoleMsg("Loading stored data.\n")
  stored_settings_string = reaper.GetExtState(stored_section_name, stored_settings_key)
  settings_table = json.decode(stored_settings_string)
else 
  reaper.ShowConsoleMsg("No stored data.\n")
  for i = 0, num_params  - 1 do
    local retval, new_param = reaper.TrackFX_GetParamName(track, current_fx_index, i)
    table.insert(settings_table[current_fx][current_preset][param], { [new_param] = "alias" })
  end
end

for key1, value1 in pairs(settings_table[current_fx][current_preset][param]) do
  for key2, value2 in pairs(value1) do
    reaper.ShowConsoleMsg("Key "..key2.." = "..value2.."\n")
  
  end
end

  
input_ids = {}
function ButtonApply_Run()
  for i = 0, num_params do
  
    input_text = reagirl.Inputbox_GetText(input_ids[i + 1])
    table.insert(settings_table[current_fx][current_preset][param][alias], input_text)
    reaper.ShowConsoleMsg("ALIAS: "..settings_table[current_fx][current_preset][param][i][alias][i].."\n")
    --[[if input_text ~= default_params_table[i] then
    
      _, track_state_chunk = reaper.GetTrackStateChunk(track, "", false)
      fx_state_chunk = ultraschall.GetFXStateChunk(track_state_chunk)
      
      success, altered_fx_chunk = ultraschall.AddParmAlias_FXStateChunk(fx_state_chunk, current_fx_index + 1, i, input_text)
      if not success then 
        reaper.ShowConsoleMsg("Setting instead of adding alias\n")
        success2, altered_fx_chunk = ultraschall.SetParmAlias2_FXStateChunk(fx_state_chunk, current_fx_index + 1, i, input_text)
        if not success2 then
          reaper.ShowConsoleMsg("Failed to set already existing alias!\n")
          return
        end
      end
      
      retval, new_track_state_chunk = ultraschall.SetFXStateChunk(track_state_chunk, altered_fx_chunk)
      if not retval then
        reaper.ShowConsoleMsg("Failed to set new fx chunk\n")
        return
      end
    
      reaper.SetTrackStateChunk(track, new_track_state_chunk, false)
    end]]
    
  end

  
  --settings_table[current_fx][current_preset][param][alias][i] = input_text
  
  --json_string = json.encode(settings_table)
  --reaper.SetExtState(stored_section_name, stored_settings_key, json_string, true)
  reaper.MB("Check your control surface!", "Done", 0)
end

reagirl.Gui_New()
reagirl.Button_Add(nil, nil, 0, 0, "Apply", "Apply changes and close dialog.", ButtonApply_Run)
input_box_description = "Set new alias name for param "
for i = 1, num_params do
  reagirl.NextLine()
  --retval, param = reaper.TrackFX_GetParamName(track, current_fx_index, i)

  --local alias = alias_names[i]
  
  --if #settings_table[current_fx][current_preset]["param"]["alias"] > 0 then
  --  alias = alias[i]
  --else 
  --  alias = param[i]
  --end
  caption = "caption" --settings_table[current_fx][current_preset][param][i]
  --if settings_table[current_fx][current_preset][param][alias] == {} then
  default_input_text = param[i]

  --else 
    --default_input_text = settings_table[current_fx][current_preset][param][i]
  --end
  input_id = reagirl.Inputbox_Add(nil, nil, 300, caption, 150, input_box_description..(i)..".", "param", nil, nil)
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





