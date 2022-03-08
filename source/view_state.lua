
local views = {}
views.__index = views

function views.new(init)
  return setmetatable({
    idx = 0,
    last_idx = init and 1 or 0,
    raw = {init}
  }, views)
end

function views:push(view)
  table.insert(self.raw, view)
  self.last_idx = self.last_idx + 1
end

function views:current()
  return self.raw[self.idx]
end

function views:step_back()
  self.idx = math.max(0, self.idx - 1)
  return self:current()
end

function views:step_forward()
  self.idx = math.min(self.last_idx, self.idx + 1)
  return self:current()
end

function views:at_end()
  return self.idx == self.last_idx
end

return views
