Dungeon = require "dungeon"
inspect = require "inspect"

dungeon = Dungeon!

print inspect dungeon.mst

love.load = ->
  love.update = (dt) ->
    love.window.setTitle math.floor collectgarbage 'count'
  love.draw = ->
    dungeon\drawGrid!
    -- dungeon\drawMST!
  love.keypressed = (key) ->
    if key == "r"
      love.event.quit "restart"
    elseif key == "escape"
      love.event.quit!