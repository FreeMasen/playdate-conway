
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
  table.insert(Views.raw, view)
  Views.last_idx = Views.last_idx + 1
end

--- Get the current view
function Views:current()
  return Views.raw[Views.idx]
end

--- Move the current view back one step
---@return boolean[][] @The current state after moving backwards
function Views:step_back()
  Views.idx = math.max(0, Views.idx - 1)
  return Views:current()
end

--- Move the current state forward one step
---@return boolean[][] @The current state after moving forwards
function Views:step_forward()
  Views.idx = math.min(Views.last_idx, Views.idx + 1)
  return Views:current()
end

--- Is this view currently in need of a new state to move forward
function Views:at_end()
  return Views.idx == Views.last_idx
end

return Views
