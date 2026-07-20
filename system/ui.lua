-- AgnesOS UI Library
-- Shared pink theme: colors, layout helpers, the flower logo and a
-- simple selectable menu widget. Every screen (installer, bootloader,
-- main menu) pulls from this so the whole OS looks consistent.

local ui = {}

local isColor = term.isColor and term.isColor() or false
ui.isColor = isColor

-- ===== Theme =====
-- Falls back to grayscale automatically on non-Advanced computers,
-- since colors.pink/magenta just render as gray shades there.
ui.theme = {
    bg        = colors.black,
    panel     = colors.black,
    border    = isColor and colors.pink or colors.gray,
    title     = isColor and colors.magenta or colors.white,
    text      = colors.white,
    subtext   = colors.lightGray,
    petal     = isColor and colors.pink or colors.lightGray,
    petalSoft = isColor and colors.magenta or colors.gray,
    center    = isColor and colors.yellow or colors.white,
    stem      = isColor and colors.green or colors.gray,
    selectBg  = isColor and colors.pink or colors.white,
    selectFg  = isColor and colors.white or colors.black,
    ok        = isColor and colors.lime or colors.white,
    warn      = isColor and colors.yellow or colors.white,
}

-- ===== Basic helpers =====

function ui.size()
    local w, h = term.getSize()
    return w, h
end

function ui.clear(bg)
    term.setBackgroundColor(bg or ui.theme.bg)
    term.setTextColor(ui.theme.text)
    term.clear()
    term.setCursorPos(1, 1)
end

-- Write text horizontally centered on line y
function ui.centerText(text, y, fg, bg)
    local w = select(1, ui.size())
    local x = math.max(1, math.floor((w - #text) / 2) + 1)
    term.setBackgroundColor(bg or ui.theme.bg)
    term.setTextColor(fg or ui.theme.text)
    term.setCursorPos(x, y)
    term.write(text)
end

-- Write text left-aligned at a given x,y
function ui.writeAt(x, y, text, fg, bg)
    term.setBackgroundColor(bg or ui.theme.bg)
    term.setTextColor(fg or ui.theme.text)
    term.setCursorPos(x, y)
    term.write(text)
end

-- Thin rounded-ish box border using box drawing characters
function ui.box(x, y, w, h, color, bg)
    color = color or ui.theme.border
    bg = bg or ui.theme.bg
    term.setBackgroundColor(bg)
    term.setTextColor(color)

    term.setCursorPos(x, y)
    term.write("\151" .. string.rep("\140", w - 2) .. "\148") -- top corners+edge
    for row = 1, h - 2 do
        term.setCursorPos(x, y + row)
        term.write("\149")
        term.setCursorPos(x + w - 1, y + row)
        term.write("\149")
    end
    term.setCursorPos(x, y + h - 1)
    term.write("\138" .. string.rep("\140", w - 2) .. "\133")
end

-- Simple full-width horizontal rule
function ui.hr(y, color, bg)
    local w = select(1, ui.size())
    term.setBackgroundColor(bg or ui.theme.bg)
    term.setTextColor(color or ui.theme.border)
    term.setCursorPos(1, y)
    term.write(string.rep("\140", w))
end

-- Progress bar. percent is 0-1.
function ui.progressBar(x, y, w, percent, label)
    percent = math.max(0, math.min(1, percent))
    local filled = math.floor(w * percent)

    term.setCursorPos(x, y)
    term.setBackgroundColor(ui.theme.bg)
    term.setTextColor(ui.theme.border)
    term.write("[")

    term.setCursorPos(x + 1, y)
    term.setBackgroundColor(ui.theme.petal)
    term.write(string.rep(" ", filled))
    term.setBackgroundColor(ui.theme.bg)
    term.write(string.rep(" ", w - filled))

    term.setCursorPos(x + w + 1, y)
    term.setTextColor(ui.theme.border)
    term.write("]")

    if label then
        ui.centerText(label, y + 1, ui.theme.subtext)
    end
end

-- ===== The AgnesOS flower logo =====
-- A small pixel-art blossom, 7x7 cells. '.' = transparent (background
-- shows through), 'P' = petal, 'Y' = center.
local FLOWER = {
    "..PPP..",
    ".P...P.",
    "P..Y..P",
    ".YYYY.",
    "P..Y..P",
    ".P...P.",
    "..PPP..",
}

-- Draws the flower with its top-left pixel at (x, y).
-- growRows, if given, only draws that many rows (for a reveal animation).
function ui.drawFlower(x, y, growRows)
    local rows = growRows or #FLOWER
    for row = 1, rows do
        local line = FLOWER[row]
        for col = 1, #line do
            local ch = line:sub(col, col)
            local px, py = x + col - 1, y + row - 1
            if ch == "P" then
                paintutils.drawPixel(px, py, ui.theme.petal)
            elseif ch == "Y" then
                paintutils.drawPixel(px, py, ui.theme.center)
            end
        end
    end
end

function ui.flowerSize()
    return #FLOWER[1], #FLOWER
end

-- Little stem + leaves drawn below a flower placed at (x, y) [x,y is
-- the flower's top-left corner]. stemHeight in rows.
function ui.drawStem(x, y, stemHeight)
    local fw, fh = ui.flowerSize()
    local cx = x + math.floor(fw / 2)
    local top = y + fh
    for i = 0, stemHeight - 1 do
        paintutils.drawPixel(cx, top + i, ui.theme.stem)
    end
    if stemHeight >= 2 then
        paintutils.drawPixel(cx - 1, top + stemHeight - 1, ui.theme.stem)
        paintutils.drawPixel(cx + 1, top + 1, ui.theme.stem)
    end
end

function ui.drawTabs(x, y, tabs, selected, opts)
    opts = opts or {}
    local gap = opts.gap or 3
    local positions = {}
    local cursorX = x
    for i, tab in ipairs(tabs) do
        local label = " " .. tab .. " "
        positions[i] = { x = cursorX, width = #label }
        if i == selected then
            term.setBackgroundColor(ui.theme.selectBg)
            term.setTextColor(ui.theme.selectFg)
        else
            term.setBackgroundColor(ui.theme.bg)
            term.setTextColor(ui.theme.subtext)
        end
        term.setCursorPos(cursorX, y)
        term.write(label)
        cursorX = cursorX + #label + gap
    end
    term.setBackgroundColor(ui.theme.bg)
    return positions
end

-- ===== Menu widget =====
-- items: list of strings. Returns the 1-based index chosen.
-- Supports Up/Down + Enter, and number-key shortcuts 1-9.
function ui.menu(x, y, items, opts)
    opts = opts or {}
    local w = opts.width or 0
    local labels = {}
    for i, item in ipairs(items) do
        labels[i] = tostring(i) .. ". " .. item
        w = math.max(w, #labels[i] + 4)
    end
    w = math.max(w, opts.minWidth or 22)
    local selected = 1

    local function draw()
        for i, label in ipairs(labels) do
            local rowY = y + (i - 1)
            if i == selected then
                term.setBackgroundColor(ui.theme.selectBg)
                term.setTextColor(ui.theme.selectFg)
                term.setCursorPos(x, rowY)
                term.write(" > " .. label .. string.rep(" ", w - #label - 3))
            else
                term.setBackgroundColor(ui.theme.bg)
                term.setTextColor(ui.theme.text)
                term.setCursorPos(x, rowY)
                term.write("   " .. label .. string.rep(" ", w - #label - 3))
            end
        end
        term.setBackgroundColor(ui.theme.bg)
    end

    draw()
    while true do
        local event, p1, p2, p3 = os.pullEvent()
        if event == "key" then
            if p1 == keys.up then
                selected = selected - 1
                if selected < 1 then selected = #items end
                draw()
            elseif p1 == keys.down then
                selected = selected + 1
                if selected > #items then selected = 1 end
                draw()
            elseif p1 == keys.enter or p1 == keys.numPadEnter then
                return selected
            elseif p1 >= keys.one and p1 <= keys.nine then
                local n = p1 - keys.one + 1
                if items[n] then return n end
            end
        elseif event == "char" then
            local n = tonumber(p1)
            if n and items[n] then return n end
        elseif event == "mouse_click" then
            local button, mx, my = p1, p2, p3
            if button == 1 and mx >= x and mx <= x + w - 1 and my >= y and my < y + #items then
                selected = my - y + 1
                draw()
                return selected
            end
        end
    end
end

return ui
