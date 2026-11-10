reaper.ClearConsole()

stored_section_name = "SetAliasParamPerPresetSection"
stored_settings_key = "settings"
stored_dialog_cc_key = "dialog_cc"

package.path = package.path .. ";" .. reaper.GetResourcePath().."/Scripts/crazyj36-reaper-reascript/" .. "?.lua" -- get json.lua from same directory.
json = require("json")

if false then -- IF 'TRUE' HERE TO RESET
  -- Doesn't reset params, but reset button does.
  settings = {}
  input_ids = {}
  last_values = { "", "", "" }
  local json_settings_string = json.encode(settings)
  reaper.SetExtState(stored_section_name, stored_settings_key, json_settings_string, true)
  reaper.SetExtState(stored_section_name, stored_dialog_cc_key, "-1", true)
  reaper.ShowConsoleMsg("RESET DATABASE!\n")
  return
end

params_dialog_title = "Customize param names for current FX and preset."
params_dialog_desc = "This dialog allows to enter custom aliases for FX params per-preset."
input_box_description = "Set new alias name for param "
dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")
dofile(reaper.GetResourcePath().."/UserPlugins/reagirl.lua")
input_ids = {}
last_values = { "", "", "" }

function GetTrackInfo()
  track = reaper.GetLastTouchedTrack()
  if track == nil then 
    return "Error: Is A Track added and selected?\n"
  end
  retval, _, _, _, current_fx_index, _ = reaper.GetTouchedOrFocusedFX(1)
  if not retval then
    retval, _, _, _, current_fx_index, _ = reaper.GetTouchedOrFocusedFX(0)
    if not retval then
      return "Error: Is an FX added to this track?\n"
    end
  end
  retval, current_fx = reaper.TrackFX_GetFXName(track, current_fx_index)
  current_preset_index, num_presets = reaper.TrackFX_GetPresetIndex(track, current_fx_index)
  if num_presets == 0 then
    return "Error: Does this FX have any presets?\n"
  elseif current_preset_index == -1 then
    return "Error: Is A preset selected?"
  end
  retval, current_track_name = reaper.GetTrackName(track)
  retval, current_preset = reaper.TrackFX_GetPreset(track, current_fx_index)
  num_params = reaper.TrackFX_GetNumParams(track, current_fx_index)
  return true
end

function SetParams()
  reaper.ShowConsoleMsg("SetParams()\n")
 
  for key, value in pairs(settings[current_fx][current_preset]) do
    
    if value ~= key then
      target_alias = key
      
      for i = 1, num_params do 
        local retval, param_name = reaper.TrackFX_GetParamName(track, current_fx_index, i - 1)
      
        if param_name == target_alias then
          reaper.ShowConsoleMsg("Setting: "..param_name.." to "..value.." at: "..i.."\n")
          
          local retval, track_chunk = reaper.GetTrackStateChunk(track, "", false)
          local fx_chunk = ultraschall.GetFXStateChunk(track_chunk)
          
          local success, altered_fx_chunk = ultraschall.AddParmAlias_FXStateChunk(fx_chunk, current_fx_index + 1, i, value)
          if not success then
            success2, altered_fx_chunk = ultraschall.SetParmAlias_FXStateChunk(fx_chunk, current_fx_index + 1, i, value)
            if not success2 then
              reaper.ShowConsoleMsg("Failed in SetParams for: "..i.."\n")
            end
          end
          
          local retval, new_track_chunk = ultraschall.SetFXStateChunk(track_chunk, altered_fx_chunk)
          local retval = reaper.SetTrackStateChunk(track, new_track_chunk, false)
              
        end
      end
    end
  end
end

function ResetParams()
  reaper.ShowConsoleMsg("RESET PARAMS\n")
  
  new_fx_chunk = ""
  for i = num_params, 1, -1 do

    local retval, track_chunk = reaper.GetTrackStateChunk(track, "", false)
    local fx_chunk = ultraschall.GetFXStateChunk(track_chunk)
    
    local parm_idx, alias_name = ultraschall.GetParmAlias_FXStateChunk(fx_chunk, current_fx_index + 1, i)
    if parm_idx ~= nil then
      reaper.ShowConsoleMsg("removing alias: "..parm_idx..", name: "..alias_name..", i: "..i.."\n")
      
      retval, new_fx_chunk = ultraschall.DeleteParmAlias_FXStateChunk(fx_chunk, current_fx_index + 1, i)
      if not retval then
        reaper.ShowConsoleMsg("Failed to delete: "..i.."\n")
      end
        
      local retval, new_track_chunk = ultraschall.SetFXStateChunk(track_chunk, new_fx_chunk)
      local retval = reaper.SetTrackStateChunk(track, new_track_chunk, false)
    end
  end
  
end

function CheckSettings()
  local settings_ext_state = reaper.GetExtState(stored_section_name, stored_settings_key)
  if settings_ext_state ~= nil then 
    settings = json.decode(settings_ext_state)
  end
  
  if settings == nil then
    settings = {}
  end
  
  if settings[current_fx] == nil then
    settings[current_fx] = {}
  end
 
  if settings[current_fx][current_preset] == nil then
    reaper.ShowConsoleMsg("SETTING DEFAULTS FOR THIS PRESET\n")
    settings[current_fx][current_preset] = {}
    ResetParams()
    for i = 1, num_params do
      local retval, param_name = reaper.TrackFX_GetParamName(track, current_fx_index, i - 1)
      settings[current_fx][current_preset][param_name] = param_name
    end
  end

end

exit = false
function ButtonExit_Run()
  exit = true
end
function OnExit() 
  reaper.ShowConsoleMsg("EXIT\n")
end
reaper.atexit(OnExit)

function ButtonSetCC_Run()
  retval, dialog_cc = reaper.GetUserInputs("Select Launch CC", 1, "Enter CC that shows alias dialog:", dialog_cc)
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
    input_text = reagirl.Inputbox_GetText(input_ids[i])
    local retval, param_name = reaper.TrackFX_GetParamName(track, current_fx_index, i - 1)
    for key, value in pairs(settings[current_fx][current_preset]) do
      if key == param_name then
        if input_text ~= key then
          settings[current_fx][current_preset][param_name] = input_text
        end
      end
    end
  end
  ResetParams()
  SetParams()
  local json_settings_string = json.encode(settings)
  reaper.SetExtState(stored_section_name, stored_settings_key, json_settings_string, true)
end

function ButtonReset_Run()
  reaper.ShowConsoleMsg("RESET DATABASE!\n")
  ResetParams()
  settings = {}
  input_ids = {}
  last_values = { "", "", "" }
  local json_settings_string = json.encode(settings)
  reaper.SetExtState(stored_section_name, stored_settings_key, json_settings_string, true)
  reaper.SetExtState(stored_section_name, stored_dialog_cc_key, "-1", true)
  exit = true
end

function SetupDialog()
  local apply_button_id = reagirl.Button_Add(nil, nil, 0, 0, "Apply", "Apply changes and close dialog.", ButtonApply_Run)
  local cc_button_id = reagirl.Button_Add(nil, nil, 0, 0, "Set CC", "Set which MIDI controller CC message will show param-setting dialog.", ButtonSetCC_Run)
  local reset_button_id = reagirl.Button_Add(nil, nil, 0, 0, "Reset", "Reset this scripts stored settings and Reaper aliases.", ButtonReset_Run)
  local exit_button_id = reagirl.Button_Add(nil, nil, 0, 0, "Quit", "Terminate this script.", ButtonExit_Run)
  reagirl.NextLine()
  
  track_label_id = reagirl.Label_Add(nil, nil, "Current Track: "..current_track_name, "Track which you're currently controlling.", false, nil, nil)
  reagirl.NextLine()
  fx_label_id = reagirl.Label_Add(nil, nil, "Current FX: "..current_fx, "FX which you're currently controlling.", false, nil, nil)
  reagirl.NextLine()
  preset_label_id = reagirl.Label_Add(nil, nil, "Current Preset: "..current_preset, "Preset which you're currently controlling.", false, nil, nil)
  
  is_dialog_setup = true
end

function main()
  if exit then
    return
  end
  
  track_info = GetTrackInfo()
  if track_info == true then
  
    if last_values[1] ~= current_track_name or 
    last_values[2] ~= current_fx_index or 
    last_values[3] ~= current_preset_index then
      reaper.ShowConsoleMsg("New Config.\n")
      
      CheckSettings()
      
      if not is_dialog_setup then
        SetupDialog()
      end
      
      reagirl.Label_SetLabelText(track_label_id,  "Current Track: "..current_track_name)
      reagirl.Label_SetLabelText(fx_label_id, "Current FX: "..current_fx)
      reagirl.Label_SetLabelText(preset_label_id, "Current Preset: "..current_preset)
      
      ResetParams()
      SetParams()

      for i = 1, #input_ids do
        local success, result = pcall(
          function()
            reagirl.UI_Element_Remove(input_ids[i])
          end
        )
        input_ids[i] = nil
      end
    
      -- MOVE THIS. USING THIS METHOD KEEPS ORDER OF PARAMS
      for i = 1, num_params do
        local retval, param_name = reaper.TrackFX_GetParamName(track, current_fx_index, i - 1)
        for key, value in pairs(settings[current_fx][current_preset]) do
          if key == param_name or value == param_name then -- ITS THIS
            local caption = key
            local placeholder = value
            reagirl.NextLine()
            input_id = reagirl.Inputbox_Add(nil, nil, 300, caption, 150, input_box_description..(i)..".", placeholder, nil, nil)
            input_ids[i] = input_id
            reagirl.Inputbox_SetText(input_ids[i], param_name)
          end
        end
      end
      
      local json_settings_string = json.encode(settings)
      reaper.SetExtState(stored_section_name, stored_settings_key, json_settings_string, true)
       
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
        reagirl.Gui_Open("Set Alias Param Per Preset", false, params_dialog_title, params_dialog_desc, 350, 600)
    end
    
  elseif track_info ~= last_track_info then
    reaper.ShowConsoleMsg(track_info.."\n")
  end
  last_track_info = track_info
  
  reaper.defer(main)
end
main()
