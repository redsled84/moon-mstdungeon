local Kruskals = require("kruskals")
local Delaunay = require("delaunay")
local Point = Delaunay.Point
local Edge = Delaunay.Edge
local Grid = require("jumper.grid")
local Pathfinder = require("jumper.pathfinder")
local Room = require("room")
local Perlin = require("perlin")
local perlin = Perlin(256)
math.randomseed(os.time())
local sprites = love.graphics.newImage("rogue.png")
sprites:setFilter("nearest", "nearest")
local wallSprite = love.graphics.newQuad(0, 0, 32, 32, sprites:getWidth(), sprites:getHeight())
local floorSprite = love.graphics.newQuad(32, 0, 32, 32, sprites:getWidth(), sprites:getHeight())
local corridorSprite = love.graphics.newQuad(64, 0, 32, 32, sprites:getWidth(), sprites:getHeight())
local tiles
tiles = {
  room = 1,
  corridor = 2,
  door = 3,
  wall = 4,
  noCorridor = 69
}
local compare
compare = function(a, b)
  if a:length() < b:length() then
    return a
  end
end
local walkable
walkable = function(value)
  return value ~= tiles.noCorridor
end
local Dungeon
do
  local _class_0
  local _base_0 = {
    initializeGrid = function(self)
      for y = 1, self.height do
        local temp
        temp = { }
        for x = 1, self.width do
          temp[x] = 0
        end
        self.grid[#self.grid + 1] = temp
      end
    end,
    initializeRooms = function(self)
      if self.numAttempts < self.maxAttempts and #self.rooms < self.numRooms then
        local x, y, width, height
        width, height = math.random(self.minW, self.maxW), math.random(self.minH, self.maxH)
        x, y = math.random(2, self.width - width - 1), math.random(2, self.height - height - 1)
        local room
        room = Room(x, y, width, height)
        local x1, y1, x2, y2
        x1, y1, x2, y2 = room:getVertices()
        if self:searchArea(x1 - 3, y1 - 3, x2 + 3, y2 + 3, tiles.room) then
          self.numAttempts = self.numAttempts + 1
          return self:initializeRooms()
        else
          self.numAttempts = self.numAttempts + 1
          self.rooms[#self.rooms + 1] = room
          self:setArea(x1, y1, x2 - 1, y2 - 1, tiles.room)
          if x1 - 1 >= 1 and y1 - 1 >= 1 then
            self.grid[y1 - 1][x1 - 1] = tiles.noCorridor
          end
          if x2 + 1 <= self.width and y1 - 1 >= 1 then
            self.grid[y1 - 1][x2] = tiles.noCorridor
          end
          if x1 - 1 >= 1 and y2 + 1 <= self.height then
            self.grid[y2][x1 - 1] = tiles.noCorridor
          end
          if x2 + 1 <= self.width and y2 + 1 <= self.height then
            self.grid[y2][x2] = tiles.noCorridor
          end
          return self:initializeRooms()
        end
      end
    end,
    setArea = function(self, x1, y1, x2, y2, value)
      for y = y1, y2 do
        for x = x1, x2 do
          self.grid[y][x] = value
        end
      end
    end,
    searchArea = function(self, x1, y1, x2, y2, value)
      local tx1, ty1, tx2, ty2
      tx1, ty1 = x1 - 1 >= 1 and x1 or 1, y1 - 1 >= 1 and y1 or 1
      tx2, ty2 = x2 + 1 <= self.width and x2 or self.width, y2 + 1 <= self.height and y2 or self.height
      for y = ty1, ty2 do
        for x = tx1, tx2 do
          if self.grid[y][x] == value then
            return true
          end
        end
      end
      return false
    end,
    initializeMST = function(self)
      local points
      points = { }
      for i = 1, #self.rooms do
        local x, y
        x, y = math.floor(self.rooms[i].x + self.rooms[i].width / 2), math.floor(self.rooms[i].y + self.rooms[i].height / 2)
        points[#points + 1] = Point(x, y)
      end
      local edges
      edges = { }
      local triangles
      triangles = Delaunay.triangulate(unpack(points))
      for i = 1, #triangles do
        local p1, p2, p3
        p1, p2, p3 = triangles[i].p1, triangles[i].p2, triangles[i].p3
        local e1, e2, e3
        e1, e2, e3 = Edge(p1, p2), Edge(p2, p3), Edge(p1, p3)
        if #edges > 1 then
          if not self:edgeAdded(edges, e1) then
            edges[#edges + 1] = e1
          end
          if not self:edgeAdded(edges, e2) then
            edges[#edges + 1] = e2
          end
          if not self:edgeAdded(edges, e3) then
            edges[#edges + 1] = e3
          end
        else
          edges[#edges + 1] = e1
          edges[#edges + 1] = e2
          edges[#edges + 1] = e3
        end
      end
      table.sort(edges, compare)
      self.mst = Kruskals(points, edges)
    end,
    edgeAdded = function(self, edges, edge)
      for i = 1, #edges do
        local temp
        temp = edges[i]
        if temp:same(edge) then
          return true
        end
      end
      return false
    end,
    initializeCorridors = function(self)
      local grid, finder, path
      grid = Grid(self.grid)
      finder = Pathfinder(grid, 'ASTAR', walkable)
      finder:setMode('ORTHOGONAL')
      self.corridors = { }
      for i = 1, #self.mst do
        local nodes
        nodes = { }
        path = finder:getPath(self.mst[i].p1.x, self.mst[i].p1.y, self.mst[i].p2.x, self.mst[i].p2.y)
        for node, count in path:nodes() do
          if self.grid[node:getY()][node:getX()] ~= tiles.room then
            nodes[#nodes + 1] = node
            self.grid[node:getY()][node:getX()] = tiles.corridor
          end
        end
        if #nodes > 2 then
          self.grid[nodes[1]:getY()][nodes[1]:getX()] = tiles.door
          self.grid[nodes[#nodes]:getY()][nodes[#nodes]:getX()] = tiles.door
        end
      end
    end,
    initializeWalls = function(self)
      for i = 1, #self.rooms do
        local room
        room = self.rooms[i]
        if room.x - 1 >= 1 and room.y - 1 >= 1 then
          self.grid[room.y - 1][room.x - 1] = tiles.wall
        end
        for x = room.x, room.x + room.width do
          if room.y - 1 >= 1 then
            if self.grid[room.y - 1][x] ~= tiles.door then
              self.grid[room.y - 1][x] = tiles.wall
            end
          end
          if room.y + room.height <= self.height then
            if self.grid[room.y + room.height][x] ~= tiles.door then
              self.grid[room.y + room.height][x] = tiles.wall
            end
          end
        end
        for y = room.y, room.y + room.height do
          if room.x - 1 >= 1 then
            if self.grid[y][room.x - 1] ~= tiles.door then
              self.grid[y][room.x - 1] = tiles.wall
            end
          end
          if room.x + room.width <= self.width then
            if self.grid[y][room.x + room.width] ~= tiles.door then
              self.grid[y][room.x + room.width] = tiles.wall
            end
          end
        end
      end
    end,
    initializeTerrain = function(self)
      self.terrain = perlin:generate(self.width, self.height)
      local counter
      counter = 0
      for y = 1, self.height do
        for x = 1, self.width do
          if self.grid[y][x] == tiles.room and self.terrain[y][x] > .002 then
            counter = counter + 1
          end
        end
      end
      print(counter)
      if counter < self.numGrassTiles and self.terrainAttempts < self.maxTerrainAttempts then
        self.terrainAttempts = self.terrainAttempts + 1
        return self:initializeTerrain()
      end
    end,
    drawTerrain = function(self)
      for y = 1, self.height do
        for x = 1, self.width do
          if self.grid[y][x] == tiles.room then
            if self.terrain[y][x] > .002 then
              love.graphics.setColor(35, 85, 255, 55)
            else
              love.graphics.setColor(35, 235, 105, 55)
            end
            love.graphics.rectangle("fill", x * self.tileSize, y * self.tileSize, self.tileSize, self.tileSize)
          end
        end
      end
    end,
    drawMST = function(self)
      for i = 1, #self.mst do
        love.graphics.setColor(255, 255, 255, 50)
        love.graphics.line(self.mst[i].p1.x * self.tileSize, self.mst[i].p1.y * self.tileSize, self.mst[i].p2.x * self.tileSize, self.mst[i].p2.y * self.tileSize)
      end
    end,
    drawGrid = function(self)
      for y = 1, self.height do
        for x = 1, self.width do
          if self.grid[y][x] == tiles.room then
            love.graphics.setColor(245, 245, 245, 100)
            love.graphics.draw(sprites, floorSprite, x * self.tileSize, y * self.tileSize, 0, .5, .5)
          elseif self.grid[y][x] == tiles.corridor then
            love.graphics.setColor(200, 155, 65, 100)
            love.graphics.draw(sprites, corridorSprite, x * self.tileSize, y * self.tileSize, 0, .5, .5)
          elseif self.grid[y][x] == tiles.door then
            love.graphics.setColor(65, 65, 55, 150)
            love.graphics.rectangle("fill", x * self.tileSize, y * self.tileSize, self.tileSize, self.tileSize)
          elseif self.grid[y][x] == tiles.wall then
            love.graphics.setColor(235, 35, 50, 150)
            love.graphics.draw(sprites, wallSprite, x * self.tileSize, y * self.tileSize, 0, .5, .5)
          else
            love.graphics.setColor(0, 255, 0, 100)
          end
        end
      end
    end,
    drawRooms = function(self)
      for i = 1, #self.rooms do
        local room
        room = self.rooms[i]
        love.graphics.setColor(255, 255, 255, 100)
        love.graphics.rectangle("fill", room.x * self.tileSize, room.y * self.tileSize, room.width * self.tileSize, room.height * self.tileSize)
      end
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self)
      self.width = 48
      self.height = 34
      self.tileSize = 16
      self.grid = { }
      self:initializeGrid()
      self.rooms = { }
      self.numRooms = 15
      self.numAttempts = 0
      self.maxAttempts = 100
      self.minW, self.maxW = 4, 7
      self.minH, self.maxH = 2, 4
      self:initializeRooms()
      self:initializeMST()
      self:initializeCorridors()
      self:initializeWalls()
      self.terrainAttempts = 0
      self.maxTerrainAttempts = 500
      self.numGrassTiles = 40
      return self:initializeTerrain()
    end,
    __base = _base_0,
    __name = "Dungeon"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Dungeon = _class_0
end
return Dungeon
