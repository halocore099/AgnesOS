-- AgnesOS main menu

local config = require("config")
local ui = require("system.ui")

local tabs = { "Mining", "Utilities", "Settings", "Shutdown" }

local function drawHeader(activeTab)
    ui.clear()
    local w, h = ui.size()
    local fw, fh = ui.flowerSize()
    local flowerX = math.floor((w - fw) / 2) + 1
    local flowerY = 1

    ui.drawFlower(flowerX, flowerY)
    ui.centerText(config.NAME, flowerY + fh + 1, ui.theme.title)
    ui.centerText("v" .. config.VERSION .. " • " .. config.OWNER, flowerY + fh + 2, ui.theme.subtext)

    local sectionY = flowerY + fh + 3
    if activeTab then
        local totalWidth = 0
        for _, tab in ipairs(tabs) do
            totalWidth = totalWidth + #tab + 2 + 3
        end
        totalWidth = totalWidth - 3
        local tabX = math.floor((w - totalWidth) / 2) + 1
        ui.drawTabs(tabX, sectionY, tabs, activeTab)
        sectionY = sectionY + 2
    end

    ui.hr(sectionY, ui.theme.border)
    return w, h, sectionY
end

local function screen(title, body, activeTab)
    local w, h, sectionY = drawHeader(activeTab)
    local topY = sectionY + 2
    ui.centerText(title, topY, ui.theme.title)
    for i, line in ipairs(body) do
        ui.centerText(line, topY + i, ui.theme.text)
    end
    ui.centerText("Press any key to return...", h - 1, ui.theme.subtext)
    os.pullEvent("key")
end

local function miningInfo()
    screen("Mining Info", {
        "Strip mine is designed for turtles.",
        "It needs enough fuel, empty inventory space",
        "and an available turtle to run the routine.",
        "Use the Strip Mine option to configure the exact tunnel",
        "length, branch spacing, and assigned turtle count.",
    }, 1)
end

local function mining()
    local w, _, sectionY = drawHeader(1)
    ui.centerText("Choose a mining routine:", sectionY + 1, ui.theme.subtext)
    local choice = ui.menu(math.floor(w / 2) - 13, sectionY + 3, { "Strip Mine", "Info", "Back" }, { width = 32 })
    if choice == 1 then
        shell.run("system/stripmine")
    elseif choice == 2 then
        miningInfo()
    end
end

local function utilities()
    screen("Utilities", { "Utilities", "Coming soon" }, 2)
end

local function settings()
    screen("AgnesOS Settings", {
        "Version: " .. config.VERSION,
        "Owner:   " .. config.OWNER,
        ui.isColor and "Display: Color" or "Display: Basic (grayscale)",
    }, 3)
end

local function shutdown()
    local w, h, sectionY = drawHeader(4)
    ui.centerText("Shutting down...", sectionY + 2, ui.theme.text)
    sleep(1)
    os.shutdown()
end

local items = { "Mining", "Utilities", "Settings", "Shutdown" }
local actions = { mining, utilities, settings, shutdown }

while true do
    local w, h, sectionY = drawHeader()
    ui.centerText("Use arrows, numbers, or click to choose.", sectionY + 1, ui.theme.subtext)
    local menuY = sectionY + 3
    local choice = ui.menu(math.floor(w / 2) - 13, menuY, items, { width = 30 })
    actions[choice]()
end
