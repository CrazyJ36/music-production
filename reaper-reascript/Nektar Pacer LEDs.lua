-- Work in progress

-- CCs are message type 11, or 176, or 0xF0,
-- Note on: 9, or 144, or 0x90,
-- Note off: 8, or 128, orr 0x80
-- can divide or multiply by 16.

deviceMode = 23 -- 16 + reaper midi output device id.
lastTrackParamValues = {}

function run()
  inputEvent = {reaper.MIDI_GetRecentInputEvent(0)}
  deviceId = inputEvent[4]
  msg = inputEvent[2]
  if msg ~= 0 and msg ~= lastInputEvent then
    cc = msg:byte(2)
    ccValue = msg:byte(3)
    channel = msg:byte(1) & 0x0F -- actual channel + 1
    msgType = msg:byte(1) & 0xF0 
    reaper.ShowConsoleMsg(
      "Last midi event:\nmsgType: "..msgType..",\nchannel: "..channel
      ..",\ncc: "..cc..",\nccValue: "..ccValue.."\nInput deviceId: "..deviceId.."\n\n"
    )
    lastInputEvent = msg
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
          reaper.StuffMIDIMessage(deviceMode, msgType + channel, cc, 0)
        else 
          reaper.StuffMIDIMessage(deviceMode, msgType + channel, cc, 127)
        end
        reaper.ShowConsoleMsg("Last Param Value: "..paramValue.."\n")
        lastTrackParamValues[i] = paramValue
      end
  end

  reaper.defer(run)
end

function onExit()
  reaper.ShowConsoleMsg("\nExited\n");
end

run()
reaper.atexit(onExit)

 



