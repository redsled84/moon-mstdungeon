Dungeon = require "dungeon"
inspect = require "inspect"

dungeon = Dungeon!

love.load = ->
  love.update = (dt) ->
    love.window.setTitle math.floor collectgarbage 'count'

  love.draw = ->
    dungeon\drawGrid!
    -- dungeon\drawMST!

    dungeon\drawTerrain!
    
  love.keypressed = (key) ->
    if key == "r"
      love.event.quit "restart"
    elseif key == "escape"
      love.event.quit!