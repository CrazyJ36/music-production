--[[
  WORK IN PROGRESS
]]

--channel = msg:byte(1) & 0x0F
--cc = msg:byte(2)
--ccValue = msg:byte(3)
--msgType = inputEvent[2]:byte(1) & 0xF0

deviceMode = 23 -- 16 + reaper midi output device id.
ccCount = 2 -- 2 for two pedals

learnBtnBounds = {5, 5, 60, 20}
quitBtnBounds = {235, 5, 60, 20}
learnBtnToggleState = false
terminate = false
learningState = false
learningStateText = ""
gotCC = false
ccs = {}
fx = {}
params = {}
minValues = {}
maxValues = {}
oldInputEvent = {reaper.MIDI_GetRecentInputEvent(0)}
inputEvent = nil
lastTouchedFx = {reaper.GetLastTouchedFX()}
lastParamId = {
  reaper.TrackFX_GetParamIdent(
    reaper.GetLastTouchedTrack(), 
    lastTouchedFx[3],
    lastTouchedFx[4]
  )
}
lastParam = {reaper.TrackFX_GetParam(
  reaper.GetLastTouchedTrack(),
  lastTouchedFx[3],
  lastTouchedFx[4]
)}
reaper.ClearConsole()

function main()
  gfx.init("Learn CCs then Params", 300, 100)
  ui()
  if learningState and #ccs < ccCount then
    if not gotCC then
      learningStateText = "Learning CC"
      reaper.runloop(getCC())
    else
      learningStateText = "Learning Param"
      reaper.runloop(getParam())
    end
  elseif #params > 0 then
    setParam()
    setLeds()
  end

  if terminate then 
    return
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

function getCC()
  inputEvent = getInputEvent()
  if inputEvent[1] then
    table.insert(ccs, inputEvent[2])
    gotCC = true
    reaper.ShowConsoleMsg("returning from getCC()\n")
    return
  end
  inputEvent = nil
end

function getParam() 
  lastTouchedFx = {reaper.GetLastTouchedFX()}
  currentParamId = {reaper.TrackFX_GetParamIdent(
    reaper.GetLastTouchedTrack(), 
    lastTouchedFx[3], lastTouchedFx[4]
  )}
  currentParam = {reaper.TrackFX_GetParam(
    reaper.GetLastTouchedTrack(),
    lastTouchedFx[3],
    lastTouchedFx[4]
  )}
  if currentParamId[1] and (currentParamId[2] ~= lastParamId[2] or 
  currentParam[1] ~= lastParam[1]) then
    lastParamId[2] = currentParamId[2]
    lastParam[1] = currentParam[1]
    table.insert(fx, lastTouchedFx[3])
    table.insert(params, lastTouchedFx[4])
    table.insert(minValues, currentParam[2])
    table.insert(maxValues, currentParam[3])
    gotCC =  false
    reaper.ShowConsoleMsg("returning from getParam\n")
    return
  end
end

function setParam()
  inputEvent = getInputEvent()
  if inputEvent[1] then
    reaper.ShowConsoleMsg("setParam: getInputEvent[1] successful.\n")
    cc = inputEvent[2]
    ccValue = inputEvent[3]
    for i = 1, #ccs do
      if cc == ccs[i] then
        if ccValue == 0 then
          reaper.TrackFX_SetParam(
            reaper.GetLastTouchedTrack(),
            fx[i],
            params[i], 
            minValues[i]
          )
  
        else 
          reaper.TrackFX_SetParam(
            reaper.GetLastTouchedTrack(), 
            fx[i], 
            params[i], 
            maxValues[i]
          )
       end
     end
   end
 end
end

function setLeds()
  if inputEvent[1] then
    reaper.ShowConsoleMsg("setLeds: getInputEvent[1] successful.\n")
    for i = 1, #params do
      channel = inputEvent[4]
      msgType = inputEvent[5]
      paramInfo = {reaper.TrackFX_GetParam(
        reaper.GetLastTouchedTrack(), fx[i], params[i]
      )}
      if paramInfo[1] == 0 then
        reaper.ShowConsoleMsg("Setting led low")
        reaper.StuffMIDIMessage(
          deviceMode, msgType + channel, ccs[i], 0
        )
      else 
        reaper.ShowConsoleMsg("Setting led high")
        reaper.StuffMIDIMessage(
          deviceMode, msgType + channel, ccs[i], 127
        )
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
       
end

function onExit()
  gfx.quit()
  reaper.ShowConsoleMsg("\nExited\n");
end

main()
reaper.atexit(onExit)
