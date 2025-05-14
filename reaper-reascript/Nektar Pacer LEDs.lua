--[[
  Work in progress.
  Specifically made for Nektar Pacer foot controller.
  Causes Reaper learned param changes to reflect on Pacer LEDs if
  its switches are set to LED > Midi on.
]]
-- CCs are message type 11, or 176
midiOutput = 23 -- 16 + reaper midi output device id.

reaper.ClearConsole()
function run()
 
  inputEvent = {reaper.MIDI_GetRecentInputEvent(0)}
  if inputEvent[1] ~= 0 then
    channel = inputEvent[2]:byte(1) & 0x0F
    msgType = inputEvent[2]:byte(1) & 0xF0
    if msgType == 176 then
      fx = {reaper.GetLastTouchedFX()}
      if fx[1] then
        mappedCC = {reaper.TrackFX_GetNamedConfigParm(
          reaper.GetLastTouchedTrack(),
          fx[3],
          "param."..fx[4]..".learn.midi2"
        )}
        
        if mappedCC[1] then
          reaper.ShowConsoleMsg("mappedCC for last Param: "..mappedCC[2].."\n")
        
          paramInfo = {reaper.TrackFX_GetParam(
            reaper.GetLastTouchedTrack(), 
            fx[3], 
            fx[4]
          )}
          if paramInfo[1] == 0 then
            reaper.StuffMIDIMessage(midiOutput, msgType + channel, mappedCC[2], 0)
          else 
            reaper.StuffMIDIMessage(midiOutput, msgType + channel, mappedCC[2], 127)
          end
         
        else 
          reaper.ShowConsoleMsg("No mapped CCs for param\n")
        end
        
      else 
        reaper.ShowConsoleMsg("No valid last touched FX parameter\n")
      end
    else 
      reaper.ShowConsoleMsg("Only supports CC messages")
    end
  else 
    reaper.ShowConsoleMsg("No recent MIDI input event\n")
  end

  reaper.defer(run)
end

function onExit()
  reaper.ShowConsoleMsg("Exited\n");
end

run()
reaper.atexit(onExit)
