-- Work in progress

deviceMode = 23 -- 16 + reaper midi output device id.
msg_type = 11 -- CCs are message type 11, Note on: 8, etc.
channel = 0 -- actual channel - 1.
cc = 0
lastTrackParamValues = {}

function run()
  inputEvent = {reaper.MIDI_GetRecentInputEvent(0)} -- table of returned values.
  cc = string.byte(inputEvent[2], 2)
  ccValue = string.byte(inputEvent[2], 3)
  if cc ~= lastCC or ccValue ~= lastCCValue then
    --[[if ccValue == 0 then
      reaper.StuffMIDIMessage(deviceMode, msg_type * 16 + channel, cc, 0)
    else 
      reaper.StuffMIDIMessage(deviceMode, msg_type * 16 + channel, cc, 127)
    end]]
    reaper.ShowConsoleMsg("Input CC and Value: "..cc .. "-" .. ccValue .. "\n\n")
    lastCC = cc
    lastCCValue = ccValue
  end
  
  num_tracks = reaper.CountSelectedTracks(0)
  for i = 0, num_tracks - 1 do
      lastTouchedFx = {reaper.GetLastTouchedFX()}
      last_fx_id = lastTouchedFx[3]
      last_fx_param = lastTouchedFx[4]
      track = reaper.GetSelectedTrack2(0, i, true)
      paramInfo = {reaper.TrackFX_GetParam(track, last_fx_id, last_fx_param)}
      paramValue = paramInfo[1]
      if paramValue ~= lastTrackParamValues[i] then
        if paramValue == 0 then
          reaper.StuffMIDIMessage(deviceMode, msg_type * 16 + channel, cc, 0)
        else 
          reaper.StuffMIDIMessage(deviceMode, msg_type * 16 + channel, cc, 127)
        end
        reaper.ShowConsoleMsg("Current Param Value: "..paramValue.."\n")
        lastTrackParamValues[i] = paramValue
      end
  end

  reaper.defer(run)
end

function onExit()
  reaper.ShowConsoleMsg("\nExited");
end

run()
reaper.atexit(onExit)

 



