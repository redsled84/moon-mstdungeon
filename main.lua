local Dungeon = require("dungeon")
local inspect = require("inspect")
local dungeon = Dungeon()
print(inspect(dungeon.mst))
love.load = function()
  love.update = function(dt)
    return love.window.setTitle(math.floor(collectgarbage('count')))
  end
  love.draw = function()
    return dungeon:drawGrid()
  end
  love.keypressed = function(key)
    if key == "r" then
      return love.event.quit("restart")
    elseif key == "escape" then
      return love.event.quit()
    end
  end
end
