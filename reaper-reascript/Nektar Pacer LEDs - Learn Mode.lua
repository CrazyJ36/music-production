--[[
  WORK IN PROGRESS
]]

--channel = msg:byte(1) & 0x0F
--cc = msg:byte(2)
--ccValue = msg:byte(3)
--msgType = inputEvent[2]:byte(1) & 0xF0

deviceMode = 23 -- 16 + reaper midi output device id.
ccCount = 1 -- 1 for two pedals

learnBtnBounds = {5, 5, 60, 20}
quitBtnBounds = {235, 5, 60, 20}
learnBtnToggleState = false
terminate = false
learningState = false
learningStateText = ""
gotCC = false
gotParam = false
trackIter = 0
selectedTrackOnly = false
ccs = {}
fx = {}
params = {}
minValues = {}
maxValues = {}
learnInc = 0
lastInputEvent = {reaper.MIDI_GetRecentInputEvent(0)}
lastTouchedFx = {reaper.GetLastTouchedFX()}
lastParam = {
  reaper.TrackFX_GetParamIdent(
    reaper.GetLastTouchedTrack(), 
    lastTouchedFx[3],
    lastTouchedFx[4]
  )
}
reaper.ClearConsole()

function main()
  gfx.init("Learn CCs then Params", 300, 100)
  ui()
  if learningState then
    if not gotCC then
      learningStateText = "Learning CC"
      reaper.runloop(getCC())
    elseif not gotParam then
      learningStateText = "Learning Param"
      reaper.runloop(getParam())
    end
  else
    reaper.runloop(setParam())
  end
  if terminate then 
    return
  end
  reaper.defer(main)
end

function getCC() 
  reaper.ShowConsoleMsg("getCC()\n")
  if reaper.MIDI_GetRecentInputEvent(0) ~= 0 then
    currentInputEvent = {reaper.MIDI_GetRecentInputEvent(0)}
    if currentInputEvent[2]:byte(1) & 0xF0 == 176 and
      currentInputEvent[2] ~= lastInputEvent[2] then
      ccs[learnInc] = currentInputEvent[2]:byte(2)
      lastInputEvent[2] = currentInputEvent[2]
      gotCC = true
      reaper.ShowConsoleMsg("returning from getCC\n")
      return
    end
  end
end

function getParam() 
  reaper.ShowConsoleMsg("getParam()\n")
  lastTouchedFx = {reaper.GetLastTouchedFX()}
  currentParamId = {reaper.TrackFX_GetParamIdent(
    reaper.GetLastTouchedTrack(), 
    lastTouchedFx[3], lastTouchedFx[4]
  )}
   
  if currentParamId[1] and currentParamId[2] ~= lastParam[2] then
    lastParam[2] = currentParamId[2]
    fx[learnInc] = lastTouchedFx[3]
    params[learnInc] = lastTouchedFx[4]
    
    param = {reaper.TrackFX_GetParam(
      reaper.GetLastTouchedTrack(),
      fx[learnInc],
      params[learnInc]
    )}
    reaper.ShowConsoleMsg("fx: "..fx[learnInc].."\n"..params[learnInc].."\n")
    minValues[learnInc] = param[2]
    maxValues[learnInc] = param[3]
    
    learnInc = learnInc + 1
    gotParam = true
    if learningState then
      gotCC =  false
      gotParam = false
      getCC()
    end
    reaper.ShowConsoleMsg("returning from getParam\n")
    return
  end
end

function setParam()
  reaper.ShowConsoleMsg("setParam()\n")
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
      for i = 0, #ccs do
      if msg:byte(2) == ccs[i] then
        if msg:byte(3) == 127 then
          reaper.ShowConsoleMsg("setting high\n")
          reaper.TrackFX_SetParam(
            track, 
            fx[i], 
            params[i], 
            maxValues[i]
          )
          reaper.StuffMIDIMessage(deviceMode, msgType + msg:byte(3), ccs[i], 127)
        else
          reaper.ShowConsoleMsg("setting low\n")
           reaper.TrackFX_SetParam(
             track,
             fx[i],
             params[i], 
             minValues[i]
           )
            reaper.StuffMIDIMessage(deviceMode, msgType + msg:byte(3), ccs[i], 0)
         end
       end
     end
   end
  end
  if not selectedTrackOnly then 
    trackIter = trackIter + 1 
  end
end


function ui()
  gfx.rect(
    learnBtnBounds[1],
    learnBtnBounds[2],
    learnBtnBounds[3],
    learnBtnBounds[4],
    false
  )
  gfx.rect(
    quitBtnBounds[1],
    quitBtnBounds[2],
    quitBtnBounds[3],
    quitBtnBounds[4],
    false
  )

  mouseState = gfx.mouse_cap & 1 == 1
  if mouseState and
  not lastMouseState and
  gfx.mouse_x > learnBtnBounds[1] and
  gfx.mouse_y > learnBtnBounds[2] and
  gfx.mouse_x < learnBtnBounds[3] + learnBtnBounds[1] and
  gfx.mouse_y < learnBtnBounds[4] + learnBtnBounds[2] then
    gotCC = false
    gotParam = false
    learningState = not learningState
  end
 
  if mouseState and 
  not lastMouseState and
  gfx.mouse_x > quitBtnBounds[1] and
  gfx.mouse_y > quitBtnBounds[2] and
  gfx.mouse_x < quitBtnBounds[3] + quitBtnBounds[1] and 
  gfx.mouse_y < quitBtnBounds[4] + quitBtnBounds[2] then
    terminate = true
  end
  lastMouseState = mouseState
  
  --[[learnBtnBounds = {5, 5, 60, 20}
  quitBtnBounds = {235, 5, 60, 20}]]
  gfx.x = 10
  gfx.y = 10
  gfx.drawstr("Learn")
  gfx.x = 240
  gfx.y = 10
  gfx.drawstr("Quit")
  
  if learningState then
    gfx.x = 75
    gfx.y = 10
    gfx.drawstr(learningStateText)
  end
       
end

function onExit()
  gfx.quit()
  reaper.ShowConsoleMsg("\nExited\n");
end

main()
reaper.atexit(onExit)
