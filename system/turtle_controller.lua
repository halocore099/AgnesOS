-- Turtle controller for AgnesOS computer.
-- Discovers nearby turtle agents, displays status, and dispatches jobs.

local ui = require("system.ui")
local config = require("config")

local PROTOCOL = "AgnesOS"
local DISCOVER_TIMEOUT = 2
local modemName
local turtles = {}

local function findModem()
    local modem = peripheral.find("modem")
    if not modem then
        return nil, "No modem peripheral found."
    end
    local name = peripheral.getName(modem)
    return name
end

local function openRednet()
    local name, err = findModem()
    if not name then
        return nil, err
    end
    if not rednet.isOpen(name) then
        rednet.open(name)
    end
    return name
end

local function resetTurtles()
    turtles = {}
end

local function recordStatus(id, status)
    if type(status) ~= "table" or status.type ~= "turtle_status" then
        return
    end
    status.lastSeen = os.clock()
    status.id = id
    turtles[id] = status
end

local function discoverTurtles()
    resetTurtles()
    rednet.broadcast({ type = "discover_request", source = os.getComputerID() }, PROTOCOL)
    local deadline = os.clock() + DISCOVER_TIMEOUT
    while os.clock() < deadline do
        local sender, message = rednet.receive(PROTOCOL, deadline - os.clock())
        if sender and type(message) == "table" and message.type == "turtle_status" then
            recordStatus(sender, message)
        end
    end
end

local function requestStatus()
    rednet.broadcast({ type = "status_request", source = os.getComputerID() }, PROTOCOL)
    local deadline = os.clock() + DISCOVER_TIMEOUT
    while os.clock() < deadline do
        local sender, message = rednet.receive(PROTOCOL, deadline - os.clock())
        if sender and type(message) == "table" and message.type == "turtle_status" then
            recordStatus(sender, message)
        end
    end
end

local function formatStatus(status)
    local name = status.name or status.label or "turtle"
    local fuel = tostring(status.fuel or "?")
    local free = tostring(status.freeSlots or "?")
    local job = status.job or "idle"
    local progress = status.progress and (" " .. tostring(status.progress)) or ""
    return string.format("%s  fuel=%s free=%s job=%s%s", name, fuel, free, job, progress)
end

local function drawHeader()
    ui.clear()
    local w, h = ui.size()
    ui.centerText(config.NAME, 2, ui.theme.title)
    ui.centerText("Turtle Fleet Controller", 4, ui.theme.subtext)
    ui.centerText("Discover nearby turtles and send them strip mine jobs.", 6, ui.theme.subtext)
    ui.hr(8, ui.theme.border)
    return w, h
end

local function showTurtleStatus(w)
    local lines = { "Discovered turtles:" }
    for id, status in pairs(turtles) do
        table.insert(lines, formatStatus(status))
    end
    if #lines == 1 then
        table.insert(lines, "No turtles found yet.")
    end
    for i, line in ipairs(lines) do
        ui.centerText(line, 8 + i, ui.theme.text)
    end
end

local function readInput(prompt, default)
    local w, h = term.getSize()
    term.setCursorPos(1, h)
    term.setBackgroundColor(ui.theme.bg)
    term.setTextColor(ui.theme.text)
    term.clearLine()
    write(prompt)
    if default then
        write(" [" .. tostring(default) .. "]")
    end
    write(": ")
    local input = read()
    if input == "" and default then
        return tostring(default)
    end
    return input
end

local function parseSelection(input, orderedIDs)
    local selected = {}
    if input:lower() == "all" then
        for _, id in ipairs(orderedIDs) do
            table.insert(selected, id)
        end
        return selected
    end
    for token in string.gmatch(input, "[^,%s]+") do
        local index = tonumber(token)
        if index and orderedIDs[index] then
            table.insert(selected, orderedIDs[index])
        end
    end
    return selected
end

local function getOrderedIDs()
    local ids = {}
    for id in pairs(turtles) do
        table.insert(ids, id)
    end
    table.sort(ids)
    return ids
end

local function assignStripMine()
    if next(turtles) == nil then
        print("No turtles available. Refresh first.")
        sleep(1.5)
        return
    end

    local ids = getOrderedIDs()
    term.clear()
    term.setCursorPos(1, 1)
    print("Available turtles:")
    for index, id in ipairs(ids) do
        local status = turtles[id]
        print(string.format("%d) %s - fuel=%s free=%s job=%s", index, status.name or status.label or "turtle", tostring(status.fuel or "?"), tostring(status.freeSlots or "?"), status.job or "idle"))
    end
    print("")
    local selection = readInput("Select turtles by number, comma separated, or 'all'", "all")
    local targetIDs = parseSelection(selection, ids)
    if #targetIDs == 0 then
        print("No valid turtle selected.")
        sleep(1.5)
        return
    end

    local length = tonumber(readInput("Main tunnel length", 20)) or 20
    local branchInterval = tonumber(readInput("Branch spacing", 4)) or 4
    local branchLength = tonumber(readInput("Branch length", 4)) or 4

    local message = {
        type = "command",
        action = "stripmine",
        params = {
            length = length,
            branchInterval = branchInterval,
            branchLength = branchLength,
        },
    }

    for _, id in ipairs(targetIDs) do
        rednet.send(id, message, PROTOCOL)
    end

    print("")
    print("Sent strip mine command to " .. tostring(#targetIDs) .. " turtle(s).")
    print("Waiting for acknowledgements...")
    local deadline = os.clock() + 3
    while os.clock() < deadline do
        local sender, response = rednet.receive(PROTOCOL, deadline - os.clock())
        if sender and type(response) == "table" and response.type == "command_ack" then
            local status = turtles[sender]
            if status then
                status.job = response.job or status.job
            end
            print(string.format("- %s replied: %s", status and status.name or tostring(sender), response.result or "ok"))
        end
    end
    print("Press any key to continue...")
    os.pullEvent("key")
end

local function main()
    local modem, err = openRednet()
    if not modem then
        print(err)
        return
    end

    discoverTurtles()

    while true do
        local w, h = drawHeader()
        showTurtleStatus(w)
        local choice = ui.menu(math.floor(w / 2) - 12, h - 5, { "Refresh Turtles", "Assign Strip Mine", "Back" }, { width = 28 })
        if choice == 1 then
            requestStatus()
        elseif choice == 2 then
            assignStripMine()
        else
            break
        end
    end
end

main()
