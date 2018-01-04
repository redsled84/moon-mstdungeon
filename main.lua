local Dungeon = require("dungeon")
local inspect = require("inspect")
local dungeon = Dungeon()
love.load = function()
  love.update = function(dt)
    return love.window.setTitle(math.floor(collectgarbage('count')))
  end
  love.draw = function()
    dungeon:drawGrid()
    return dungeon:drawTerrain()
  end
  love.keypressed = function(key)
    if key == "r" then
      return love.event.quit("restart")
    elseif key == "escape" then
      return love.event.quit()
    end
  end
end
