dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")

section_name = "SetAliasParamPerPresetSection"
plugins_section_key = "plugins"
presets_section_key = "presets"
plugins_section_key_value = "plugin"
presets_section_key_value = "preset"

table_of_plugins = {}
table_of_plugin_presets = {}

track = reaper.GetSelectedTrack(0, 0) -- tracks start at 1, master is 0.
if track == nil then 
  reaper.ShowConsoleMsg("Error: Is A Track added and selected?\n")
  return 
end

retval, _, _, fx_idx = reaper.GetFocusedFX()--1 -- set to selected fx.  fx_idx starts at 1. Use getfocusedFx()
if not retval then 
  reaper.ShowConsoleMsg("Error: Couldn't get last touched fx\n")
  return
end
retval, fx_name = reaper.TrackFX_GetFXName(track, fx_idx)
if not retval then
  reaper.ShowConsoleMsg("Error: Couldn't get fx_name\n")
  return
else 
  reaper.ShowConsoleMsg("fx name: "..fx_name.."\n")
end

param_idx = 1 -- in reasynth param_idx is 1 for attack, starts at 1
retval, _, _ = reaper.TrackFX_GetParam(track, fx_idx, param_idx)
if not retval then
  reaper.ShowConsoleMsg("Error: Does this FX have any params?\n")
  return
end


function GetStoredData() 
  stored_plugins = reaper.GetExtState(section_name, plugins_section_key)
  if stored_plugins and stored_plugins ~= "" then
    for val in string.gmatch(stored_plugins, "([^,]+)") do
      table.insert(table_of_plugins, val)
    end
  end

  stored_presets = reaper.GetExtState(section_name, presets_section_key)
  if stored_presets and stored_presets ~= "" then
    for val in string.gmatch(stored_presets, "([^,]+)") do
      table.insert(table_of_plugin_presets, val)
    end
  end
  reaper.ShowConsoleMsg("presets table size: "..#table_of_plugin_presets.."\n")
  reaper.ShowConsoleMsg("plugins table size: "..#table_of_plugins.."\n")
    
end


function SetStoredData() 
  if not TableContains(table_of_plugins, fx_name) then
    table_of_plugins[#table_of_plugins + 1] = fx_name
    new_table_of_plugins_string = table.concat(table_of_plugins, ",")
    reaper.SetExtState(section_name, plugins_section_key, new_table_of_plugins_string, true)
  end
  if not TableContains(table_of_plugin_presets, preset_name) then
    table_of_plugin_presets[#table_of_plugin_presets + 1] = preset_name
    new_table_of_plugin_presets_string = table.concat(table_of_plugin_presets, ",")
    reaper.SetExtState(section_name, presets_section_key, new_table_of_plugin_presets_string, true)
  end
end



function SetFXParameterAlias(track, fx_idx, param_idx, alias_name)

  local retval, track_state_chunk = reaper.GetTrackStateChunk(track, "", false)
  local fx_state_chunk = ultraschall.GetFXStateChunk(track_state_chunk)
  
  local success, altered_fx_chunk = ultraschall.AddParmAlias_FXStateChunk(fx_state_chunk, fx_idx + 1, param_idx, alias_name)
  if not success then -- if already has alias, make new.
      success, altered_fx_chunk = ultraschall.SetParmAlias2_FXStateChunk(fx_state_chunk, fx_idx + 1, param_idx, alias_name)
  end
  
  if success then
      _, track_state_chunk = ultraschall.SetFXStateChunk(track_state_chunk, altered_fx_chunk)
      reaper.SetTrackStateChunk(track, track_state_chunk)
  end
end


function GetPresetName(track, fx_idx) -- needs A preset to be selected in dropdown.
  retval, preset_name = reaper.TrackFX_GetPreset(track, fx_idx)
  if not retval then
    reaper.ShowConsoleMsg("Error: Does FX have any presets?\n")
    return ""
  elseif preset_name == "" then
    reaper.ShowConsoleMsg("Error: Is A preset selected?\n")
    return ""
  else
    reaper.ShowConsoleMsg("current preset name: "..preset_name.."\n")
    return preset_name
  end
end

function GetNumPresets(track, fx_idx)
  _, num_presets = reaper.TrackFX_GetPresetIndex(track, fx_idx)
  reaper.ShowConsoleMsg("preset count: "..num_presets.."\n")
  return num_presets
end

function TableContains(tbl, x)
    for _, value in ipairs(tbl) do
        if value == x then return true end
    end
    return false
end

reaper.ShowConsoleMsg("FX_IDX: "..fx_idx.."\n")

function GetFXParams()
  num_params = reaper.TrackFX_GetNumParams(track, fx_idx)
  reaper.ShowConsoleMsg("num_params: "..num_params.."\n")
  for i = 0, num_params - 1 do
    local retval, name = reaper.TrackFX_GetParamName(track, fx_idx, i)
    if retval then
      reaper.ShowConsoleMsg("param: "..name.."\n")
    else
      reaper.ShowConsoleMsg("Error getting params\n")
    end
  end
end

GetStoredData()
SetStoredData()


preset_name = GetPresetName(track, fx_idx) 
if preset_name == "" then
    return
end
if preset_name == "Loud" then
  SetFXParameterAlias(track, fx_idx, param_idx, "Loud!")
elseif preset_name == "Quiet" then
  SetFXParameterAlias(track, fx_idx, param_idx, "Quiet...")
end

GetFXParams(track, fx_id)


