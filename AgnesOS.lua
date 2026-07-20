-- AgnesOS main menu

local config = require("config")
local ui = require("system.ui")

local function drawHeader()
    ui.clear()
    local w, h = ui.size()
    local fw = select(1, ui.flowerSize())
    local flowerX = 3
    local flowerY = 1
    ui.drawFlower(flowerX, flowerY)

    ui.writeAt(flowerX + fw + 2, flowerY + 2, config.NAME, ui.theme.title)
    ui.writeAt(flowerX + fw + 2, flowerY + 3, "v" .. config.VERSION, ui.theme.subtext)
    ui.writeAt(flowerX + fw + 2, flowerY + 4, "for " .. config.OWNER, ui.theme.subtext)

    ui.hr(flowerY + select(2, ui.flowerSize()) + 1, ui.theme.border)
    return w, h
end

local function screen(title, body)
    local w, h = drawHeader()
    local topY = 12
    ui.centerText(title, topY, ui.theme.title)
    for i, line in ipairs(body) do
        ui.centerText(line, topY + 1 + i, ui.theme.text)
    end
    ui.centerText("Press any key to return...", h - 1, ui.theme.subtext)
    os.pullEvent("key")
end

local function mining()
    screen("Mining", { "Mining system", "Coming soon" })
end

local function utilities()
    screen("Utilities", { "Utilities", "Coming soon" })
end

local function settings()
    screen("AgnesOS Settings", {
        "Version: " .. config.VERSION,
        "Owner:   " .. config.OWNER,
        ui.isColor and "Display: Color" or "Display: Basic (grayscale)",
    })
end

local function shutdown()
    local w, h = drawHeader()
    ui.centerText("Shutting down...", 12, ui.theme.text)
    sleep(1)
    os.shutdown()
end

local items = { "Mining", "Utilities", "Settings", "Shutdown" }
local actions = { mining, utilities, settings, shutdown }

while true do
    local w, h = drawHeader()
    local menuY = 12
    local choice = ui.menu(math.floor(w / 2) - 8, menuY, items)
    actions[choice]()
end
