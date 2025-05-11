--[[
  An example GUI Toggle and Exit Buttons
]]

gfx.init("Toggle", 200, 200)

btnToggleBounds = {5, 5, 40, 20}
btnExitBounds = {150, 5, 40, 20}
btnToggleState = false

function main()
  
  mouseState = gfx.mouse_cap & 1 == 1
  
  if mouseState and 
    not lastMouseState and
    gfx.mouse_x > btnToggleBounds[1] and
    gfx.mouse_x < btnToggleBounds[3] + btnToggleBounds[1] and
    gfx.mouse_y > btnToggleBounds[2] and
    gfx.mouse_y < btnToggleBounds[4] + btnToggleBounds[2] then
      btnToggleState = not btnToggleState
  elseif mouseState and
    not lastMouseState and
    gfx.mouse_x > btnExitBounds[1] and
    gfx.mouse_x < btnExitBounds[3] + btnExitBounds[1] and
    gfx.mouse_y > btnExitBounds[2] and
    gfx.mouse_y < btnExitBounds[4] + btnExitBounds[2] then
      return
  end
  lastMouseState = mouseState
  
  gfx.rect(
    btnToggleBounds[1],
    btnToggleBounds[2],
    btnToggleBounds[3],
    btnToggleBounds[4],
    btnToggleState
  )
  gfx.x = 5
  gfx.y = 5
  gfx.drawstr("Tgl")
  
  gfx.rect(
    btnExitBounds[1],
    btnExitBounds[2],
    btnExitBounds[3],
    btnExitBounds[4],
    false
  )
  gfx.x = 150
  gfx.y = 5
  gfx.drawstr("Exit")
  
  reaper.defer(main)
end

main()
function atExit()
  gfx.quit()
  reaper.ShowConsoleMsg("Killed Action Successfully.\n")
end
reaper.atexit(atExit)





 



