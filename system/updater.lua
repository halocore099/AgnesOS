local config = require("config")

local function getRemoteVersion()
    local url = config.UPDATE_URL .. "version.txt"
    local response = http.get(url)
    if not response then
        return nil
    end
    local version = response.readAll()
    response.close()
    return version
end

local function updateFile(file)
    print("Updating " .. file)
    local url = config.UPDATE_URL .. file
    shell.run("wget", url, file)
end

print("Checking updates...")

local remote = getRemoteVersion()

if not remote then
    print("Offline mode")
    return
end

if remote ~= config.VERSION then
    print("")
    print("Update found!")
    print(config.VERSION .. " -> " .. remote)

    sleep(2)

    updateFile("AgnesOS.lua")
    updateFile("config.lua")
    updateFile("version.txt")
    updateFile("startup.lua")
    updateFile("system/ui.lua")
    updateFile("system/stripmine.lua")
    updateFile("system/turtle_agent.lua")
    updateFile("system/turtle_controller.lua")
    updateFile("turtle_install.lua")

    print("")
    print("Updated!")
else
    print("AgnesOS is up to date")
end

sleep(1)
