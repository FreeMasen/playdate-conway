
---@class Cell
---@field x integer The x index for this cell
---@field y integer The y index for this cell
---@field alive boolean If this cell is alive
---@field next_alive boolean If this cell will be alive in the next generation
---@field did_change boolean If this cell has changed from gen to gen
---@field trace boolean If this cell should log tracing information
---@field n Cell
---@field ne Cell
---@field e Cell
---@field se Cell
---@field s Cell
---@field sw Cell
---@field w Cell
---@field nw Cell
local Cell = {}
Cell.__index = Cell

function Cell.new(x, y, seed_value)
  local alive = math.random() < seed_value
  return setmetatable({
    x = x,
    y = y,
    alive = alive,
    next_alive = alive,
    did_change = false,
    trace = false,
  }, Cell)
end

function Cell:live_neighbor_count()
  local ret = (self.n.alive and 1 or 0)
  + (self.ne.alive and 1 or 0)
  + (self.e.alive and 1 or 0)
  + (self.se.alive and 1 or 0)
  + (self.s.alive and 1 or 0)
  + (self.sw.alive and 1 or 0)
  + (self.w.alive and 1 or 0)
  + (self.nw.alive and 1 or 0)
  if self.trace and ret > 0 then
    print(string.format('(%s)---%s---(%s)', self.alive, self:debug_idx(), ret))
    print(string.format("%s %s %s", self.nw.alive, self.n.alive, self.ne.alive))
    print(string.format("%s %s", self.w.alive, self.e.alive))
    print(string.format("%s %s %s", self.sw.alive, self.s.alive, self.se.alive))
    print(string.format('---%s---', self:debug_idx()))
  end
  return ret
end

function Cell:debug_idx()
  return string.format("%sx%s", self.x or '?', self.y or '?')
end

function Cell:set_neighbor(idx, cell)
  self[idx] = cell
end

function Cell:set_alive(is_alive)
  if self.trace then
    print(self:debug_idx(), "setting alive", is_alive, self:live_neighbor_count())
  end
  local did_change = self.alive ~= is_alive
  self.next_alive = is_alive
  self.did_change = did_change
end

function Cell:complete_alive()
  if self.did_change then
    self.alive = self.next_alive
  end
end

return Cell
