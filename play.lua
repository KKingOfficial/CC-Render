-- Usage:  play grounded_anim.cca
-- Plays a delta-encoded teletext animation on a 4x3 monitor (text scale 0.5). Ctrl+T to stop.
local path = ... or "grounded_anim.cca"

local mon = peripheral.find("monitor")
assert(mon, "No monitor found")
mon.setTextScale(0.5)

local fh = fs.open(path, "rb")
assert(fh, "Can't open " .. path)
local data = fh.readAll()
fh.close()

local byte, char, concat, floor = string.byte, string.char, table.concat, math.floor

assert(data:sub(1, 4) == "CCA1", "Not a CCA1 file")
local W        = byte(data, 5)
local ROWS     = byte(data, 6)
local darkIdx  = byte(data, 7)
local delay    = (byte(data, 9) + byte(data, 10) * 256) / 1000
local nframes  = byte(data, 11) + byte(data, 12) * 256
local BODY     = 61

for i = 0, 15 do
  local p = 13 + i * 3
  mon.setPaletteColor(2 ^ i, byte(data, p) / 255, byte(data, p + 1) / 255, byte(data, p + 2) / 255)
end

local hex = {}
for i = 0, 15 do hex[i] = ("0123456789abcdef"):sub(i + 1, i + 1) end

-- centre the picture on the monitor
local mw, mh = mon.getSize()
local xoff = math.max(0, floor((mw - W) / 2))
local yoff = math.max(0, floor((mh - ROWS) / 2))

mon.setBackgroundColor(2 ^ darkIdx)
mon.clear()

-- screen buffers, one entry per cell
local T, F, B = {}, {}, {}
for y = 1, ROWS do
  T[y], F[y], B[y] = {}, {}, {}
  for x = 1, W do T[y][x] = char(128); F[y][x] = hex[darkIdx]; B[y][x] = hex[darkIdx] end
end

local function readVar(pos)
  local b = byte(data, pos)
  if b < 128 then return b, pos + 1 end
  return (b - 128) + byte(data, pos + 1) * 128, pos + 2
end

while true do
  local pos = BODY
  for _ = 1, nframes do
    local timer = os.startTimer(delay)
    local nseg
    nseg, pos = readVar(pos)
    local cell = 0
    local dirty = {}
    for _ = 1, nseg do
      local skip, n
      skip, pos = readVar(pos)
      n, pos = readVar(pos)
      cell = cell + skip
      for _ = 1, n do
        local b1, b2 = byte(data, pos, pos + 1)
        pos = pos + 2
        local row = floor(cell / W) + 1
        local col = cell % W + 1
        T[row][col] = char(128 + b2)
        F[row][col] = hex[floor(b1 / 16)]
        B[row][col] = hex[b1 % 16]
        dirty[row] = true
        cell = cell + 1
      end
    end
    for row in pairs(dirty) do
      mon.setCursorPos(1 + xoff, row + yoff)
      mon.blit(concat(T[row]), concat(F[row]), concat(B[row]))
    end
    repeat local _, id = os.pullEvent("timer") until id == timer
  end
end
