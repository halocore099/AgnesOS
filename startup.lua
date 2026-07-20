-- AgnesOS Bootloader
-- Draws the flower logo, checks for updates, then launches AgnesOS.

local ui = require("system.ui")
local config = require("config")

ui.clear()

local w, h = ui.size()
local fw, fh = ui.flowerSize()
local flowerX = math.floor((w - fw) / 2) + 1
local flowerY = 2

-- Petal-by-petal reveal
for row = 1, fh do
    ui.drawFlower(flowerX, flowerY, row)
    sleep(0.05)
end
ui.drawStem(flowerX, flowerY, 2)

ui.centerText(config.NAME, flowerY + fh + 3, ui.theme.title)
ui.centerText("v" .. config.VERSION, flowerY + fh + 4, ui.theme.subtext)

sleep(0.4)

local statusY = flowerY + fh + 6
local dots = { "", ".", "..", "..." }
for i = 1, 8 do
    ui.writeAt(1, statusY, string.rep(" ", w))
    ui.centerText("Booting" .. dots[(i % 4) + 1], statusY, ui.theme.subtext)
    sleep(0.1)
end

if fs.exists("system/updater.lua") then
    ui.writeAt(1, statusY, string.rep(" ", w))
    ui.centerText("Checking for updates...", statusY, ui.theme.subtext)
    shell.run("system/updater")
else
    ui.writeAt(1, statusY, string.rep(" ", w))
    ui.centerText("Updater missing", statusY, ui.theme.warn)
    sleep(1)
end

sleep(0.3)
shell.run("AgnesOS")
