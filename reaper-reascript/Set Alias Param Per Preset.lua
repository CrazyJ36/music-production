reaper.ClearConsole()

stored_section_name = "SetAliasParamPerPresetSection"
stored_settings_key = "settings"
stored_last_values_key = "last_values"

if false then -- IF 'TRUE' HERE TO RESET
  reaper.SetExtState(stored_section_name, stored_settings_key, "", true)
  reaper.SetExtState(stored_section_name, stored_last_values_key, "", true)
  reaper.ShowConsoleMsg("RESET DATABASE!\n")
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
  reaper.ShowConsoleMsg("Error: Is A preset selected?\n")
  return
end
retval, current_preset = reaper.TrackFX_GetPreset(track, current_fx_index)
if current_preset ~= "" then 
  reaper.ShowConsoleMsg("Current preset: "..current_preset.."\n")
end
num_params = reaper.TrackFX_GetNumParams(track, current_fx_index)


dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")
dofile(reaper.GetResourcePath().."/UserPlugins/reagirl.lua")
package.path = package.path .. ";" .. reaper.GetResourcePath().."/Scripts/crazyj36-reaper-reascript/" .. "?.lua"
json = require("json")



-- restore settings if exists, if not, see below
settings_ext_state = reaper.GetExtState(stored_section_name, stored_settings_key)
if settings_ext_state ~= nil and settings_ext_state ~= "" then 
  settings = json.decode(settings_ext_state) 
end
-- test if settings have been added before for above, if not added above, create tables for current fx/preset.
if settings == nil then
  settings = {}
end
if settings[current_fx] == nil then
  settings[current_fx] = {}
end
if settings[current_fx][current_preset] == nil then
  settings[current_fx][current_preset] = {}
  reaper.ShowConsoleMsg("SETTING DEFAULTS FOR THIS PRESET\n")
  for i = 0, num_params - 1 do
    retval, param_id = reaper.TrackFX_GetParamIdent(track, current_fx_index, i)
    param_index = reaper.TrackFX_GetParamFromIdent(track, current_fx_index, param_id)
    retval, param_name = reaper.TrackFX_GetParamName(track, current_fx_index, param_index)
    table.insert(settings[current_fx][current_preset], { [param_name] = param_name })
  end
end



stored_last_values_string = reaper.GetExtState(stored_section_name, stored_last_values_key)
if stored_last_values_string ~= nil and stored_last_values_string ~= "" then
  stored_last_values = json.decode(stored_last_values_string)
  
  if stored_last_values[1] ~= current_fx_index or stored_last_values[2] ~= current_preset_index then
    reaper.ShowConsoleMsg("New Config. last fx: "..stored_last_values[1]..", preset: "..stored_last_values[2].."\n")
    
   
    for i = 1, num_params do
    
      local retval, track_state_chunk = reaper.GetTrackStateChunk(track, "", false)
      if not retval then
        reaper.ShowConsoleMsg("Failed to get track state chunk in delete old aliases\n")
        goto continue
      end
      
      local fx_state_chunk, _ = ultraschall.GetFXStateChunk(track_state_chunk)
      local retval, param_id = reaper.TrackFX_GetParamIdent(track, current_fx_index, i)
      local param_index = reaper.TrackFX_GetParamFromIdent(track, current_fx_index, param_id)
      
      local retval, altered_fx_chunk1 = ultraschall.DeleteParmAlias2_FXStateChunk(fx_state_chunk, current_fx_index + 1, param_index)
      if not retval then
        reaper.ShowConsoleMsg("Failed to delete old alias at index: "..param_index.."\n")
        --goto continue
      else
        reaper.ShowConsoleMsg("deleted alias at index "..param_index.."\n")
      end
    
      for key, value in pairs(settings[current_fx][current_preset][i]) do
        reaper.ShowConsoleMsg("KEY: "..key..", VALUE: "..value.."\n")
        success, altered_fx_chunk2 = ultraschall.AddParmAlias_FXStateChunk(altered_fx_chunk1, current_fx_index + 1, param_index, value)
      end
      
      local retval, new_track_state_chunk = ultraschall.SetFXStateChunk(track_state_chunk, altered_fx_state_chunk2)
      local retval = reaper.SetTrackStateChunk(track, new_track_state_chunk, false)
      if not retval then
        reaper.ShowConsoleMsg("Failed to set fx state chunk in delete param\n")
      end
      ::continue::
    end
    
    
    --[[for i = 1, num_params do 
      -- Set params to what current fx/preset should be.
      retval, track_state_chunk = reaper.GetTrackStateChunk(track, "", false)
      fx_state_chunk = ultraschall.GetFXStateChunk(track_state_chunk)
      for key, value in pairs(settings[current_fx][current_preset][i]) do
        reaper.ShowConsoleMsg("preset value: "..value.."\n")
        success, altered_fx_chunk = ultraschall.AddParmAlias_FXStateChunk(fx_state_chunk, current_fx_index + 1, i, value)
        if not success then 
          success2, altered_fx_chunk = ultraschall.SetParmAlias2_FXStateChunk(fx_state_chunk, current_fx_index + 1, i, value)
          if not success2 then
            reaper.ShowConsoleMsg("Failed to set ParmAlias in LOAD change!\n")
            --return
          end
        end
      end
      retval, new_track_state_chunk = ultraschall.SetFXStateChunk(track_state_chunk, altered_fx_chunk)
      retval = reaper.SetTrackStateChunk(track, new_track_state_chunk, false)
    end]]
  end
  
end



function ButtonApply_Run()

  altered_fx_state_chunk = ""
  for i = 1, num_params do
    input_text = reagirl.Inputbox_GetText(input_ids[i])
    
    for key, value in pairs(settings[current_fx][current_preset][i]) do
      
      if input_text ~= value then
        retval, track_state_chunk = reaper.GetTrackStateChunk(track, "", false)
    
        settings[current_fx][current_preset][i] = { [key] = input_text }
        for key, value in pairs(settings[current_fx][current_preset][i]) do
          reaper.ShowConsoleMsg("CHANGED: "..key.." to "..value.."\n")
        end
        
        fx_state_chunk = ultraschall.GetFXStateChunk(track_state_chunk)
        success, altered_fx_chunk = ultraschall.AddParmAlias_FXStateChunk(fx_state_chunk, current_fx_index + 1, i, input_text)
        if not success then 
          success2, altered_fx_chunk = ultraschall.SetParmAlias2_FXStateChunk(fx_state_chunk, current_fx_index + 1, i, input_text)
          if not success2 then
            reaper.ShowConsoleMsg("Failed to set ParmAlias in change!\n")
            return
          end
        end
        retval, new_track_state_chunk = ultraschall.SetFXStateChunk(track_state_chunk, altered_fx_chunk)
        
        retval = reaper.SetTrackStateChunk(track, new_track_state_chunk, false)
        if not retval then
          reaper.ShowConsoleMsg("Failed to set fx state chunk in new param\n")
          return
        end
      end
    end
  end
  
  reaper.MB("Check your control surface!", "Done", 0)
  reagirl.Gui_Close()
end

input_ids = {}
reagirl.Button_Add(nil, nil, 0, 0, "Apply", "Apply changes and close dialog.", ButtonApply_Run)
input_box_description = "Set new alias name for param "
for i = 1, num_params do
  for key, value in pairs(settings[current_fx][current_preset][i]) do
    --reaper.ShowConsoleMsg("LOAD: "..key..", "..value.."\n")
    caption = key
    placeholder = value
  end
  reagirl.NextLine()
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
    json_settings_string = json.encode(settings)
    json_last_values_string = json.encode({ current_fx_index, current_preset_index })
    reaper.SetExtState(stored_section_name, stored_settings_key, json_settings_string, true)
    reaper.SetExtState(stored_section_name, stored_last_values_key, json_last_values_string, true)
    reaper.ShowConsoleMsg("EXIT\n")
  end
end

RunParamsDialog() -- TODO: run this if midi button pressed. Show on script load 'you don't have A midi button assigned to set custom names, set one?'
