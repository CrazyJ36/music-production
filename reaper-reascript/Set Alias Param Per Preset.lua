reaper.ClearConsole()

stored_section_name = "SetAliasParamPerPresetSection"
stored_settings_key = "settings"

if false then -- IF 'TRUE' HERE TO RESET
  reaper.SetExtState(stored_section_name, stored_settings_key, "", true)
  reaper.ShowConsoleMsg("RESET!\n")
  return
end

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
current_preset_index, num_presets = reaper.TrackFX_GetPresetIndex(track, current_fx_index)
if current_preset_index ~= -1 then
  if num_presets > 0 then
    reaper.ShowConsoleMsg("num presets: "..num_presets.."\n")
  else 
    reaper.ShowConsoleMsg("Error: Does this FX have any presets?\n")
    return
  end
else
  reaper.ShowConsoleMsg("Error v1: Is A preset selected?\n")
  return
end
retval, current_preset = reaper.TrackFX_GetPreset(track, current_fx_index)
if retval and current_preset ~= "" then 
  reaper.ShowConsoleMsg("Current preset: "..current_preset.."\n")
else
 reaper.ShowConsoleMsg("Error v2: Is A preset selected?\n")
 return
end
num_params = reaper.TrackFX_GetNumParams(track, current_fx_index)

dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")
dofile(reaper.GetResourcePath().."/UserPlugins/reagirl.lua")
package.path = package.path .. ";" .. reaper.GetResourcePath().."/Scripts/crazyj36-reaper-reascript/" .. "?.lua"
json = require("json")

-- restore settings if exists, if not, see below
settings_ext_state = reaper.GetExtState(stored_section_name, stored_settings_key)
if settings_ext_state ~= nil and settings_ext_state ~= "" then 
  settings_table = json.decode(settings_ext_state) 
end

-- test if settings have been added before for above, if not added above, create tables for current fx/preset.
if settings_table == nil then
  settings_table = {}
end
if settings_table[current_fx] == nil then
  settings_table[current_fx] = {}
end
if settings_table[current_fx][current_preset] == nil then
  settings_table[current_fx][current_preset] = {}
end
for i = 0, num_params - 1 do
  retval, new_param = reaper.TrackFX_GetParamName(track, current_fx_index, i)
  settings_table[current_fx][current_preset][new_param] = settings_table[current_fx][current_preset][new_param] or "alias"..i
end


for fx, unknown in pairs(settings_table) do
  reaper.ShowConsoleMsg("BEFORE FX: "..fx.."\n")
end
for preset, params in pairs(settings_table[current_fx]) do
  reaper.ShowConsoleMsg("\nBEFORE PRESET: "..preset.."\n")
  for param, alias in pairs(settings_table[current_fx][current_preset]) do
    reaper.ShowConsoleMsg("BEFORE PARAM: "..param..": "..alias.."\n")
  end
end


input_ids = {} -- reset to empty every run/loop to only receive current param inputIds.
function ButtonApply_Run()
  
  i = 1
  for param, alias in pairs(settings_table[current_fx][current_preset]) do
    input_text = reagirl.Inputbox_GetText(input_ids[i])
    settings_table[current_fx][current_preset][param] = input_text
    --reaper.ShowConsoleMsg("SETTING to: "..param..": "..alias.."\n")
    i = i + 1
  end
  

  --[[for i = 1, num_params do

    input_text = reagirl.Inputbox_GetText(input_ids[i])

    retval, track_state_chunk = reaper.GetTrackStateChunk(track, "", false)
    if not retval then
      reaper.ShowConsoleMsg("Failed to get track state chunk\n")
      return
    end
    
    fx_state_chunk = ultraschall.GetFXStateChunk(track_state_chunk)
    success, altered_fx_chunk = ultraschall.AddParmAlias_FXStateChunk(fx_state_chunk, current_fx_index + 1, i, input_text)
    if not success then 
      reaper.ShowConsoleMsg("Setting instead of adding alias\n")
      success2, altered_fx_chunk = ultraschall.SetParmAlias_FXStateChunk(fx_state_chunk, current_fx_index + 1, i, input_text)
      if not success2 then
        reaper.ShowConsoleMsg("Failed to set already existing alias\n")
        return
      end
    end
    retval, new_track_state_chunk = ultraschall.SetFXStateChunk(track_state_chunk, altered_fx_chunk)
    if not retval then
      reaper.ShowConsoleMsg("Failed to set new fx chunk\n")
      return
    end
    
    retval = reaper.SetTrackStateChunk(track, new_track_state_chunk, false)
    if not retval then
      reaper.ShowConsoleMsg("Failed to set track state chunk\n")
      return
    end

  end]]
  
  
  reaper.MB("Check your control surface!", "Done", 0)
  reagirl.Gui_Close()
end

reagirl.Gui_New()
reagirl.Button_Add(nil, nil, 0, 0, "Apply", "Apply changes and close dialog.", ButtonApply_Run)
input_box_description = "Set new alias name for param "
i = 1
for key, value in pairs(settings_table[current_fx][current_preset]) do
  reagirl.NextLine()
  caption = key
  placeholder = value
  input_id = reagirl.Inputbox_Add(nil, nil, 300, caption, 150, input_box_description..(i)..".", placeholder, nil, nil)
  table.insert(input_ids, input_id)
  i = i + 1
end

params_dialog_title = "Customize param names for current FX and preset."
params_dialog_desc = "This dialog allows to enter custom aliases for FX params per-preset."
reagirl.Gui_Open("Set Alias Param Per Preset", false, params_dialog_title, params_dialog_desc, 350, 600)
function RunParamsDialog() 
  reagirl.Gui_Manage()
  if reagirl.Gui_IsOpen() then
    reaper.defer(RunParamsDialog)
  else 
    reaper.ShowConsoleMsg("EXIT\n")
    for param, alias in pairs(settings_table[current_fx][current_preset]) do
      reaper.ShowConsoleMsg("AFTER PARAM: "..param..": "..alias.."\n")
    end
    json_settings_string = json.encode(settings_table)
    reaper.SetExtState(stored_section_name, stored_settings_key, json_settings_string, true)
  end
end

RunParamsDialog() -- TODO: run this if midi button pressed. Show on script load 'you don't have A midi button assigned to set custom names, set one?'
