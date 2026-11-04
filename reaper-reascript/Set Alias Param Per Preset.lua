reaper.ClearConsole()

stored_section_name = "SetAliasParamPerPresetSection"
stored_settings_key = "settings"
stored_dialog_cc_key = "dialog_cc"


if false then -- IF 'TRUE' HERE TO RESET
  reaper.SetExtState(stored_section_name, stored_settings_key, "", true)
  reaper.SetExtState(stored_section_name, stored_dialog_cc_key, "-1", true)
  reaper.ShowConsoleMsg("RESET DATABASE!\n")
  return
end


dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")
dofile(reaper.GetResourcePath().."/UserPlugins/reagirl.lua")
package.path = package.path .. ";" .. reaper.GetResourcePath().."/Scripts/crazyj36-reaper-reascript/" .. "?.lua"
json = require("json")

input_ids = {}
last_values = { "", "", "" }
exit = false

function ButtonExit_Run()
  json_settings_string = json.encode(settings)
  reaper.SetExtState(stored_section_name, stored_settings_key, json_settings_string, true)
  exit = true
  reaper.ShowConsoleMsg("EXIT\n")
end

reaper.atexit(ButtonExit_Run)

function GetTrackInfo()
  track = reaper.GetSelectedTrack(0, 0)
  if track == nil then 
    return "Error: Is A Track added and selected?\n"
  end
  retval, _, _, current_fx_index = reaper.GetFocusedFX()
  if not retval then
    return "Error: Couldn't get focued fx\n"
  end
  retval, current_fx = reaper.TrackFX_GetFXName(track, current_fx_index)
  if not retval then
    return "Error: Is an FX Added to track?\n"
  end
  current_preset_index, num_presets = reaper.TrackFX_GetPresetIndex(track, current_fx_index)
  if num_presets == 0 then
    return "Error: Does this FX have any presets?\n"
  elseif current_preset_index == -1 then
    return "Error: Is A preset selected?"
  end
  retval, current_preset = reaper.TrackFX_GetPreset(track, current_fx_index)
  num_params = reaper.TrackFX_GetNumParams(track, current_fx_index)
  retval, current_track_name = reaper.GetTrackName(track)
  return true
end

function SetParams(i)
  local retval, param_name = reaper.TrackFX_GetParamName(track, current_fx_index, i - 1)
  for key, value in pairs(settings[current_fx][current_preset]) do
    if key == param_name then
      input = value
    end
  end
  
  local retval, track_chunk = reaper.GetTrackStateChunk(track, "", false)
  local fx_chunk = ultraschall.GetFXStateChunk(track_chunk)
  
  local success, altered_fx_chunk = ultraschall.AddParmAlias_FXStateChunk(fx_chunk, current_fx_index + 1, i, input)
  if not success then
    success2, altered_fx_chunk = ultraschall.SetParmAlias_FXStateChunk(fx_chunk, current_fx_index + 1, i, input)
    if not success2 then
      reaper.ShowConsoleMsg("Failed in SetParams for: "..i.."\n")
    end
  end
  
  local retval, new_track_chunk = ultraschall.SetFXStateChunk(track_chunk, altered_fx_chunk)
  local retval = reaper.SetTrackStateChunk(track, new_track_chunk, false)
end

function ResetParams()
  
  for i = num_params, 1, -1 do
  
    local retval, track_chunk = reaper.GetTrackStateChunk(track, "", false)
    local fx_chunk = ultraschall.GetFXStateChunk(track_chunk)
  
    retval_new_chunk, new_fx_chunk = ultraschall.DeleteParmAlias_FXStateChunk(fx_chunk, current_fx_index + 1, i)
    if not retval_new_chunk then
      reaper.ShowConsoleMsg("Failed to delete: "..(i - 1).."\n")
    else 
      reaper.ShowConsoleMsg("Successfully deleted: "..(i - 1).."\n")
    end
    
    retval, new_track_chunk = ultraschall.SetFXStateChunk(track_chunk, new_fx_chunk)
    local retval = reaper.SetTrackStateChunk(track, new_track_chunk, false)
    
    local retval, param_name = reaper.TrackFX_GetParamName(track, current_fx_index, i - 1)
    settings[current_fx][current_preset][param_name] = param_name
  end
  
end

function CheckSettings()
  -- restore settings if exists, if not, see below
  settings_ext_state = reaper.GetExtState(stored_section_name, stored_settings_key)
  if settings_ext_state ~= nil and settings_ext_state ~= "" then 
    settings = json.decode(settings_ext_state) 
  end
  -- test if settings have been added before for above, if not added above, create tables for current fx/preset.
  if settings == nil then
    settings = {}
  end
  if current_fx ~= nil and settings[current_fx] == nil then
    settings[current_fx] = {}
  end
  if settings[current_fx][current_preset] == nil then
    reaper.ShowConsoleMsg("SETTING DEFAULTS FOR THIS PRESET\n")
    settings[current_fx][current_preset] = {}
    for i = 1, num_params do
      local retval, param_name = reaper.TrackFX_GetParamName(track, current_fx_index, i - 1)
      settings[current_fx][current_preset][param_name] = param_name
    end
  end
end

function ButtonSetCC_Run()
  retval, dialog_cc = reaper.GetUserInputs("Select Launch CC", 1, "Enter CC that shows param entry dialog", dialog_cc)
  if retval then
    reaper.SetExtState(stored_section_name, stored_dialog_cc_key, dialog_cc, true)
  end
  dialog_cc = tonumber(dialog_cc)
end
dialog_cc = tonumber(reaper.GetExtState(stored_section_name, stored_dialog_cc_key)) or -1
if dialog_cc == -1 then
  ButtonSetCC_Run()
end


function ButtonApply_Run()
  for i = 1, num_params do
    --ResetParams(i)
    input_text = reagirl.Inputbox_GetText(input_ids[i])
    local retval, param_name = reaper.TrackFX_GetParamName(track, current_fx_index, i - 1)
    for key, value in pairs(settings[current_fx][current_preset]) do
      if key == param_name then
        if input_text ~= key then
          settings[current_fx][current_preset][param_name] = input_text
        end
      end
    end
    SetParams(i)
  end
  reaper.MB("Check your control surface!", "Done", 0)
  reagirl.Gui_Close()
end



function SetupDialog() 
  params_dialog_title = "Customize param names for current FX and preset."
  params_dialog_desc = "This dialog allows to enter custom aliases for FX params per-preset."
  input_box_description = "Set new alias name for param "
  
  reagirl.Button_Add(nil, nil, 0, 0, "Apply", "Apply changes and close dialog.", ButtonApply_Run)
  reagirl.Button_Add(nil, nil, 0, 0, "Set CC", "Set which MIDI controller CC message will show param-setting dialog.", ButtonSetCC_Run)
  reagirl.Button_Add(nil, nil, 0, 0, "Quit", "Terminate this script.", ButtonExit_Run)
  
  reagirl.NextLine()
  retval, track_name = reaper.GetTrackName(track)
  track_label_id = reagirl.Label_Add(nil, nil, "Current Track: "..track_name, "Track info.", false, nil, nil)
  reagirl.NextLine()
  fx_label_id = reagirl.Label_Add(nil, nil, "Current FX: "..current_fx, "FX which you're currently controlling.", false, nil, nil)
  reagirl.NextLine()
  preset_label_id = reagirl.Label_Add(nil, nil, "Current Preset: "..current_preset, "Preset which you're currently controlling.", false, nil, nil)
  reagirl.NextLine()
  
  for i = 1, num_params do
    local retval, param_name = reaper.TrackFX_GetParamName(track, current_fx_index, i - 1)
    for key, value in pairs(settings[current_fx][current_preset]) do
      if key == param_name then
      
        caption = key
        placeholder = value
        reagirl.NextLine()
        input_id = reagirl.Inputbox_Add(nil, nil, 300, caption, 150, input_box_description..(i)..".", placeholder, nil, nil)
        input_ids[i] = input_id
      end
    end
  end
  
  is_dialog_setup = true
end

function main()
  if exit then
    return
  end
  
  track_info = GetTrackInfo()
  if track_info == true then
    
    CheckSettings()
    
    if last_values[1] ~= track_name or 
    last_values[2] ~= current_fx_index or 
    last_values[3] ~= current_preset_index then
      reaper.ShowConsoleMsg("New Config.\n")
      
      if not is_dialog_setup then
        SetupDialog()
      end
    
      
      ResetParams(i)
   
      for i = 1, num_params do
        --[[local retval, param_name = reaper.TrackFX_GetParamName(track, current_fx_index, i - 1)
        for key, value in pairs(settings[current_fx][current_preset]) do
          if key == param_name then
            reaper.ShowConsoleMsg("matched settings in main setparams, for "..i.."\n")
            settings[current_fx][current_preset][key] = value
          end
        end]]
        --SetParams(i)
      end
      
      last_values[1] = current_track_name
      last_values[2] = current_fx_index
      last_values[3] = current_preset_index
    end
    
    
    
  
    reagirl.Gui_Manage()
    inputEvent = { reaper.MIDI_GetRecentInputEvent(0) }
    if inputEvent[1] ~= 0 and
      inputEvent[2]:byte(1) & 0xF0 == 176 and
      inputEvent[2]:byte(2) == dialog_cc and
      inputEvent[2]:byte(3) == 127 and
      not reagirl.Gui_IsOpen() then
        reaper.ShowConsoleMsg("Starting GUI\n")
        reagirl.Gui_Open("Set Alias Param Per Preset", false, params_dialog_title, params_dialog_desc, 350, 600)
        
        if not reagirl.Gui_IsOpen() then
          reaper.ShowConsoleMsg("EXIT GUI\n")
        end
        
        
        reagirl.Label_SetLabelText(track_label_id,  "Current Track: "..current_track_name)
        reagirl.Label_SetLabelText(fx_label_id, "Current FX: "..current_fx)
        reagirl.Label_SetLabelText(preset_label_id, "Current Preset: "..current_preset)
    end

  else
    reaper.ShowConsoleMsg(track_info.."\n")
  end
  
  reaper.defer(main)
end
main()
