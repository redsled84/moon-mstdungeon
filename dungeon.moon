Kruskals = require "kruskals"
Delaunay = require "delaunay"
Point = Delaunay.Point
Edge = Delaunay.Edge
Grid = require "jumper.grid"
Pathfinder = require "jumper.pathfinder"

Room = require "room"
Perlin = require "perlin"
perlin = Perlin 256

math.randomseed os.time!

sprites = love.graphics.newImage "rogue.png"
sprites\setFilter "nearest", "nearest"
wallSprite = love.graphics.newQuad 0, 0, 32, 32, sprites\getWidth!, sprites\getHeight!
floorSprite = love.graphics.newQuad 32, 0, 32, 32, sprites\getWidth!, sprites\getHeight!
corridorSprite = love.graphics.newQuad 64, 0, 32, 32, sprites\getWidth!, sprites\getHeight!

local tiles
tiles = {
  room: 1,
  corridor: 2,
  door: 3,
  wall: 4,
  noCorridor: 69
}

compare = (a, b) ->
  if a\length! < b\length!
    return a

walkable = (value) ->
  return value ~= tiles.noCorridor

class Dungeon
  new: =>
    @width = 48
    @height = 34
    @tileSize = 16

    @grid = {}
    @initializeGrid!

    @rooms = {}
    @numRooms = 15
    @numAttempts = 0
    @maxAttempts = 100

    @minW, @maxW = 4, 7
    @minH, @maxH = 2, 4

    @initializeRooms!
    @initializeMST!
    @initializeCorridors!
    @initializeWalls!
    -- @setArea 1, 1, 5, 5, tiles.room

    @terrainAttempts = 0
    @maxTerrainAttempts = 500
    @numGrassTiles = 40

    @initializeTerrain!

  initializeGrid: =>
    for y = 1, @height
      local temp
      temp = {}
      for x = 1, @width
        temp[x] = 0
      @grid[#@grid+1] = temp

  initializeRooms: =>
    if @numAttempts < @maxAttempts and #@rooms < @numRooms
      local x, y, width, height
      width, height = math.random(@minW, @maxW), math.random(@minH, @maxH)
      x, y = math.random(2, @width-width-1), math.random(2, @height-height-1)

      local room
      room = Room x, y, width, height

      local x1, y1, x2, y2
      x1, y1, x2, y2 = room\getVertices!
      -- print x1, y2, x2, y2

      if @searchArea x1-3, y1-3, x2+3, y2+3, tiles.room
        @numAttempts += 1
        @initializeRooms!
      else
        @numAttempts += 1
        @rooms[#@rooms+1] = room
        @setArea x1, y1, x2-1, y2-1, tiles.room

        if x1 - 1 >= 1 and y1 - 1 >= 1
          @grid[y1-1][x1-1] = tiles.noCorridor
        if x2 + 1 <= @width and y1 - 1 >= 1
          @grid[y1-1][x2] = tiles.noCorridor
        if x1 - 1 >= 1 and y2 + 1 <= @height
          @grid[y2][x1-1] = tiles.noCorridor
        if x2 + 1 <= @width and y2 + 1 <= @height
          @grid[y2][x2] = tiles.noCorridor

        @initializeRooms!


  setArea: (x1, y1, x2, y2, value) =>
    for y = y1, y2
      for x = x1, x2
        @grid[y][x] = value

  searchArea: (x1, y1, x2, y2, value) =>
    local tx1, ty1, tx2, ty2
    tx1, ty1 = x1 - 1 >= 1 and x1 or 1, y1 - 1 >= 1 and y1 or 1
    tx2, ty2 = x2 + 1 <= @width and x2 or @width, y2 + 1 <= @height and y2 or @height
    for y = ty1, ty2
      for x = tx1, tx2
        if @grid[y][x] == value
          return true

    return false

  initializeMST: =>
    local points
    points = {}
    for i = 1, #@rooms
      local x, y
      x, y = math.floor(@rooms[i].x + @rooms[i].width / 2), math.floor(@rooms[i].y + @rooms[i].height / 2)
      points[#points+1] = Point(x, y)

    local edges
    edges = {}

    local triangles
    triangles = Delaunay.triangulate unpack points
    for i = 1, #triangles
      local p1, p2, p3
      p1, p2, p3 = triangles[i].p1, triangles[i].p2, triangles[i].p3
      local e1, e2, e3
      e1, e2, e3 = Edge(p1, p2), Edge(p2, p3), Edge(p1, p3)

      if #edges > 1
        if not @edgeAdded edges, e1
          edges[#edges+1] = e1
        if not @edgeAdded edges, e2
          edges[#edges+1] = e2
        if not @edgeAdded edges, e3
          edges[#edges+1] = e3
      else
        edges[#edges+1] = e1
        edges[#edges+1] = e2
        edges[#edges+1] = e3
    
    table.sort edges, compare

    @mst = Kruskals points, edges

  edgeAdded: (edges, edge) =>
    for i = 1, #edges
        local temp
        temp = edges[i]
        if temp\same edge
          return true
    return false

  initializeCorridors: =>
    local grid, finder, path
    grid = Grid @grid
    finder = Pathfinder grid, 'ASTAR', walkable
    finder\setMode 'ORTHOGONAL'

    @corridors = {}
    for i = 1, #@mst
      local nodes
      nodes = {}
      path = finder\getPath @mst[i].p1.x, @mst[i].p1.y, @mst[i].p2.x, @mst[i].p2.y

      for node, count in path\nodes!
        if @grid[node\getY!][node\getX!] ~= tiles.room
          nodes[#nodes+1] = node
          @grid[node\getY!][node\getX!] = tiles.corridor

      if #nodes > 2
        @grid[nodes[1]\getY!][nodes[1]\getX!] = tiles.door
        @grid[nodes[#nodes]\getY!][nodes[#nodes]\getX!] = tiles.door

  initializeWalls: =>
    for i = 1, #@rooms
      local room
      room = @rooms[i]

      if room.x - 1 >= 1 and room.y - 1 >= 1
        @grid[room.y-1][room.x-1] = tiles.wall

      for x = room.x, room.x + room.width
        if room.y - 1 >= 1
          if @grid[room.y-1][x] ~= tiles.door
            @grid[room.y-1][x] = tiles.wall

        if room.y + room.height <= @height
          if @grid[room.y+room.height][x] ~= tiles.door
            @grid[room.y+room.height][x] = tiles.wall

      for y = room.y, room.y + room.height
        if room.x - 1 >= 1
          if @grid[y][room.x-1] ~= tiles.door
            @grid[y][room.x-1] = tiles.wall

        if room.x + room.width <= @width
          if @grid[y][room.x+room.width] ~= tiles.door
            @grid[y][room.x+room.width] = tiles.wall

  initializeTerrain: =>
    @terrain = perlin\generate @width, @height
    local counter
    counter = 0
    for y = 1, @height
      for x = 1, @width
        if @grid[y][x] == tiles.room and @terrain[y][x] > .002
          counter += 1

    print counter

    if counter < @numGrassTiles and @terrainAttempts < @maxTerrainAttempts
      @terrainAttempts += 1
      @initializeTerrain!

  drawTerrain: =>
    for y = 1, @height
      for x = 1, @width
        if @grid[y][x] == tiles.room 
          if @terrain[y][x] > .002
            love.graphics.setColor(35,85,255,55)
          else
            love.graphics.setColor(35,235,105,55)
          love.graphics.rectangle("fill", x * @tileSize, y * @tileSize,
            @tileSize, @tileSize)

  drawMST: =>
    for i = 1, #@mst
      love.graphics.setColor(255,255,255, 50)
      love.graphics.line(@mst[i].p1.x * @tileSize, @mst[i].p1.y * @tileSize,
        @mst[i].p2.x * @tileSize, @mst[i].p2.y * @tileSize)

  drawGrid: =>
    for y = 1, @height
      for x = 1, @width
        if @grid[y][x] == tiles.room
          love.graphics.setColor 245,245,245,100
          love.graphics.draw sprites, floorSprite, x * @tileSize, y * @tileSize, 0, .5, .5
        elseif @grid[y][x] == tiles.corridor
          love.graphics.setColor 200,155,65,100
          love.graphics.draw sprites, corridorSprite, x * @tileSize, y * @tileSize, 0, .5, .5
        elseif @grid[y][x] == tiles.door
          love.graphics.setColor 65,65,55,150
          love.graphics.rectangle "fill", x * @tileSize, y * @tileSize, @tileSize, @tileSize
        elseif @grid[y][x] == tiles.wall
          love.graphics.setColor 235,35,50,150
          love.graphics.draw sprites, wallSprite, x * @tileSize, y * @tileSize, 0, .5, .5
        -- elseif @grid[y][x] == tiles.noCorridor
          -- love.graphics.setColor 0,255,255,100

        else
          love.graphics.setColor 0,255,0,100
        -- love.graphics.rectangle "fill", x * @tileSize, y * @tileSize, @tileSize, @tileSize
        -- love.graphics.setColor 255, 255, 255, 15
        -- love.graphics.rectangle "fill", x * @tileSize, y * @tileSize, @tileSize, @tileSize

    -- for i = 1, #@corridors
    --   love.graphics.setColor 255,0,255,150
    --   local p1, p2
    --   p1 = @corridors[i][1]
    --   p2 = @corridors[i][#@corridors[i]]
    --   love.graphics.rectangle "fill", p1.x * @tileSize, p1.y * @tileSize, @tileSize, @tileSize
    --   love.graphics.rectangle "fill", p2.x * @tileSize, p2.y * @tileSize, @tileSize, @tileSize

  drawRooms: =>
    for i = 1, #@rooms
      local room
      room = @rooms[i]
      love.graphics.setColor 255, 255, 255, 100
      love.graphics.rectangle "fill", room.x * @tileSize, room.y * @tileSize,
        room.width * @tileSize, room.height * @tileSize

return Dungeon