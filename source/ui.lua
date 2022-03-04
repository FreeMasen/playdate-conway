import "CoreLibs/graphics"
import "CoreLibs/timer"

local gfx = playdate.graphics
local m = {
  x = 10,
  y = 10,
  width = 150,
  height = 200,
  is_a_pressed = false,
  selected = "seed-up",
}

local labels = {
  seed = "Seed rate",
  cell = "Cell size",
}

function labels:max_width()
  local width, height = gfx.getTextSize(self.seed)
  return width
end

function m:update(state)
  if not state.menu then
    return
  end
  gfx.setColor(gfx.kColorWhite)
  gfx.fillRoundRect(self.x, self.y, self.width, self.height, 0.5)
  gfx.setColor(gfx.kColorBlack)
  gfx.drawRoundRect(self.x, self.y, self.width, self.height, 0.5)
  local menu = "*Menu*"
  local _width, height = gfx.getTextSize(menu)
  gfx.drawTextAligned(menu, self.x + (self.width / 2), self.y + 2, kTextAlignment.center)
  self:draw_seed_random(self.x + 5, self.y + height + 2, state.seed_value)
  self:draw_cell_size(self.x + 5, self.y + height + 50, state.cell_size)
end

function m:draw_up_arrow_button(x, y, is_pressed, is_selected)
  gfx.drawRoundRect(x, y, 16, 16, 1)
  if is_selected then
    gfx.drawRoundRect(x+1, y + 1, 14, 14, 1)
  end
  local p1x, p1y = x + 8, y + 4
  local p2x, p2y = p1x - 4, p1y + 6
  local p3x, p3y = p1x + 3, p1y + 6
  gfx.drawTriangle(
    p1x, p1y,
    p2x, p2y,
    p3x, p3y
  )
  if is_pressed then
    gfx.fillTriangle(
      p1x, p1y,
      p2x, p2y,
      p3x, p3y
    )
  end
end

function m:draw_down_arrow_button(x, y, is_pressed, is_selected)
  gfx.drawRoundRect(x, y, 16, 16, 1)
  if is_selected then
    gfx.drawRoundRect(x+1, y + 1, 14, 14, 1)
  end
  local p1x, p1y = x + 8, y + 11
  local p2x, p2y = p1x - 4, p1y - 6
  local p3x, p3y = p1x + 3, p1y - 6
  gfx.drawTriangle(
    p1x, p1y,
    p2x, p2y,
    p3x, p3y
  )
  if is_pressed then
    gfx.fillTriangle(
      p1x, p1y,
      p2x, p2y,
      p3x, p3y
    )
  end
end

function m:draw_text_box(x, y, width, value)
  local text_width, height = gfx.getTextSize(value)
  gfx.drawRoundRect(x, y, width, height + 2, 0.8)
  gfx.drawTextAligned(value, x + width - 3, y + 3, kTextAlignment.right)
end

function m:draw_seed_random(x, y, seed_value)
  gfx.drawTextAligned(labels.seed, x, y+9, kTextAlignment.left)
  self:draw_up_arrow_button(x + labels:max_width() + 3, y, self.selected == "seed-up" and self.is_a_pressed, self.selected == "seed-up")
  self:draw_down_arrow_button(x + labels:max_width() + 3, y + 20, self.selected == "seed-down" and self.is_a_pressed, self.selected == "seed-down")
  local seed_text = string.format("%.1f", seed_value)
  self:draw_text_box(x + labels:max_width() + 23, y + 5, 40, seed_text)
end

function m:draw_cell_size(x, y, cell_size)
  gfx.drawTextAligned(labels.cell, x, y+9, kTextAlignment.left)
  self:draw_up_arrow_button(x + labels:max_width() + 3, y, self.selected == "cell-up" and self.is_a_pressed, self.selected == "cell-up")
  self:draw_down_arrow_button(x + labels:max_width() + 3, y + 20, self.selected == "cell-down" and self.is_a_pressed, self.selected == "cell-down")
  local cell_text = string.format("%d", cell_size)
  self:draw_text_box(x + labels:max_width() + 23, y + 5, 40, cell_text)
end

function m:a_pressed(state)
  self.is_a_pressed = true
  if self.selected == "seed-up" then
    state:set_seed_value(math.min(0.9, state.seed_value + 0.1))
  elseif self.selected == "seed-down" then
    state:set_seed_value(math.max(0.1, state.seed_value - 0.1))
  elseif self.selected == "cell-up" then
    state:set_cell_size(math.min(1, state.cell_size + 1))
  elseif self.selected == "cell-up" then
    state:set_cell_size(math.max(50, state.cell_size - 1))
  end
  playdate.timer.performAfterDelay(0.3, function()
    self.is_a_pressed = false
  end)
end

function m:up_pressed()
  if self.selected == "seed-up" then
    self.selected = "cell-down"
  elseif self.selected == "seed-down" then
    self.selected = "seed-up"
  elseif self.selected == "cell-down" then
    self.selected = "cell-up"
  elseif self.selected == "cell-up" then
    self.selected = "seed-down"
  end
end

function m:down_pressed()
  if self.selected == "seed-up" then
    self.selected = "seed-down"
  elseif self.selected == "seed-down" then
    self.selected = "cell-up"
  elseif self.selected == "cell-up" then
    self.selected = "cell-down"
  elseif self.selected == "cell-down" then
    self.selected = "speed-up"
  end
end

function m:input_handlers(state)
  return {
    AButtonUp = function()
      m:a_pressed(state)
    end,
    upButtonUp = function()
      m:up_pressed()
    end,
    downButtonUp = function()
      m:down_pressed()
    end,
  }
end

return m
