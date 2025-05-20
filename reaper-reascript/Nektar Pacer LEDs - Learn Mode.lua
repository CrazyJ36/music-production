--[[
  WORK IN PROGRESS
]]

--channel = msg:byte(1) & 0x0F
--cc = msg:byte(2)
--ccValue = msg:byte(3)
--msgType = inputEvent[2]:byte(1) & 0xF0

reaper.ClearConsole()
scriptName = "Nektar Pacer LEDs - Learn Mode"
maxLearnCount = 128 -- starts at one.
learnBtnBounds = {5, 5, 60, 20}
quitBtnBounds = {335, 5, 60, 20}
resetBtnBounds = {335, 30, 60, 20}
setupBtnBounds = {270, 5, 60, 20}
learningStateText = ""

if reaper.HasExtState(scriptName, "midiOutputId") then
  midiOutputId = reaper.GetExtState(scriptName, "midiOutputId")
else
  midiOutputId = ""
end
if reaper.HasExtState(scriptName, "midiChannel") then
  midiChannel = reaper.GetExtState(scriptName, "midiChannel")
else
  midiChannel = ""
end

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
end

function getLastTrack(fx) 
  if fx[2] == -1 then
    return reaper.GetMasterTrack(0)
  else
    return reaper.GetTrack(0, fx[2])
  end
end

oldInputEvent = {reaper.MIDI_GetRecentInputEvent(0)}

gfx.init(scriptName, 400, 300)

function main()
  if terminate then 
    return
  end

  if midiOutputId ~= "" and midiChannel ~= "" then
    if learningState then
      if #fxNames < maxLearnCount then
        if not gotCC then
          reaper.runloop(learnCC())
        elseif not gotParam then
          reaper.runloop(learnParam())  
        end
      else
        learningState = false
      end
    elseif #fxNames > 0 then
      inputEventIn = getInputEvent()
      for i = 1, #fxNames do
        if tonumber(tracks[i]) == -1 then
          trackIn = reaper.GetMasterTrack(0)
        else
          trackIn = reaper.GetTrack(0, tracks[i])
        end
        if inputEventIn[1] then
            setParam(inputEventIn, i, trackIn)
        end
        setLed(i, trackIn)
      end
    end
    if not learningState then
      if #fxNames < maxLearnCount then
        learningStateText = "Press Learn"
      else
        learningStateText = "Max CCs Learned"
      end
    end
    
    mappedCCsText = ""
    for i = 1, #fxNames do
      if tonumber(tracks[i]) == -1 then
        trackText = "Master"
      else 
        trackText = tracks[i] + 1
      end
      mappedCCsText = mappedCCsText.."CC "..
        ccs[i].." is mapped to track "..trackText..":\n"..fxNames[i].."\n\n"
    end
  
  else
    learningStateText = "Press Setup"
    mappedCCsText = ""
    learningState = false
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
    
    oldTouchedFx = {reaper.GetTouchedOrFocusedFX(0)}
    oldParam = {reaper.TrackFX_GetParam(
      getLastTrack(oldTouchedFx),
      oldTouchedFx[5],
      oldTouchedFx[6]
    )}
    
    reaper.ShowConsoleMsg("returning from learnCC()\n")
    return
  end
end

function learnParam() 
  learningStateText = "Learning Param"
  currentTouchedFx = {reaper.GetTouchedOrFocusedFX(0)}
  currentParam = {reaper.TrackFX_GetParam(
    getLastTrack(currentTouchedFx),
    currentTouchedFx[5], currentTouchedFx[6]
  )}
  
  if currentTouchedFx[1] and
  (currentTouchedFx[6] ~= oldTouchedFx[6] or
  currentParam[1] ~= oldParam[1]) then
    
    oldTouchedFx[6] = currentTouchedFx[6]
    oldParam[1] = currentParam[1]
    
    fxName = {reaper.TrackFX_GetFXName(
      getLastTrack(currentTouchedFx), 
      currentTouchedFx[5]
    )}
    paramName = {reaper.TrackFX_GetParamName(
      getLastTrack(currentTouchedFx), 
      currentTouchedFx[5],
      currentTouchedFx[6]
    )}
    table.insert(tracks, currentTouchedFx[2])
    table.insert(fxs, currentTouchedFx[5])
    table.insert(params, currentTouchedFx[6])
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

function setLed(i, trackOut) 
  paramInfo = {reaper.TrackFX_GetParam(
    trackOut, fxs[i], params[i]
  )}
  if paramInfo[1] == 0 then
    value = 0
  else 
    value = 127
  end
  reaper.StuffMIDIMessage(
    midiOutputId, 176 + midiChannel, ccs[i], value
  )
end

function setParam(inputEventOut, i, trackOut)
  if inputEventOut[2] == tonumber(ccs[i]) then
    if inputEventOut[3] == 0 then
      value = minValues[i]
    else
      value = maxValues[i]
    end
    reaper.TrackFX_SetParam(
      trackOut,
      fxs[i], params[i],  value
    )
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
  gfx.rect(
    setupBtnBounds[1],
    setupBtnBounds[2],
    setupBtnBounds[3],
    setupBtnBounds[4],
    false
  )
  --[[learnBtnBounds = {5, 5, 60, 20}
  quitBtnBounds = {335, 5, 60, 20}
  resetBtnBounds = {335, 30, 60, 20}
  outputIdBtnBounds = {265, 30, 60, 20}
  channelBtnBounds = {265, 5, 60, 20}]]
  gfx.x = 10
  gfx.y = 10
  gfx.drawstr("Learn")
  gfx.x = 345
  gfx.y = 10
  gfx.drawstr("Quit")
  gfx.x = 345
  gfx.y = 35
  gfx.drawstr("Reset")
  gfx.x = 280
  gfx.y = 10
  gfx.drawstr("Setup")
  
gfx.line(0, 55, 400, 55)

  local mouseState = gfx.mouse_cap & 1 == 1
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
    reaper.SetExtState(scriptName, "params", table.concat(params, ","), true)
    reaper.SetExtState(scriptName, "minValues", table.concat(minValues, ","), true)
    reaper.SetExtState(scriptName, "maxValues", table.concat(maxValues, ","), true)
    reaper.SetExtState(scriptName, "fxNames", table.concat(fxNames, ","), true)
    midiOutputId = ""
    midiChannel = ""
    reaper.DeleteExtState(scriptName, "midiOutputId", true)
    reaper.DeleteExtState(scriptName, "midiChannel", true)
    reaper.ClearConsole()
  end
  if mouseState and
  not lastMouseState and
  gfx.mouse_x > setupBtnBounds[1] and
  gfx.mouse_y > setupBtnBounds[2] and
  gfx.mouse_x < setupBtnBounds[3] + setupBtnBounds[1] and
  gfx.mouse_y < setupBtnBounds[4] + setupBtnBounds[2] then
  
  setupInput = {reaper.GetUserInputs(
    "Setup", 2, "MIDI Output Device ID,MIDI Device Channel", 
    reaper.GetExtState(scriptName,"midiOutputId")..","..
      reaper.GetExtState(scriptName, "midiChannel")
  )}
  if setupInput[1] then
    local result = {}
    for field in string.gmatch(setupInput[2]..",", '([^,]*),') do
      table.insert(result, field)
    end
    for i = 1, 2 do
      if i == 1 then 
        midiOutputId = result[i]
      else 
        midiChannel = result[i]
      end
    end
    reaper.SetExtState(scriptName, "midiOutputId", midiOutputId, true)
    reaper.SetExtState(scriptName, "midiChannel", midiChannel, true)
  end
  
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
