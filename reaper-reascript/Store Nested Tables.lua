reaper.ClearConsole()
scriptName = "Store Nested Table"

values = {
  [1] = {"value 1 entry1", "value 1 entry2"},
  [2] = {"value 2 entry"},
  [3] = {"value 3 entry"}
}

for i = 1, #values do
  storedTable = reaper.GetExtState(scriptName, "storedTable"..i)
  reaper.ShowConsoleMsg("storedTable "..i..": "..storedTable.."\n")
end

for index, value in ipairs(values) do
  reaper.ShowConsoleMsg("index: "..index..":\n")
  for i = 1, #value do
    reaper.ShowConsoleMsg("value: "..value[i].."\n")

  end
end

for i = 1, #values do
  reaper.SetExtState(scriptName, "storedTable"..i, table.concat(values[i], ","), false)
end
