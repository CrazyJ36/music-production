reaper.ClearConsole()
function run()
  is_new,name,sec,cmd,rel,res,val = reaper.get_action_context()
  if is_new then
    reaper.ShowConsoleMsg(name.."\nrel: ".. rel.."\nres: "..res.."\nval = "..val.."\n")
  end
  reaper.defer(run)
end

function onexit()
  reaper.ShowConsoleMsg("Exited?\n")
end

run()
reaper.atexit(onexit)
