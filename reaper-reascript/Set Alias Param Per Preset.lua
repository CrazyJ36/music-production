track = reaper.GetSelectedTrack(0, 0)
fx_idx = 1 -- set to selected fx
param_idx = 1 -- in reasynth param_idx is 1 for attack, starts at 1

dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")

-- tracks start at 1, master is 0. fx_id starts at 1.
function SetFXParameterAlias(track, fx_idx, param_idx, alias_name)

    local retval, track_state_chunk = reaper.GetTrackStateChunk(track, "", false)
    if not retval then
      reaper.ShowConsoleMsg("Error: Is track added in Reaper?\n")
    end
    
    local fx_state_chunk = ultraschall.GetFXStateChunk(track_state_chunk)
    
    local success, altered_fx_chunk = ultraschall.AddParmAlias_FXStateChunk(fx_state_chunk, fx_idx, param_idx, alias_name)
    if not success then -- if alread has alias, make new.
        success, altered_fx_chunk = ultraschall.SetParmAlias2_FXStateChunk(fx_state_chunk, fx_idx, param_idx, alias_name)
    end
    
    if success then
        _, track_state_chunk = ultraschall.SetFXStateChunk(track_state_chunk, altered_fx_chunk)
        reaper.SetTrackStateChunk(track, track_state_chunk)
    end
    
end

function GetPresetName(track, fx_idx) 
    _, preset_name = reaper.TrackFX_GetPreset(track, fx_idx - 1)
    --reaper.ShowConsoleMsg("current preset name: "..preset_name.."\n")
  return preset_name
end

function GetNumPresets(track, fx_idx)
  _, num_presets = reaper.TrackFX_GetPresetIndex(track, fx_idx - 1)
  --reaper.ShowConsoleMsg("preset count: "..num_presets.."\n")
  return num_presets
end

preset_name = GetPresetName(track, fx_idx)  -- needs A preset to be selected/active.
if preset_name == "Quiet" then
  SetFXParameterAlias(track, fx_idx, param_idx, "Quiet param")
elseif preset_name == "Loud" then
  SetFXParameterAlias(track, fx_idx, param_idx, "Loud param")
end

num_params = reaper.TrackFX_GetNumParams(track, fx_idx - 1)
reaper.ShowConsoleMsg("num_params: "..num_params.."\n")

--table = {}
for i = 0, num_params - 1 do
    local retval, name = reaper.TrackFX_GetParamName(track, fx_idx - 1, i)
    if retval then
      reaper.ShowConsoleMsg("param: "..name.."\n")
    else
      reaper.ShowConsoleMsg("Error\n")
    end
end



