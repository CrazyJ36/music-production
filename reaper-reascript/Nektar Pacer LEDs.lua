-- Work in progress

deviceMode = 23 -- 16 + reaper midi output device id.
msg_type = 11 -- CCs are message type 11, Note on: 8, etc.
channel = 0 -- actual channel - 1.
cc = 0

gotLastTrackValue = {}

function run()
  inputEvent = {reaper.MIDI_GetRecentInputEvent(0)} -- table of returned values.
  cc = string.byte(inputEvent[2], 2)
  ccValue = string.byte(inputEvent[2], 3)
  
  if cc ~= lastCC or ccValue ~= lastCCValue then
    if ccValue == 0 then
      reaper.StuffMIDIMessage(deviceMode, msg_type * 16 + channel, cc, 0)
    else 
      reaper.StuffMIDIMessage(deviceMode, msg_type * 16 + channel, cc, 127)
    end
    reaper.ShowConsoleMsg(cc .. " " .. ccValue .. "\n\n")
    lastCC = cc
    lastCCValue = ccValue
  end
  
  num_tracks = reaper.CountSelectedTracks(0)
  for i = 0, num_tracks - 1 do
    gotLastTrackValue[i] = false
    
    if not gotLastTrackValue[i] then
    
      track = reaper.GetSelectedTrack(0, i)
      if track then
        lastTouchedFx = {reaper.GetLastTouchedFX()}
        last_fx_id = lastTouchedFx[3]
        last_fx_param = lastTouchedFx[4]
    
        paramValue = {reaper.TrackFX_GetParam(track, last_fx_id, last_fx_param)}
        if paramValue[1] ~= lastParamValue then
          reaper.ShowConsoleMsg(paramValue[1].."\n")
          lastParamValue = paramValue[1]
        end
      end
      gotLastTrackValue[i] = true
    end
  end
 
  
  
  reaper.defer(run)
end

function onExit()
  reaper.ShowConsoleMsg("\nExited");
end

run()
reaper.atexit(onExit)

 



