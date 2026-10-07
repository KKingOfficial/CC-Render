-- Usage:  view grounded_color.bimg      (or grounded_lines.bimg)
-- Needs a 4x3 monitor (any side). Draws the image using teletext characters.
local path = ... or "grounded_color.bimg"

local mon = peripheral.find("monitor")
assert(mon, "No monitor found")
mon.setTextScale(0.5)

local h = fs.open(path, "r")
assert(h, "Can't open " .. path)
local img = textutils.unserialize(h.readAll())
h.close()
assert(img, "File failed to parse")

-- load the 16-colour palette (index 0..15 -> colors.white, orange, ... black)
for i = 0, 15 do
  mon.setPaletteColor(2 ^ i, img.palette[i])
end

local frame = img[1]
local mw, mh = mon.getSize()
local iw = #frame[1][1]
local xoff = math.max(0, math.floor((mw - iw) / 2))
local yoff = math.max(0, math.floor((mh - #frame) / 2))

mon.setBackgroundColor(colors.black)
mon.clear()
for y, row in ipairs(frame) do
  mon.setCursorPos(1 + xoff, y + yoff)
  mon.blit(row[1], row[2], row[3])
end
