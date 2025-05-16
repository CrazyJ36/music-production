--[[
  Specifically made for Nektar Pacer foot controller.
  Causes Reaper learned param changes to reflect on Pacer LEDs if
  its switches are set to CC and LED > Midi on.
  
  To use in reaper: 
  Download or copy this script text to A new file, find your PACER midi output ID in Reapers' 
  Options menu > Preferences > Midi Outputs > and change the first 'midiOutput' line here 
  to 16 + Id number. Then find your Reaper resources directory by clicking the Options menu
  in Reaper > Show REAPER resource path in explorer > then save this script in to the 'Scripts'
  directory there. Then in the Reaper Actions menu > Show actions list > New action >
  Load reascript > select this script file > then run it whenever you want your LEDs
  to react to changes in the DAW. 
]]
midiOutput = 23 -- CHANGE THIS to 16 + reaper midi output device id.

reaper.ClearConsole()
function run()
 
  inputEvent = {reaper.MIDI_GetRecentInputEvent(0)}
  if inputEvent[1] ~= 0 then
    channel = inputEvent[2]:byte(1) & 0x0F
    msgType = inputEvent[2]:byte(1) & 0xF0
    if msgType == 176 then
      fx = {reaper.GetLastTouchedFX()}
      if fx[1] then
        for i = 1, reaper.CountTracks(0) do
          track = reaper.GetTrack(0, i - 1)
          mappedCC = {reaper.TrackFX_GetNamedConfigParm(
            track,
            fx[3],
            "param."..fx[4]..".learn.midi2"
          )}
          
          if mappedCC[1] then
            --reaper.ShowConsoleMsg("mappedCC for last Param: "..mappedCC[2].." on track: "..i.."\n")
          
            paramInfo = {reaper.TrackFX_GetParam(
              track, 
              fx[3], 
              fx[4]
            )}
            if paramInfo[1] == 0 then
              reaper.StuffMIDIMessage(midiOutput, msgType + channel, mappedCC[2], 0)
            else 
              reaper.StuffMIDIMessage(midiOutput, msgType + channel, mappedCC[2], 127)
            end
           
          else 
            --reaper.ShowConsoleMsg("No mapped CCs for param\n")
          end
        end
        
      else 
        --reaper.ShowConsoleMsg("No valid last touched FX parameter\n")
      end
    else 
     -- reaper.ShowConsoleMsg("Only supports CC messages")
    end
  else 
    --reaper.ShowConsoleMsg("No recent MIDI input event\n")
  end

  reaper.defer(run)
end

function onExit()
  --reaper.ShowConsoleMsg("Terminated Nektar Pacer LEDs successfully.\n");
end

run()
reaper.atexit(onExit)
