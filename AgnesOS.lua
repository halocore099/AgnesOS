-- AgnesOS main menu

local config = require("config")
local ui = require("system.ui")

local function drawHeader()
    ui.clear()
    local w, h = ui.size()
    local fw, fh = ui.flowerSize()
    local flowerX = math.floor((w - fw) / 2) + 1
    local flowerY = 1

    ui.drawFlower(flowerX, flowerY)
    ui.centerText(config.NAME, flowerY + fh + 1, ui.theme.title)
    ui.centerText("v" .. config.VERSION .. " • " .. config.OWNER, flowerY + fh + 2, ui.theme.subtext)
    ui.hr(flowerY + fh + 4, ui.theme.border)
    return w, h, flowerY + fh + 4
end

local function screen(title, body)
    local w, h, sectionY = drawHeader()
    local topY = sectionY + 2
    ui.centerText(title, topY, ui.theme.title)
    for i, line in ipairs(body) do
        ui.centerText(line, topY + i, ui.theme.text)
    end
    ui.centerText("Press any key to return...", h - 1, ui.theme.subtext)
    os.pullEvent("key")
end

local function mining()
    local w, _, sectionY = drawHeader()
    ui.centerText("Choose a mining routine:", sectionY + 1, ui.theme.subtext)
    local choice = ui.menu(math.floor(w / 2) - 10, sectionY + 3, { "Strip Mine", "Back" })
    if choice == 1 then
        shell.run("system/stripmine")
    end
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
    local w, h, sectionY = drawHeader()
    ui.centerText("Use arrows, numbers, or click to choose.", sectionY + 1, ui.theme.subtext)
    local menuY = sectionY + 3
    local choice = ui.menu(math.floor(w / 2) - 10, menuY, items)
    actions[choice]()
end
