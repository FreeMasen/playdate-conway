
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local menu = import "ui.lua"

local gfx = playdate.graphics

local state = playdate.datastore.read()
if not state then
  local width, height = playdate.display.getSize()
  state = {
    menu = true,
    seed_value = math.random(),
    has_changed = false,
    columns = width / 5,
    rows = height / 5,
    cell_size = 5,
  }
  playdate.datastore.write(state)
end

function state:set_seed_value(value)
  self.has_changed = self.has_changed or value ~= self.seed_value
  self.seed_value = value
end

function state:set_cell_size(value)
  print("set_cell_size", self.cell_size, value)
  self.has_changed = self.has_changed or value ~= self.cell_size
  local width, height = playdate.display.getSize()
  self.columns = math.floor(width / value)
  self.rows = math.floor(height / value)
  self.cell_size = value
end

local Cell = {}
Cell.__index = Cell

function Cell.new(x, y)
  local alive = math.random() < state.seed_value
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

local cells = nil
local function init_cells()
  cells = {}
  for i=1,state.rows do
    local row = {}
    table.insert(cells, row)
    for j = 1, state.columns do
      table.insert(row, Cell.new(j, i))
    end
  end
end

function init()
  if cells then
    return
  else
    inited = true
  end
  init_cells()
  for i=1,state.rows do
    local above_idx = i-1
    if not cells[above_idx] then
      above_idx = #cells
    end
    local below_idx = i+1
    if not cells[below_idx] then
      below_idx = 1
    end
    for j=1,state.columns do
      local left_idx = j - 1
      if not cells[i][left_idx] then
        left_idx = #cells[i]
      end
      local right_idx = j+1
      if not cells[i][right_idx] then
        right_idx = 1
      end
      local cell = cells[i][j]
      cell:set_neighbor("n", cells[above_idx][j])
      cell:set_neighbor("ne", cells[above_idx][right_idx])
      cell:set_neighbor("e", cells[i][right_idx])
      cell:set_neighbor("se", cells[below_idx][right_idx])
      cell:set_neighbor("s", cells[below_idx][j])
      cell:set_neighbor("sw", cells[below_idx][left_idx])
      cell:set_neighbor("w", cells[i][left_idx])
      cell:set_neighbor("nw", cells[above_idx][left_idx])
    end
  end
end

local function apply_rules()
  if not cells then
    return
  end
  for i, column in ipairs(cells) do
    for j, cell in ipairs(column) do
      local live_neighbors = cell:live_neighbor_count()
      if cell.alive then
        if live_neighbors < 2 or live_neighbors > 3 then
          cell:set_alive(false)
        end
      end
      if not cell.alive and live_neighbors == 3 then
        cell:set_alive(true)
      end
    end
  end
  for i, column in ipairs(cells) do
    for j, cell in ipairs(column) do
      cell:complete_alive()
    end
  end
end

local function render()
  gfx.clear(gfx.kColorWhite)
  if not cells then
    return
  end
  for i, column in ipairs(cells) do
    for j, row in ipairs(column) do
      local x, y = (j-1)*state.cell_size, (i-1)*state.cell_size
      if row.alive then
        gfx.setColor(gfx.kColorBlack)
      else
        gfx.setColor(gfx.kColorWhite)
      end
      gfx.fillRect(x, y, state.cell_size, state.cell_size)
      gfx.setColor(gfx.kColorWhite)
      gfx.drawRect(x, y, state.cell_size, state.cell_size)
      row.did_change = false
    end
  end
  menu:update(state)
end

gfx.clear(gfx.kColorWhite)

function playdate.update()
  render()
  playdate.timer.updateTimers()
end

function state.tick()
  if cells == nil then
    init()
    return
  end
  apply_rules()
end

function state.start()
  state.timer = playdate.timer.keyRepeatTimerWithDelay(500, 500, function()
    state.tick()
  end)
end

function playdate.AButtonUp()
  state.timer:remove()
  cells = nil
  playdate.timer.new(2, function()
    state.start()
  end)
end

function playdate.BButtonUp()
  state.menu = not state.menu
  if state.menu then
    playdate.inputHandlers.push(menu:input_handlers(state))
  else
    playdate.inputHandlers.pop()
    if state.has_changed then
      state.timer:remove()
      cells = nil
      playdate.timer.new(2, function()
        state.start()
      end)
      playdate.datastore.write(state)
    end
  end
end

if state.menu then
  playdate.inputHandlers.push(menu:input_handlers(state))
end

state.start()
