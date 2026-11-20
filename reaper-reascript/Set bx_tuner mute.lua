fx_index = 0

track = reaper.GetSelectedTrack(0, 0)
if track ~= nil then

  retval, fx_name = reaper.TrackFX_GetFXName(track, fx_index)
  if retval and fx_name == "VST3: bx_tuner (Plugin Alliance)" then
  
    num_params = reaper.TrackFX_GetNumParams(track, fx_index)
    for j = 0, num_params do
      retval, param_name = reaper.TrackFX_GetParamName(track, fx_index, j, "")
      if param_name == "Tuner Mode" then
      
        retval = reaper.TrackFX_SetParam(track, 0, j, 1)
        if not retval then
          reaper.ShowConsoleMsg("Failed to toggle tuner mute.\n")
        end
        
        break
        
      end
    end

  else 
    reaper.ShowConsoleMsg("Is FX 1 on this track bx_tuner?\n")
  end
  
else 
  reaper.ShowConsoleMsg("Is A track selected?\n")
end
