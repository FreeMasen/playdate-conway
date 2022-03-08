
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local menu = import "ui.lua"
local State = import "game_state.lua"

local gfx = playdate.graphics
local state = State.read()

local function render(view)
  gfx.clear(gfx.kColorWhite)
  if not view then
    return
  end
  for i, column in ipairs(view) do
    for j, cell in ipairs(column) do
      local x, y = (j-1)*state.cell_size, (i-1)*state.cell_size
      if cell then
        gfx.setColor(gfx.kColorBlack)
      else
        gfx.setColor(gfx.kColorWhite)
      end
      gfx.fillRect(x, y, state.cell_size, state.cell_size)
      gfx.setColor(gfx.kColorWhite)
      gfx.drawRect(x, y, state.cell_size, state.cell_size)
    end
  end
  menu:update(state)
end

gfx.clear(gfx.kColorWhite)

function playdate.update()
  render(state:view())
  playdate.timer.updateTimers()
end

function playdate.AButtonUp()
  state.timer:remove()
  state.cells = nil
  playdate.timer.new(2, function()
    state:start()
  end)
end

function playdate.BButtonUp()
  state.menu = not state.menu
  if state.menu then
    playdate.inputHandlers.push(menu:input_handlers(state))
  else
    playdate.inputHandlers.pop()
    if state.did_change then
      state.timer:remove()
      state.cells = nil
      state.cell_size = state.next_cell_info.cell_size or state.cell_size
      state.columns = state.next_cell_info.columns or state.columns
      state.rows = state.next_cell_info.rows or state.rows
      state.next_cell_info = {}
      state:unpause()
      playdate.datastore.write(state:raw())
    end
  end
end

function playdate.cranked(change, acceleratedChange)
  state.total_crank_change = (state.total_crank_change or 0) + change
  if state.total_crank_change > 3.6 then
    state.total_crank_change = 0
    state:tick(true)
  elseif state.total_crank_change < -3.6 then
    state.total_crank_change = 0
    state:tick(false)
  end
end

function playdate.crankDocked()
  state:unpause()
end

function playdate.crankUndocked()
  state:pause()
end

if state.menu then
  playdate.inputHandlers.push(menu:input_handlers(state))
end

state:start()

if not playdate.isCrankDocked() then
  state:pause()
end
