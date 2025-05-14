--[[
  Work in progress.
  Specifically made for Nektar Pacer foot controller.
  AlloCauses Reaper param changes to reflect on Pacer LEDs when
  its switches are set to LED > Midi on.
]]
-- CCs are message type 11, or 176
midiOutput = 23 -- 16 + reaper midi output device id.

reaper.ClearConsole()
function run()
  fx = {reaper.GetLastTouchedFX()}
  mappedCC = {reaper.TrackFX_GetNamedConfigParm(
    reaper.GetTrack(0, 0),
    fx[3],
    "param."..fx[4]..".learn.midi2"
  )}
  --reaper.ShowConsoleMsg("success: "..tostring(mappedCC[1]).."data: "..mappedCC[2].."\n")

  inputEvent = {reaper.MIDI_GetRecentInputEvent(0)}
  cc = inputEvent[2]:byte(2) 
  channel = inputEvent[2]:byte(1) & 0x0F
  msgType = inputEvent[2]:byte(1) & 0xF0

  paramInfo = {reaper.TrackFX_GetParam(reaper.GetTrack(0, 0), fx[3], fx[4])}
  paramValue = paramInfo[1]
  if paramValue == 0 then
    reaper.StuffMIDIMessage(midiOutput, 176 + channel, mappedCC[2], 0)
  else 
    reaper.StuffMIDIMessage(midiOutput, 176 + channel, mappedCC[2], 127)
  end
 
  reaper.defer(run)
end

function onExit()
  reaper.ShowConsoleMsg("\nExited\n");
end

run()
reaper.atexit(onExit)
