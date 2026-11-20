fx = "VST3: bx_tuner (Plugin Alliance)"
fx_param_name = "Tuner Mode"

track = reaper.GetSelectedTrack(0, 0)
if track ~= nil then
  
  found_fx = false
  num_fx = reaper.TrackFX_GetCount(track)
  if num_fx > 0 then
      
    for i = 0, num_fx do
      
      retval, fx_name = reaper.TrackFX_GetFXName(track, i)
      if retval then
        
        if fx_name == fx then
          found_fx = true
          
          if reaper.TrackFX_GetFloatingWindow(track, i) then
            reaper.TrackFX_SetEnabled(track, i, false)
            reaper.TrackFX_Show(track, i, 2)
            
          else 
            reaper.TrackFX_Show(track, i, 3)
             reaper.TrackFX_SetEnabled(track, i, true)
          end
          
          num_params = reaper.TrackFX_GetNumParams(track, i)
          for j = 0, num_params do
            
            retval, param_name = reaper.TrackFX_GetParamName(track, i, j, "")
            if param_name == fx_param_name then
            
              retval = reaper.TrackFX_SetParam(track, 0, j, 1)
              if not retval then
                reaper.ShowConsoleMsg("Failed to toggle tuner mute.\n")
              end
              
              break
            end
          
          end
          
          break
        end
        
      end 
      
    end
    
    if not found_fx then
      reaper.ShowConsoleMsg("Is bx_tuner added to this track?\n")
    end
    
  else 
    reaper.ShowConsoleMsg("Are there any FX on the selected track? Script needs bx_tuner added.\n")
  end
  
else 
  reaper.ShowConsoleMsg("Is A track selected?\n")
end
