-- Work in progress

deviceMode = 23 -- 16 + reaper midi output device id.
msg_type = 11 -- CCs are message type 11, Note on: 8, etc.
channel = 0 -- actual channel - 1.


function run()
  retval, buf, ts, devIdx, projPos, projLoopCnt = reaper.MIDI_GetRecentInputEvent(0)
  receivedCC = string.byte(buf, 2)
  receivedValue = string.byte(buf, 3)
  
  track = reaper.GetSelectedTrack(0, 0)
  last_retva, last_track_id, last_fx_id, last_fx_param = reaper.GetLastTouchedFX()
  
  if track then
    val, track, fxid, paramid, minval, maxval = reaper.TrackFX_GetParam(track, last_fx_id, last_fx_param)
    reaper.ShowConsoleMsg(val .. "\n")
  end
  
  if receivedCC ~= lastStoredCC then
    if receivedValue == 0 then
      reaper.StuffMIDIMessage(deviceMode, msg_type * 16 + channel, 0, 0)
    else 
      reaper.StuffMIDIMessage(deviceMode, msg_type * 16 + channel, 0, 127)
    end
    reaper.ShowConsoleMsg(receivedCC .. " " .. receivedValue .. "\n")
    lastStoredCC = receivedCC
  end
    
  reaper.defer(run)
end


function onexit()
  reaper.ShowConsoleMsg("Exited");
end

reaper.defer(run)
reaper.atexit(onexit)

 



