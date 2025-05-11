--[[
  WORK IN PROGRESS
  Specifically for Nektar Pacer foot controller.
  Use Reapers' parameter learn for desired parameters
  and when you change A param in the plugin the LEDs
  on the Pacer will reflect.
]]


-- CCs are message type 11, or 176, or 0xF0,
-- Note on: 9, or 144, or 0x90,
-- Note off: 8, or 128, or 0x80
-- can divide or multiply by 16.

deviceMode = 23 -- 16 + reaper midi output device id.
lastParamValues = {}

function run()
  inputEvent = {reaper.MIDI_GetRecentInputEvent(0)}
  inputDevice = inputEvent[4]
  msg = inputEvent[2]
  if msg ~= 0 and msg ~= lastInputEvent then
    cc = msg:byte(2)
    ccValue = msg:byte(3)
    channel = msg:byte(1) & 0x0F
    msgType = msg:byte(1) & 0xF0
    lastInputEvent = msg
    reaper.ShowConsoleMsg(
      "Last midi event:\nmsgType: "..msgType..",\nchannel: "..channel + 1
      ..",\ncc: "..cc..",\nccValue: "..ccValue.."\nInput device Id: "
      ..inputDevice.."\n\n"
    )
  end
  
  num_tracks = reaper.CountTracks(0)
  for i = 0, num_tracks - 1 do
      lastTouchedFx = {reaper.GetLastTouchedFX()}
      last_fx_id = lastTouchedFx[3]
      last_fx_param = lastTouchedFx[4]
      track = reaper.GetTrack(0, i)
      paramInfo = {reaper.TrackFX_GetParam(track, last_fx_id, last_fx_param)}
      paramValue = paramInfo[1]
      if paramValue ~= lastParamValues[i] then
        if paramValue == 0 then
          reaper.StuffMIDIMessage(deviceMode, msgType + channel, cc, 0)
        else 
          reaper.StuffMIDIMessage(deviceMode, msgType + channel, cc, 127)
        end
        reaper.ShowConsoleMsg("Last Param Value: "..paramValue.."\n")
        lastParamValues[i] = paramValue
      end
  end

  reaper.defer(run)
end

function onExit()
  gfx.quit()
  reaper.ShowConsoleMsg("\nExited\n");
end

run()
reaper.atexit(onExit)
