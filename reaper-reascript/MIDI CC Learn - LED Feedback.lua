--[[
  WORK IN PROGRESS
]]

reaper.ClearConsole()
scriptName = "MIDI CC Learn - LED Feedback"
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
  
values = {
  [1] = {}, -- tracks
  [2] = {}, -- ccs
  [3] = {}, -- fxs
  [4] = {}, -- params
  [5] = {}, -- minValues
  [6] = {}, -- maxValues
  [7] = {} -- fxNames
}
if reaper.HasExtState(scriptName, "values") then
  for i = 1, #values do
     for j in string.gmatch(reaper.GetExtState(scriptName, "values"..i), "[^,]+") do
       table.insert(values[i], j)
     end
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
      if #values[7] < maxLearnCount then
        if not gotCC then
          reaper.runloop(learnCC())
        elseif not gotParam then
          reaper.runloop(learnParam())  
        end
      else
        learningState = false
      end
    elseif #values[7] > 0 then
      inputEventIn = getInputEvent()
      if reaper.CountTracks(0) > 0 then
        for i = 1, #values[7] do
          if tonumber(values[1][i]) == -1 then
            trackIn = reaper.GetMasterTrack(0)
          else
            trackIn = reaper.GetTrack(0, values[1][i])
          end
          if inputEventIn[1] then
              setParam(inputEventIn, i, trackIn)
          end
          setLed(i, trackIn)
        end
      
      else
        for i = 1, #values[7] do
          if inputEventIn[1] then
            setParam(inputEventIn, i, reaper.GetMasterTrack(0))
          end
          setLed(i, reaper.GetMasterTrack(0))
        end
      end
    end
    if not learningState then
      if #values[7] < maxLearnCount then
        learningStateText = "Press Learn"
      else
        learningStateText = "Max CCs Learned"
      end
    end
    
    mappedCCsText = ""
    for i = 1, #values[7] do
      if tonumber(values[1]) == -1 then
        trackText = "Master"
      else 
        trackText = values[1][i] + 1
      end

      mappedCCsText = mappedCCsText.."CC "..
        values[2][i].." is mapped to track "..trackText..":\n"..values[7][i].."\n\n"
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
    table.insert(values[2], inputEvent[2])
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
    
    table.insert(values[1], currentTouchedFx[2])
    table.insert(values[3], currentTouchedFx[5])
    table.insert(values[4], currentTouchedFx[6])
    table.insert(values[5], currentParam[2])
    table.insert(values[6], currentParam[3])
    table.insert(values[7], fxName[2]..": "..paramName[2])
    
    for i = 1, #values do
      reaper.SetExtState(scriptName, "values"..i, table.concat(values[i], ","), true)
    end
    
    if learningState then
      gotParam = true
      gotCC = false
    end
    return
  end
end

function setLed(i, trackOut) 
  paramInfo = {reaper.TrackFX_GetParam(
    trackOut, values[3][i], values[4][i]
  )}
  if paramInfo[1] == 0 then
    value = 0
  else 
    value = 127
  end
  reaper.StuffMIDIMessage(
    midiOutputId + 16, 176 + midiChannel - 1, values[2][i], value
  )
end

function setParam(inputEventOut, i, trackOut)
  if inputEventOut[2] == tonumber(values[2][i]) then
    if inputEventOut[3] == 0 then
      value = values[5][i]
    else
      value = values[6][i]
    end
    reaper.TrackFX_SetParam(
      trackOut,
      values[3][i], values[4][i],  value
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
   reset()   
  end
  if mouseState and
  not lastMouseState and
  gfx.mouse_x > setupBtnBounds[1] and
  gfx.mouse_y > setupBtnBounds[2] and
  gfx.mouse_x < setupBtnBounds[3] + setupBtnBounds[1] and
  gfx.mouse_y < setupBtnBounds[4] + setupBtnBounds[2] then
  
    setupInput = {reaper.GetUserInputs(
      "Setup", 2, "MIDI Output Device ID,MIDI Device Channel", 
      reaper.GetExtState(scriptName, "midiOutputId")..","..
        reaper.GetExtState(scriptName, "midiChannel")
    )}
    if setupInput[1] then
      local inputValues = {}
      for value in string.gmatch(setupInput[2]..",", '([^,]*),') do
        table.insert(inputValues, value)
      end
      for i = 1, 2 do
        if i == 1 then 
          if inputValues[i] == "" or tonumber(inputValues[i]) == nil then
            midiOutputId = ""
          else
            midiOutputId = tonumber(inputValues[i])
          end
        else 
          if inputValues[i] == "" or tonumber(inputValues[i]) == nil then
            midiChannel = ""
          else 
            midiChannel = tonumber(inputValues[i])
          end
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

function reset()
  learningState = false
  values = {
    [1] = {}, -- tracks
    [2] = {}, -- ccs
    [3] = {}, -- fxs
    [4] = {}, -- params
    [5] = {}, -- minValues
    [6] = {}, -- maxValues
    [7] = {} -- fxNames
  }
  for i = 1, #values do
    reaper.DeleteExtState(scriptName, "values"..i, true)
  end
  midiOutputId = ""
  midiChannel = ""
  reaper.DeleteExtState(scriptName, "midiOutputId", true)
  reaper.DeleteExtState(scriptName, "midiChannel", true)
  reaper.ClearConsole()
end

function onExit()
  gfx.quit()
end

main()
reaper.atexit(onExit)
