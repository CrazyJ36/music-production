--[[
  WORK IN PROGRESS
]]

--channel = msg:byte(1) & 0x0F
   --cc = msg:byte(2)
--ccValue = msg:byte(3)

eviceMode = 23 -- 16 + reaper midi output device id.
trackIter = 0
selectedTrackOnly = false
fx = {}
params = {}
ccs = {}
tracks = {}
ccInc = 0
gotCC = false
gotParam = false
lastInputEvent = {reaper.MIDI_GetRecentInputEvent(0)}
lastTouchedFx = {reaper.GetLastTouchedFX()}
lastParam = {
  reaper.TrackFX_GetParamIdent(
    reaper.GetLastTouchedTrack(), 
    lastTouchedFx[3], lastTouchedFx[4]
  )
}
reaper.ClearConsole()

function main()
  for i = 0, 0, reaper.CountTracks(0) do
    tracks[i] = reaper.GetTrack(0, i)
  end
  
  if #params < 1 then -- < 1 for two pedals
    if not gotCC then
      reaper.runloop(getCC)
    else
      if not gotParam then
        reaper.runloop(getParam)
      end
    end
  else 
    setParam()
  end
  --[[if paramValue ~= params[i] then
    if paramValue == 0 then
      reaper.StuffMIDIMessage(deviceMode, msgType + channel, cc, 0)
    else 
      reaper.StuffMIDIMessage(deviceMode, msgType + channel, cc, 127)
    end
    lastParamValues[i] = paramValue
  end]]
  
  reaper.defer(main)
end

function getCC() 
  reaper.ShowConsoleMsg("getting cc\n")
  currentInputEvent = {reaper.MIDI_GetRecentInputEvent(0)}
  if currentInputEvent[2] ~= nil then
    msg = currentInputEvent[2]
    msgType = msg:byte(1) & 0xF0
    if currentInputEvent[1] ~= 0 and 
      msg ~= lastInputEvent[2] and 
        msgType == 176 then
      ccs[ccInc] = msg:byte(2)
      lastInputEvent[2] = currentInputEvent[2]
      gotParam = false
      gotCC = true
      reaper.ShowConsoleMsg("returning from getCC\n")
      return
    end
  end
end

function getParam() 
  reaper.ShowConsoleMsg("getting param\n")
  lastTouchedFx = {reaper.GetLastTouchedFX()}
  currentParam = {reaper.TrackFX_GetParamIdent(
    reaper.GetLastTouchedTrack(), 
    lastTouchedFx[3], lastTouchedFx[4]
  )}
  if currentParam[1] and currentParam[2] ~= lastParam[2] then
    lastParam[2] = currentParam[2]
    fx[ccInc] = lastTouchedFx[3]
    params[ccInc] = lastTouchedFx[4]
    ccInc = ccInc + 1
    gotCC = false
    gotParam = true
    reaper.ShowConsoleMsg("returning from getParam\n")
    return
  end
end

function setParam()
  if selectedTrackOnly then
    track = reaper.GetLastTouchedTrack()
  else 
    if trackIter == reaper.CountTracks(0) then
      trackIter = 0
    end
    track = reaper.GetTrack(0, trackIter)
  end
  
  currentInputEvent = {reaper.MIDI_GetRecentInputEvent(0)}
  msg = currentInputEvent[2]
  if msg ~= nil and currentInputEvent[1] ~= 0 then
    msgType = msg:byte(1) & 0xF0
    if msg ~= lastInputEvent[2] and 
    msgType == 176 then
      for i = 0, #ccs, 1 do
      if msg:byte(2) == ccs[i] then
        if msg:byte(3)== 127 then
          reaper.ShowConsoleMsg("setting param high\n")
          reaper.TrackFX_SetParam(
            track, -- if track == last touched track
            fx[i], -- should be number
            params[i], -- input is not on, warning.
            1.0
          )
         else
           reaper.ShowConsoleMsg("setting param low\n")
           reaper.TrackFX_SetParam(
             track,
             fx[i],
             params[i], 
             0.0
           )
         end
       end
     end
   end
  end

  if not selectedTrackOnly then 
    trackIter = trackIter + 1 
  end
end

function onExit()
  reaper.ShowConsoleMsg("\nExited\n");
end

main()
reaper.atexit(onExit)
