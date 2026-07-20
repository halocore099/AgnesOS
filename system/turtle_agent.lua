-- Turtle agent for AgnesOS.
-- Listens for controller commands over rednet and executes turtle jobs.

local function loadLocalModule(filename)
    local running = shell.getRunningProgram() or "system/turtle_agent.lua"
    local dir = running:match("^(.*)/") or ""
    local path = shell.resolve(dir .. "/" .. filename)
    if not fs.exists(path) then
        error("Missing local module: " .. path)
    end
    return dofile(path)
end

local stripmine = loadLocalModule("stripmine.lua")

local PROTOCOL = "AgnesOS"
local modemName
local currentJob = nil

local function findModem()
    local modem = peripheral.find("modem")
    if not modem then
        return nil, "No modem peripheral found."
    end
    return peripheral.getName(modem)
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

local function countEmptySlots()
    local free = 0
    for slot = 1, 16 do
        if turtle.getItemCount(slot) == 0 then
            free = free + 1
        end
    end
    return free
end

local function buildStatus()
    return {
        type = "turtle_status",
        name = os.getComputerLabel() or "turtle",
        label = os.getComputerLabel(),
        id = os.getComputerID(),
        fuel = turtle.getFuelLevel(),
        freeSlots = countEmptySlots(),
        job = currentJob and currentJob.status or "idle",
        progress = currentJob and currentJob.progress,
        message = currentJob and currentJob.message,
    }
end

local function sendStatus(recipient)
    local status = buildStatus()
    if recipient then
        rednet.send(recipient, status, PROTOCOL)
    else
        rednet.broadcast(status, PROTOCOL)
    end
end

local function sendAck(recipient, result, job)
    rednet.send(recipient, { type = "command_ack", result = result or "ok", job = job }, PROTOCOL)
end

local function setJobState(status, progress, message)
    currentJob = currentJob or {}
    currentJob.status = status
    currentJob.progress = progress
    currentJob.message = message
end

local function updateProgress(progress, message)
    if currentJob then
        currentJob.progress = progress
        currentJob.message = message
    end
end

local function reportLoop(controller)
    if controller then
        sendStatus(controller)
    end
end

local function runStripMine(controller, params)
    setJobState("running", "0%", "starting")
    sendAck(controller, "accepted", "stripmine")
    local ok, err = pcall(function()
        stripmine.run(params, function(update)
            if type(update) == "table" then
                if update.event == "progress" then
                    updateProgress(update.percent or string.format("%d/%d", update.step or 0, update.total or 0), update.message)
                else
                    updateProgress(update.event, update.message)
                end
                sendStatus(controller)
            end
        end)
    end)
    if not ok then
        setJobState("error", nil, tostring(err))
        rednet.send(controller, { type = "command_ack", result = "error", error = tostring(err) }, PROTOCOL)
    else
        setJobState("idle", nil, "completed")
        sendStatus(controller)
        rednet.send(controller, { type = "command_ack", result = "complete", job = "stripmine" }, PROTOCOL)
    end
end

local function handleMessage(sender, message)
    if type(message) ~= "table" or not message.type then
        return
    end

    if message.type == "discover_request" or message.type == "status_request" then
        sendStatus(sender)
        return
    end

    if message.type == "command" then
        if message.action == "stripmine" then
            if currentJob and currentJob.status == "running" then
                rednet.send(sender, { type = "command_ack", result = "busy", job = "stripmine" }, PROTOCOL)
                return
            end
            currentJob = { status = "starting" }
            runStripMine(sender, message.params or {})
            return
        end
    end
end

local function main()
    local modem, err = openRednet()
    if not modem then
        print(err)
        return
    end

    print("AgnesOS Turtle Agent running on modem " .. modem)
    sendStatus()

    while true do
        local sender, message = rednet.receive(PROTOCOL)
        handleMessage(sender, message)
    end
end

main()
