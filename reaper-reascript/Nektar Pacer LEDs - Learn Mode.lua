--[[
  WORK IN PROGRESS
]]

--channel = msg:byte(1) & 0x0F
--cc = msg:byte(2)
--ccValue = msg:byte(3)
--msgType = inputEvent[2]:byte(1) & 0xF0

reaper.ClearConsole()
scriptName = "Nektar Pacer LEDs - Learn Mode"
deviceMode = 23 -- 16 + reaper midi output device id.
maxLearnCount = 4 -- starts at one.
learnBtnBounds = {5, 5, 60, 20}
quitBtnBounds = {335, 5, 60, 20}
resetBtnBounds = {335, 30, 60, 20}
learningStateText = ""
tracks = {}
ccs = {}
fxs = {}
params = {}
minValues = {}
maxValues = {}
fxNames = {}
if reaper.HasExtState(scriptName, "tracks") and 
  reaper.HasExtState(scriptName, "ccs") and
  reaper.HasExtState(scriptName, "fxs") and
  reaper.HasExtState(scriptName, "params") and
  reaper.HasExtState(scriptName, "minValues") and
  reaper.HasExtState(scriptName, "maxValues") and
  reaper.HasExtState(scriptName, "fxNames") then
  storedTracks = reaper.GetExtState(scriptName, "tracks")
  storedCCs = reaper.GetExtState(scriptName, "ccs")
  storedFxs = reaper.GetExtState(scriptName, "fxs")
  storedParams = reaper.GetExtState(scriptName, "params")
  storedMinValues = reaper.GetExtState(scriptName, "minValues")
  storedMaxValues = reaper.GetExtState(scriptName, "maxValues")
  storedFxNames = reaper.GetExtState(scriptName, "fxNames")
  for i in string.gmatch(storedTracks, '([^,]+)') do
    table.insert(tracks, i)
  end
  for i in string.gmatch(storedCCs, '([^,]+)') do
    table.insert(ccs, i)
  end
  for i in string.gmatch(storedFxs, '([^,]+)') do
    table.insert(fxs, i)
  end
  for i in string.gmatch(storedParams, '([^,]+)') do
    table.insert(params, i)
  end
  for i in string.gmatch(storedMinValues, '([^,]+)') do
    table.insert(minValues, i)
  end
  for i in string.gmatch(storedMaxValues, '([^,]+)') do
    table.insert(maxValues, i)
  end
  for i in string.gmatch(storedFxNames, '([^,]+)') do
    table.insert(fxNames, i)
  end
  
  for i = 1, #fxNames do
    reaper.ShowConsoleMsg("tracks: "..tracks[i].."\n")
  end
end

oldInputEvent = {reaper.MIDI_GetRecentInputEvent(0)}
oldTouchedFx = {reaper.GetLastTouchedFX()}
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

gfx.init(scriptName, 400, 300)

function main()
  if terminate then 
    return
  end

  if learningState then
    if #fxNames < maxLearnCount then
      if not gotCC then
        reaper.runloop(learnCC())
      elseif not gotParam then
        reaper.runloop(learnParam())  
      end
    else
      learningState = false
      learningStateText = "Max CCs Learned"
    end
  elseif #fxNames > 0 then
    setParamAndLed()
  end

  if not learningState then
    learningStateText = "Press Learn"
  end

  mappedCCsText = ""
  for i = 1, #fxNames do
    if tracks[i] == 0 then
      trackText = "Master"
    else 
      trackText = tracks[i]
    end
    mappedCCsText = mappedCCsText.."CC "..
      ccs[i].." is mapped to track "..trackText..":\n"..fxNames[i].."\n\n"
  end

  ui()
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
    if learningState then
      gotCC = true
      gotParam = false
    end
    reaper.ShowConsoleMsg("returning from learnCC()\n")
    return
  end
end

function learnParam() 
  learningStateText = "Learning Param"
  currentTouchedFx = {reaper.GetLastTouchedFX()}
  currentParamId = {reaper.TrackFX_GetParamIdent(
    reaper.GetLastTouchedTrack(), 
    currentTouchedFx[3], currentTouchedFx[4]
  )}
  currentParam = {reaper.TrackFX_GetParam(
    reaper.GetLastTouchedTrack(),
    currentTouchedFx[3], currentTouchedFx[4]
  )}
  
  if currentTouchedFx[1] and currentParamId[1] and 
  currentTouchedFx[4] ~= oldTouchedFx[4] and
  (currentParamId[2] ~= oldParamId[2] or 
  currentParam[1] ~= oldParam[1]) then
    oldTouchedFx[4] = currentTouchedFx[4]
    oldParamId[2] = currentParamId[2]
    oldParam[1] = currentParam[1]
    fxName = {reaper.TrackFX_GetFXName(
      reaper.GetLastTouchedTrack(), 
      currentTouchedFx[3]
    )}
    paramName = {reaper.TrackFX_GetParamName(
      reaper.GetLastTouchedTrack(), 
      currentTouchedFx[3],
      currentTouchedFx[4]
    )}
    table.insert(tracks, currentTouchedFx[2])
    table.insert(fxs, currentTouchedFx[3])
    table.insert(params, currentTouchedFx[4])
    table.insert(minValues, currentParam[2])
    table.insert(maxValues, currentParam[3])
    table.insert(fxNames, fxName[2]..": "..paramName[2])
    reaper.SetExtState(scriptName, "tracks", table.concat(tracks, ","), false)
    reaper.SetExtState(scriptName, "ccs", table.concat(ccs, ","), false)
    reaper.SetExtState(scriptName, "fxs", table.concat(fxs, ","), false)
    reaper.SetExtState(scriptName, "params", table.concat(params, ","), false)
    reaper.SetExtState(scriptName, "minValues", table.concat(minValues, ","), false)
    reaper.SetExtState(scriptName, "maxValues", table.concat(maxValues, ","), false)
    reaper.SetExtState(scriptName, "fxNames", table.concat(fxNames, ","), false)
    if learningState then
      gotParam = true
      gotCC = false
    end
    reaper.ShowConsoleMsg("returning from learnParam()\n")
    return
  end
end

function setParamAndLed()
  inputEvent = getInputEvent()
  if inputEvent[1] then
    for i = 1, #fxNames do
      if inputEvent[2] == tonumber(ccs[i]) then
        if tonumber(tracks[i]) > 0 then
          -- set param
          if inputEvent[3] == 0 then
            reaper.TrackFX_SetParam(
              reaper.GetTrack(0, tracks[i] - 1),
              fxs[i], params[i],  minValues[i]
            )
          else 
            reaper.TrackFX_SetParam(
              reaper.GetTrack(0, tracks[i] - 1),
              fxs[i], params[i], maxValues[i]
            )
          end
          -- set led
          paramInfo = {reaper.TrackFX_GetParam(
            reaper.GetTrack(0, tracks[i] - 1), fxs[i], params[i]
          )}
          channel = inputEvent[4]
          msgType = inputEvent[5]
          if paramInfo[1] == 0 then
            reaper.StuffMIDIMessage(
              deviceMode, msgType + channel, ccs[i], 0
            )
          else 
            reaper.StuffMIDIMessage(
              deviceMode, msgType + channel, ccs[i], 127
            )
          end
          
        else
          -- set param for master
          if inputEvent[3] == 0 then
            reaper.TrackFX_SetParam(
              reaper.GetMasterTrack(0),
                fxs[i], params[i], minValues[i]
              )
          else
            reaper.TrackFX_SetParam(
              reaper.GetMasterTrack(0),
              fxs[i], params[i], maxValues[i]
            )
          end
          -- set led for master
          paramInfo = {reaper.TrackFX_GetParam(
            reaper.GetMasterTrack(0), fxs[i], params[i]
          )}
          channel = inputEvent[4]
          msgType = inputEvent[5]
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
end

function ui()
  gfx.rect(
    learnBtnBounds[1],
    learnBtnBounds[2],
    learnBtnBounds[3],
    learnBtnBounds[4],
    learningState
  )
  gfx.rect(
    quitBtnBounds[1],
    quitBtnBounds[2],
    quitBtnBounds[3],
    quitBtnBounds[4],
    false
  )
  gfx.rect(
    resetBtnBounds[1],
    resetBtnBounds[2],
    resetBtnBounds[3],
    resetBtnBounds[4],
    false
  )
  --[[learnBtnBounds = {5, 5, 60, 20}
  quitBtnBounds = {335, 5, 60, 20}
  resetBtnBounds = {335, 30, 60, 20}]]
  gfx.x = 10
  gfx.y = 10
  gfx.drawstr("Learn")
  gfx.x = 345
  gfx.y = 10
  gfx.drawstr("Quit")
  gfx.x = 345
  gfx.y = 35
  gfx.drawstr("Reset")
  
gfx.line(0, 55, 400, 55)

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
  if mouseState and
  not lastMouseState and
  gfx.mouse_x > resetBtnBounds[1] and
  gfx.mouse_y > resetBtnBounds[2] and
  gfx.mouse_x < resetBtnBounds[3] + resetBtnBounds[1] and
  gfx.mouse_y < resetBtnBounds[4] + resetBtnBounds[2] then
    learningState = false
    tracks = {}
    ccs = {}
    fxs = {}
    params = {}
    minValues = {}
    maxValues = {}
    fxNames = {}
    reaper.SetExtState(scriptName, "tracks", table.concat(tracks, ","), false)
    reaper.SetExtState(scriptName, "ccs", table.concat(ccs, ","), false)
    reaper.SetExtState(scriptName, "fxs", table.concat(fxs, ","), false)
    reaper.SetExtState(scriptName, "params", table.concat(params, ","), false)
    reaper.SetExtState(scriptName, "minValues", table.concat(minValues, ","), false)
    reaper.SetExtState(scriptName, "maxValues", table.concat(maxValues, ","), false)
    reaper.SetExtState(scriptName, "fxNames", table.concat(fxNames, ","), false)
    
    reaper.ClearConsole()
  end
  lastMouseState = mouseState
  
  gfx.x = 75
  gfx.y = 10
  gfx.drawstr(learningStateText)
  gfx.x = 5
  gfx.y = 60
  gfx.drawstr(mappedCCsText)
  
end

function onExit()
  reaper.ShowConsoleMsg("Exited")
  gfx.quit()
end

main()
reaper.atexit(onExit)
