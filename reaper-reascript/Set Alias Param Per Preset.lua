reaper.ClearConsole()

dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")
dofile(reaper.GetResourcePath().."/UserPlugins/reagirl.lua")

section_name = "SetAliasParamPerPresetSection"
section_plugins_key = "plugins"
section_plugin_presets_key = "presets"
section_plugin_presets_params_key = "params"
section_default_params_key = "default_params"
if false then -- IF 'TRUE' HERE TO RESET.
  reaper.SetExtState(section_name, "", "", true)
  reaper.SetExtState(section_name, section_plugins_key, "", true)
  reaper.SetExtState(section_name, section_plugin_presets_key, "", true)
  reaper.SetExtState(section_name, section_plugin_presets_params_key, "", true)
  reaper.SetExtState(section_name, section_default_params_key, "", true)
  reaper.ShowConsoleMsg("RESET!\n")
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

function GetCurrentPresetName(track, current_fx_index) -- needs A preset to be selected in dropdown.
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
current_preset_name = GetCurrentPresetName(track, current_fx_index)

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
current_params = GetFXParams()

default_params = {}
function GetSetDefaultParams()
  default_params_string = reaper.GetExtState(section_name, section_default_params_key)
  
  if default_params_string == nil or default_params_string == "" then
    reaper.ShowConsoleMsg("Setting default params...\n")
    for index, default_param in ipairs(current_params) do
      default_params_string = default_params_string..";"..default_param
    end
    reaper.ShowConsoleMsg("default params for current: "..default_params_string.."\n")
    reaper.SetExtState(section_name, section_default_params_key, default_params_string, true)
  else
    reaper.ShowConsoleMsg("default params already set!\n")
  end
  
  for item in string.gmatch(default_params_string, "([^;]+)") do
    table.insert(default_params, item)
  end
end
GetSetDefaultParams()


input_ids = {}
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
end
RunParamsDialog() -- TODO: run this if midi button pressed. Show on script load 'you don't have A midi button assigned to set custom names, set one?'

current_params_string = table.concat(current_params, ";")




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

plugins = {}
function SetTables()

  plugins[current_fx_name] = {}
  plugins[current_fx_name][current_preset_name] = {}
  
  for index, value in ipairs(current_params) do 
    plugins[current_fx_name][current_preset_name][value] = value
  end
  
  --[[for i = 1, GetNumPresets(track, current_fx_index) do
    if not plugins[current_fx_name][current_preset_name] then
      reaper.ShowConsoleMsg("Adding new preset to this plugin table!\n")
      plugins[current_fx_name][current_preset_name] = current_preset_name
    end
  end
  
  for plugin, presets in pairs(plugins) do
    reaper.ShowConsoleMsg("table plugin: "..plugin..":\n")
    for preset, params in pairs(presets) do
      reaper.ShowConsoleMsg("table preset: "..preset.."\n")
      for index, param in ipairs(params) do 
        reaper.ShowConsoleMsg("table param: "..param.."\n")
      end
    end
  end]]
  --reaper.SetExtState(section_name, section_plugins_key, )
end

function GetStoredData() 
  stored_plugins_string = reaper.GetExtState(section_name, section_plugins_key)
  if stored_plugins_string then
    for val in string.gmatch(stored_plugins_string, "([^;]+)") do
      table.insert(plugins, val)
    end
  end
end

GetStoredData()
SetTables()







