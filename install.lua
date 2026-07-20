-- AgnesOS Installer
-- Self-contained on purpose: this runs before any AgnesOS files exist
-- on disk, so it can't require() the shared system/ui.lua library yet.
-- It draws its own small pink flower + progress bar, then downloads
-- everything (including system/ui.lua) for the OS to use afterwards.

local repo = "https://raw.githubusercontent.com/halocore099/AgnesOS/main/"

local isColor = term.isColor and term.isColor() or false
local petalColor = isColor and colors.pink or colors.lightGray
local centerColor = isColor and colors.yellow or colors.white
local titleColor = isColor and colors.magenta or colors.white
local subColor = colors.lightGray
local barColor = petalColor

local FLOWER = {
    "..PPPPP..",
    ".PP...PP.",
    "PP.....PP",
    "P..YYY..P",
    "PP.YYY.PP",
    "P..YYY..P",
    "PP.....PP",
    ".PP...PP.",
    "..PPPPP..",
}

local function drawFlower(x, y)
    for row = 1, #FLOWER do
        local line = FLOWER[row]
        for col = 1, #line do
            local ch = line:sub(col, col)
            if ch == "P" then
                paintutils.drawPixel(x + col - 1, y + row - 1, petalColor)
            elseif ch == "Y" then
                paintutils.drawPixel(x + col - 1, y + row - 1, centerColor)
            end
        end
    end
end

local function centerText(text, y, color)
    local w = select(1, term.getSize())
    local x = math.max(1, math.floor((w - #text) / 2) + 1)
    term.setTextColor(color or colors.white)
    term.setCursorPos(x, y)
    term.write(text)
end

local function progressBar(x, y, w, percent)
    percent = math.max(0, math.min(1, percent))
    local filled = math.floor(w * percent)
    term.setTextColor(isColor and colors.pink or colors.white)
    term.setCursorPos(x, y)
    term.write("[")
    term.setCursorPos(x + 1, y)
    term.setBackgroundColor(barColor)
    term.write(string.rep(" ", filled))
    term.setBackgroundColor(colors.black)
    term.write(string.rep(" ", w - filled))
    term.setCursorPos(x + w + 1, y)
    term.write("]")
end

term.setBackgroundColor(colors.black)
term.clear()

local w, h = term.getSize()
local flowerX = math.floor((w - 9) / 2) + 1
local flowerY = 2
drawFlower(flowerX, flowerY)

term.setBackgroundColor(colors.black)
centerText("AgnesOS Installer", flowerY + 11, titleColor)
centerText("made with love for Agnes", flowerY + 12, subColor)
sleep(0.5)

local files = {
    "startup.lua",
    "AgnesOS.lua",
    "config.lua",
    "version.txt",
    "system/ui.lua",
    "system/updater.lua",
}

if not fs.exists("system") then
    fs.makeDir("system")
end

local listY = flowerY + 14
local barY = h - 2

for i, file in ipairs(files) do
    term.setBackgroundColor(colors.black)
    term.setCursorPos(1, listY)
    term.write(string.rep(" ", w))
    term.setCursorPos(1, listY)
    term.setTextColor(colors.white)
    term.write("Installing " .. file .. " ...")

    -- wget prints its own status lines, which would clash with our
    -- layout, so run it against a hidden off-screen window instead.
    local ok = true
    if window and term.redirect then
        local oldTerm = term.current()
        local hidden = window.create(oldTerm, 1, 1, w, h, false)
        term.redirect(hidden)
        ok = shell.run("wget", repo .. file, file)
        term.redirect(oldTerm)
    else
        ok = shell.run("wget", repo .. file, file)
    end

    progressBar(math.floor((w - 30) / 2), barY, 30, i / #files)

    term.setCursorPos(1, listY)
    term.write(string.rep(" ", w))
    term.setCursorPos(1, listY)
    if ok == false then
        term.setTextColor(colors.red)
        term.write("Failed: " .. file)
        sleep(1)
    else
        term.setTextColor(isColor and colors.lime or colors.white)
        term.write("OK  " .. file)
    end
end

term.setBackgroundColor(colors.black)
centerText("Installation complete!", barY + 2, isColor and colors.lime or colors.white)
sleep(2)

os.reboot()
