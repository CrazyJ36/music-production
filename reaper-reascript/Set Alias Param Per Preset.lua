-- Load the Ultraschall API
dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")

-- tracks start at 1, master is 0. fx_id starts at 1.
function SetFXParameterAlias(track, fx_idx, param_idx, alias_name)

    local retval, track_state_chunk = reaper.GetTrackStateChunk(track, "", false)
    if not retval then
      reaper.ShowConsoleMsg("Error: Is track added in Reaper?\n")
    end
    
    local fx_state_chunk = ultraschall.GetFXStateChunk(track_state_chunk)
    
    local success, altered_fx_chunk = ultraschall.AddParmAlias_FXStateChunk(fx_state_chunk, fx_idx, param_idx, alias_name)
    
    if not success then
        success, altered_fx_chunk = ultraschall.SetParmAlias2_FXStateChunk(fx_state_chunk, fx_idx, param_idx, alias_name)
    end
    
    if success then
        -- 4. Inject the altered FX Chunk back into the Track State Chunk
        _, track_state_chunk = ultraschall.SetFXStateChunk(track_state_chunk, altered_fx_chunk)
        
        -- 5. Commit the Track State Chunk back to REAPER
        retval = reaper.SetTrackStateChunk(track, track_state_chunk)
    end
    
end

track = reaper.GetSelectedTrack(0, 0)
SetFXParameterAlias(track, 1, 1, "CrazyJ36") -- in reasynth param id is 1 for attack
