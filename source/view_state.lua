
---@class Views
---@field idx integer The current index of views
---@field last_idx integer The length of self.raw
---@field raw table[] The raw list of view states
local Views = {}
Views.__index = Views

--- Create a new Views
---@param init boolean[][] The first viewin the list
function Views.new(init)
  return setmetatable({
    idx = 0,
    last_idx = init and 1 or 0,
    raw = {init}
  }, Views)
end

--- Append a new view to the list of views
---@param view boolean[][]
function Views:push(view)
  table.insert(self.raw, view)
  self.last_idx = self.last_idx + 1
end

--- Get the current view
function Views:current()
  return self.raw[self.idx]
end

--- Move the current view back one step
---@return boolean[][] @The current state after moving backwards
function Views:step_back()
  self.idx = math.max(1, self.idx - 1)
  return self:current()
end

--- Move the current state forward one step
---@return boolean[][] @The current state after moving forwards
function Views:step_forward()
  self.idx = math.min(self.last_idx, self.idx + 1)
  return self:current()
end

--- Is this view currently in need of a new state to move forward
function Views:at_end()
  return self.idx == self.last_idx
end

return Views
