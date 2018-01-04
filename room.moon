class Room
  new: (@x, @y, @width, @height) =>
  getVertices: =>
    return @x, @y, @x + @width, @y + @height

return Room