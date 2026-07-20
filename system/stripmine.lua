-- Strip mine module for turtles.
-- Creates a simple main tunnel with side branches.

local stripmine = {}

local function isTurtle()
    return type(turtle) == "table" and turtle.forward ~= nil
end

local function clearLine(check, dig)
    while check() do
        if not dig() then
            return false
        end
        sleep(0.05)
    end
    return true
end

local function safeForward()
    while not turtle.forward() do
        if turtle.detect() then
            turtle.dig()
        else
            sleep(0.1)
        end
    end
    return true
end

local function safeUp()
    while not turtle.up() do
        if turtle.detectUp() then
            turtle.digUp()
        else
            sleep(0.1)
        end
    end
    return true
end

local function safeDown()
    while not turtle.down() do
        if turtle.detectDown() then
            turtle.digDown()
        else
            sleep(0.1)
        end
    end
    return true
end

local function step()
    clearLine(turtle.detect, turtle.dig)
    if not safeForward() then
        return false
    end
    clearLine(turtle.detectUp, turtle.digUp)
    clearLine(turtle.detectDown, turtle.digDown)
    return true
end

local function addBranches(branchLength, report)
    local function mineBranch(turnLeft)
        if turnLeft then
            turtle.turnLeft()
        else
            turtle.turnRight()
        end

        for i = 1, branchLength do
            if not step() then
                return false
            end
            if report then
                report({ event = "branch_progress", branch = i, total = branchLength })
            end
        end

        turtle.turnRight()
        turtle.turnRight()

        for i = 1, branchLength do
            if not step() then
                return false
            end
            if report then
                report({ event = "branch_progress", branch = branchLength + i, total = branchLength * 2 })
            end
        end

        if turnLeft then
            turtle.turnRight()
        else
            turtle.turnLeft()
        end
        return true
    end

    if not mineBranch(true) then
        return false
    end
    if not mineBranch(false) then
        return false
    end
    return true
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

local function estimateMine(length, branchInterval, branchLength)
    local branchCount = math.floor(length / branchInterval)
    local pathSteps = length + branchCount * branchLength * 2
    local blocks = pathSteps * 3
    return branchCount, pathSteps, blocks
end

local function checkFuel(required)
    if turtle.getFuelLevel then
        local fuel = turtle.getFuelLevel()
        if fuel ~= "unlimited" and fuel ~= math.huge and fuel < required then
            return false
        end
    end
    return true
end

local function checkInventory(requiredSlots)
    local freeSlots = countEmptySlots()
    if freeSlots < requiredSlots then
        return false
    end
    return true
end

local function run(params, report)
    if not isTurtle() then
        error("The strip mine routine must be run from a turtle.")
    end

    local length = params.length or 20
    local branchInterval = params.branchInterval or 4
    local branchLength = params.branchLength or 4

    local branchCount, pathSteps, totalBlocks = estimateMine(length, branchInterval, branchLength)
    local requiredFuel = pathSteps + 5
    local requiredSlots = math.min(12, math.ceil(totalBlocks / 4))

    if not checkFuel(requiredFuel) then
        error("Not enough fuel for requested strip mine.")
    end
    if not checkInventory(requiredSlots) then
        error("Not enough inventory space for requested strip mine.")
    end

    if report then
        report({ event = "start", length = length, branchInterval = branchInterval, branchLength = branchLength, branchCount = branchCount, totalBlocks = totalBlocks })
    end

    clearLine(turtle.detect, turtle.dig)
    clearLine(turtle.detectUp, turtle.digUp)
    clearLine(turtle.detectDown, turtle.digDown)

    for i = 1, length do
        if not step() then
            error("Stopped at block " .. i .. " due to obstruction.")
        end

        if i % branchInterval == 0 then
            if report then
                report({ event = "branch_start", block = i })
            end
            if not addBranches(branchLength, report) then
                error("Branching interrupted at block " .. i .. ".")
            end
        end

        if report then
            report({ event = "progress", step = i, total = length, percent = math.floor(i / length * 100) })
        end
    end

    if report then
        report({ event = "complete" })
    end
end

local stripmine = {
    run = run,
}

return stripmine
