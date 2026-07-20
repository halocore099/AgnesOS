-- Strip mine script for turtles.
-- Creates a simple main tunnel with side branches.

local ui = require("system.ui")

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

local function addBranches(branchLength)
    local function mineBranch(turnLeft)
        if turnLeft then
            turtle.turnLeft()
        else
            turtle.turnRight()
        end

        for _ = 1, branchLength do
            if not step() then
                return false
            end
        end

        turtle.turnRight()
        turtle.turnRight()

        for _ = 1, branchLength do
            if not step() then
                return false
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

local function readNumber(prompt, default)
    while true do
        term.write(prompt)
        if default then
            term.write(" [" .. tostring(default) .. "]")
        end
        term.write(": ")
        local input = read()
        if input == "" and default then
            return default
        end
        local value = tonumber(input)
        if value and value >= 1 then
            return math.floor(value)
        end
        print("Please enter a positive integer.")
    end
end

local function confirm(prompt)
    term.write(prompt .. " (Y/n): ")
    local input = read()
    input = input:lower()
    return input == "" or input:sub(1, 1) == "y"
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

local function showHeader()
    ui.clear()
    ui.centerText("Strip Mine", 2, ui.theme.title)
    ui.centerText("Simple turtle strip mining routine.", 4, ui.theme.subtext)
    ui.centerText("Enter your tunnel settings below.", 5, ui.theme.subtext)
end

local function checkFuel(required)
    if turtle.getFuelLevel then
        local fuel = turtle.getFuelLevel()
        if fuel ~= "unlimited" and fuel ~= math.huge and fuel < required then
            print("Warning: fuel level is " .. tostring(fuel) .. ", estimated needed " .. tostring(required) .. ".")
            if not confirm("Refuel and continue?") then
                return false
            end
        end
    end
    return true
end

local function checkInventory(requiredSlots)
    local freeSlots = countEmptySlots()
    if freeSlots < requiredSlots then
        print("Warning: only " .. freeSlots .. " empty inventory slots available.")
        print("This strip mine may fill inventory quickly.")
        if not confirm("Continue anyway?") then
            return false
        end
    end
    return true
end

local function showSummary(length, branchInterval, branchLength, turtles)
    local branchCount, pathSteps, totalBlocks = estimateMine(length, branchInterval, branchLength)
    local perTurtle = math.max(1, math.ceil(totalBlocks / turtles))

    ui.clear()
    ui.centerText("Strip Mine Summary", 2, ui.theme.title)
    ui.centerText("Main tunnel length: " .. length .. " blocks", 4, ui.theme.subtext)
    ui.centerText("Branch every " .. branchInterval .. " blocks", 5, ui.theme.subtext)
    ui.centerText("Branch length: " .. branchLength .. " blocks", 6, ui.theme.subtext)
    ui.centerText("Assigned turtles: " .. turtles, 7, ui.theme.subtext)
    ui.centerText("Estimated branch points: " .. branchCount, 8, ui.theme.subtext)
    ui.centerText("Estimated mining steps: " .. pathSteps, 9, ui.theme.subtext)
    ui.centerText("Estimated blocks mined: " .. totalBlocks, 10, ui.theme.subtext)
    ui.centerText("Estimated blocks per turtle: " .. perTurtle, 11, ui.theme.subtext)
    ui.centerText("Press any key to continue...", 13, ui.theme.subtext)
    os.pullEvent("key")
end

local function main()
    if not isTurtle() then
        error("The strip mine routine must be run from a turtle.")
    end

    showHeader()
    local length = readNumber("Main tunnel length", 20)
    local branchInterval = readNumber("Branch spacing", 4)
    local branchLength = readNumber("Branch length", 4)
    local turtleCount = readNumber("Turtles assigned", 1)

    if turtleCount > 1 then
        print("Note: this script is run from one turtle instance.")
        print("Assigned turtle count is used for planning only.")
        if not confirm("Continue with this plan?") then
            return
        end
    end

    local branchCount, pathSteps, totalBlocks = estimateMine(length, branchInterval, branchLength)
    local requiredFuel = pathSteps + 5
    local requiredSlots = math.min(12, math.ceil(totalBlocks / 4))

    if not checkFuel(requiredFuel) then
        return
    end
    if not checkInventory(requiredSlots) then
        return
    end

    showSummary(length, branchInterval, branchLength, turtleCount)

    print("")
    print("Starting strip mine...")
    print("Main tunnel: " .. length .. " blocks")
    print("Branch every " .. branchInterval .. " blocks, " .. branchLength .. " blocks deep")
    print("Estimated steps: " .. pathSteps)
    print("Estimated blocks mined: " .. totalBlocks)
    print("")
    print("Press Enter to begin.")
    read()

    clearLine(turtle.detect, turtle.dig)
    clearLine(turtle.detectUp, turtle.digUp)
    clearLine(turtle.detectDown, turtle.digDown)

    for i = 1, length do
        if not step() then
            print("Stopped at block " .. i .. ".")
            return
        end

        if i % branchInterval == 0 then
            print("Branching at block " .. i .. "...")
            if not addBranches(branchLength) then
                print("Branching interrupted at block " .. i .. ".")
                return
            end
        end
    end

    print("Strip mine complete. Main tunnel finished.")
    print("Return to the entrance or continue mining manually.")
end

main()
