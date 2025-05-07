loopCount = 0;
commandId = reaper.NamedCommandLookup("_RS0a2c9b10e87f8321f19ececd4fa699dab4a6b959");

gfx.init("ReaScript Loop Example");

char = gfx.getchar()

function run()
  if gfx.getchar() > 0 then
    return
  end

  loopCount = loopCount + 1;
  gfx.x = 1;
  gfx.printf("Loop Count:%d", loopCount);
  reaper.defer(run);
end

function onExit()
  gfx.quit();
  reaper.ShowConsoleMsg("Exited Successfully!")
end

reaper.defer(run)
reaper.atexit(onExit);
