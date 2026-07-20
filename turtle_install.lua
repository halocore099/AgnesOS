-- Turtle install helper for AgnesOS.
-- Use this on a turtle to install the turtle agent and strip mine helper.

local repo = "https://raw.githubusercontent.com/halocore099/AgnesOS/main/"
local files = {
    "system/turtle_agent.lua",
    "system/stripmine.lua",
}

if not fs.exists("system") then
    fs.makeDir("system")
end

for _, file in ipairs(files) do
    print("Installing " .. file .. "...")
    local ok = shell.run("wget", repo .. file, file)
    if ok == false then
        print("Failed to download " .. file)
        return
    end
end

print("Turtle install complete!")
print("Run system/turtle_agent.lua on your turtle to connect it to AgnesOS.")
