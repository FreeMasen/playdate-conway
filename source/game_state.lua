local Views = import "view_state.lua"
local Cell = import "cell.lua"

---@class State
---@field menu boolean If the menu is displayed
---@field seed_value number Percent of cells that begin alive
---@field has_changed boolean If the last menu closing resulted in a change
---@field columns integer The number of columns
---@field rows integer The number of rows
---@field cell_size integer The number of pixels each cell takes up
---@field next_cell_info table Pending menu options
---@field total_crank_change number The current state of the crank
---@field views Views The view history
---@field cells Cell[] The view state for this run
local State = {}
State.__index = State

function State.from_raw(raw)
  return setmetatable({
    menu = raw.menu,
    seed_value = raw.seed_value,
    has_changed = false,
    columns = raw.columns,
    rows = raw.rows,
    cell_size = raw.cell_size,
    next_cell_info = {},
    total_crank_change = 0,
    views = Views.new()
  }, State)
end

--- Read the state from the datastore
function State.read()
  local raw = playdate.datastore.read()
  if not raw then
    local width, height = playdate.display.getSize()
    local cell_size = 5
    raw = {
      menu = true,
      seed_value = 0.5,
      has_changed = false,
      columns = width / cell_size,
      rows = height / cell_size,
      cell_size = cell_size
    }
    playdate.datastore.write(raw)
  end
  return State.from_raw(raw)
end

--- Distill this class into a raw table for storage
function State:raw()
  return {
    menu = self.menu,
    seed_value = self.seed_value,
    columns = self.columns,
    rows = self.rows,
    cell_size = self.cell_size
  }
end

--- Set the seed value from the menu for the next game
---@param value number Percent as a number between 0.1 and 0.9
function State:set_seed_value(value)
  self.did_change = self.did_change or value ~= self.seed_value
  self.seed_value = value
end

--- Increase the cell size by 1 saturating at 20px
function State:increment_cell_size()
  local current_size = self.cell_size
  if self.next_cell_info and self.next_cell_info.cell_size then
    current_size = self.next_cell_info.cell_size
  end
  self:set_cell_size(math.min(20, current_size + 1))
end

--- Decrease the cell size by 1 saturating at 3px
function State:decrement_cell_size()
  local current_size = self.cell_size
  if self.next_cell_info and self.next_cell_info.cell_size then
    current_size = self.next_cell_info.cell_size
  end
  self:set_cell_size(math.max(3, current_size - 1))
end

--- Set the cell size from a raw value, this will re-calculate the row and column values
--- based on the screen size
---@param value integer
function State:set_cell_size(value)
  print("set_cell_size", self.cell_size, value)
  self.did_change = self.did_change or value ~= self.cell_size
  local width, height = playdate.display.getSize()
  local next_cell_info = {
    columns = math.floor(width / value),
    rows = math.floor(height / value),
    cell_size = value
  }
  self.next_cell_info = next_cell_info
end

--- Initialize the cells w/o any relationships
function State:init_cells()
  self.cells = {}
  for i=1, self.rows do
    local row = {}
    table.insert(self.cells, row)
    for j = 1, self.columns do
      table.insert(row, Cell.new(j, i, self.seed_value))
    end
  end
end

--- Initialize the state for a single run
---
--- This method will generate the relationships between cells
function State:init()
  if self.cells then
    return
  end
  self:init_cells()
  for i=1,self.rows do
    local above_idx = i-1
    if not self.cells[above_idx] then
      above_idx = #self.cells
    end
    local below_idx = i+1
    if not self.cells[below_idx] then
      below_idx = 1
    end
    for j=1,self.columns do
      local left_idx = j - 1
      if not self.cells[i][left_idx] then
        left_idx = #self.cells[i]
      end
      local right_idx = j+1
      if not self.cells[i][right_idx] then
        right_idx = 1
      end
      local cell = self.cells[i][j]
     cell:set_neighbor("n", self.cells[above_idx][j])
     cell:set_neighbor("ne", self.cells[above_idx][right_idx])
     cell:set_neighbor("e", self.cells[i][right_idx])
     cell:set_neighbor("se", self.cells[below_idx][right_idx])
     cell:set_neighbor("s", self.cells[below_idx][j])
     cell:set_neighbor("sw", self.cells[below_idx][left_idx])
     cell:set_neighbor("w", self.cells[i][left_idx])
     cell:set_neighbor("nw", self.cells[above_idx][left_idx])
    end
  end
end

--- Apply the generational rules to the current cells
function State:apply_rules()
  if not self.cells then
    return
  end
  for i, column in ipairs(self.cells) do
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
  for i, column in ipairs(self.cells) do
    for j, cell in ipairs(column) do
      cell:complete_alive()
    end
  end
end

--- Update the state for a single generation
function State:tick()
  if self.cells == nil then
    self:init()
    return
  end
  self:apply_rules()
end

--- Start the current series
function State:start()
  self.timer = playdate.timer.keyRepeatTimerWithDelay(500, 500, function()
    self:tick()
  end)
end

--- Pause the current series
function State:pause()
  if self.timer then
    self.timer:remove()
  end
end

--- Restart the current series after a being paused
function State:unpause()
  playdate.timer.new(2, function()
    self:start()
  end)
end

return State
