loopCount = 0;
commandId = reaper.NamedCommandLookup("_RS0a2c9b10e87f8321f19ececd4fa699dab4a6b959");

gfx.init("ReaScript Loop Example LUA");

function run()
  loopCount = loopCount + 1;
  gfx.x = 1;
  gfx.y = 1;
  gfx.drawstr("Press \'q\' to exit...\n\n");
  gfx.printf("Loop Count:%d", loopCount);

  if gfx.getchar() ~= string.byte('q') then
    reaper.defer(run)
  end
  
end

function onExit()
  gfx.quit();
  reaper.ShowConsoleMsg("Exited Successfully!")
end

run()
reaper.atexit(onExit)
