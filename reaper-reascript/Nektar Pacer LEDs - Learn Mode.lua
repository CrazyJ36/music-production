--[[
  WORK IN PROGRESS
]]

--channel = msg:byte(1) & 0x0F
--cc = msg:byte(2)
--ccValue = msg:byte(3)
--msgType = inputEvent[2]:byte(1) & 0xF0

deviceMode = 23 -- 16 + reaper midi output device id.
maxLearnCount = 2 -- 2 for two pedals, starts at one.
learnBtnBounds = {5, 5, 60, 20}
quitBtnBounds = {235, 5, 60, 20}
terminate = false
learningState = false
learningStateText = ""
uiInfo = "Some ui info to add to."
gotCC = false
ccs = {}
fxs = {}
params = {}
minValues = {}
maxValues = {}
oldInputEvent = {reaper.MIDI_GetRecentInputEvent(0)}
oldTouchedFx = {reaper.GetLastTouchedFX()}
if not oldTouchedFx[1] then
  reaper.ShowConsoleMsg("No Touched FX globally")
end
oldParamId = {
  reaper.TrackFX_GetParamIdent(
    reaper.GetLastTouchedTrack(), 
    oldTouchedFx[3],
    oldTouchedFx[4]
  )
}
oldParam = {reaper.TrackFX_GetParam(
  reaper.GetLastTouchedTrack(),
  oldTouchedFx[3],
  oldTouchedFx[4]
)}
reaper.ClearConsole()

function main()
  if terminate then 
    return
  end
  gfx.init("Learn CCs then Params", 300, 100)
  ui()
  
  if learningState then
    if #params < maxLearnCount then
      if not gotCC then
        reaper.runloop(learnCC())
      else
        reaper.runloop(learnParam())
      end
    else
      learningState = false
    end
  elseif #params > 0 then
    setParamAndLed()
  end
  
  reaper.defer(main)
end

function getInputEvent() 
  currentInputEvent = {reaper.MIDI_GetRecentInputEvent(0)}
  if currentInputEvent[1] ~= 0 and
  currentInputEvent[2] ~= oldInputEvent[2] and
  currentInputEvent[2]:byte(1) & 0xF0 == 176 then
    oldInputEvent[2] = currentInputEvent[2]
    cc = currentInputEvent[2]:byte(2)
    ccValue = currentInputEvent[2]:byte(3)
    channel = currentInputEvent[2]:byte(1) & 0x0F
    msgType = currentInputEvent[2]:byte(1) & 0xF0
    return {true, cc, ccValue, channel, msgType}
  else 
    return {false}
  end
end

function learnCC()
  learningStateText = "Learning CC"
  inputEvent = getInputEvent()
  if inputEvent[1] then
    table.insert(ccs, inputEvent[2])
    gotCC = true
    reaper.ShowConsoleMsg("Learned CC\n")
    return
  end
end

function learnParam() 
  learningStateText = "Learning Param"
  currentTouchedFx = {reaper.GetLastTouchedFX()}
  if not currentTouchedFx[1] then
    reaper.ShowConsoleMsg("No Touched FX in learnParam")
  end
  currentParamId = {reaper.TrackFX_GetParamIdent(
    reaper.GetLastTouchedTrack(), 
    currentTouchedFx[3], currentTouchedFx[4]
  )}
  currentParam = {reaper.TrackFX_GetParam(
    reaper.GetLastTouchedTrack(),
    currentTouchedFx[3], currentTouchedFx[4]
  )}
  if currentParamId[1] and (currentParamId[2] ~= oldParamId[2] or 
  currentParam[1] ~= oldParam[1]) then
    oldParamId[2] = currentParamId[2]
    oldParam[1] = currentParam[1]
    table.insert(fxs, currentTouchedFx[3])
    table.insert(params, currentTouchedFx[4])
    table.insert(minValues, currentParam[2])
    table.insert(maxValues, currentParam[3])
    gotCC =  false
    reaper.ShowConsoleMsg("Learned Param\n")
    return
  end
end

function setParamAndLed(track)
  inputEvent = getInputEvent()
  if inputEvent[1] then
    cc = inputEvent[2]
    ccValue = inputEvent[3]
    channel = inputEvent[4]
    msgType = inputEvent[5]
    for i = 1, #params do
      if cc == ccs[i] then
        if ccValue == 0 then
          reaper.TrackFX_SetParam(
            reaper.GetLastTouchedTrack(),
            fxs[i] ,params[i],  minValues[i]
          )
        else 
          reaper.TrackFX_SetParam(
            reaper.GetLastTouchedTrack(),
            fxs[i], params[i], maxValues[i]
          )
        end
        paramInfo = {reaper.TrackFX_GetParam(
          reaper.GetLastTouchedTrack(), fxs[i], params[i]
        )}
        if paramInfo[1] == 0 then
          reaper.StuffMIDIMessage(
            deviceMode, msgType + channel, ccs[i], 0
          )
        else 
          reaper.StuffMIDIMessage(
            deviceMode, msgType + channel, ccs[i], 127
          )
    
        end
      end
    end
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
  
  gfx.x = 5
  gfx.y = 30
  gfx.drawstr(uiInfo)
       
end

function onExit()
  gfx.quit()
  reaper.ShowConsoleMsg("\nExited\n");
end

main()
reaper.atexit(onExit)
