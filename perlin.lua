local Perlin
do
  local _class_0
  local _base_0 = {
    noise = function(self, x, y, z)
      local a, aa, ab, b, ba, bb, u, v, w, _x, _y, _z
      _x = math.floor(x) % self.n
      _y = math.floor(y) % self.n
      _z = math.floor(z) % self.n
      x = x - math.floor(x)
      y = y - math.floor(y)
      z = z - math.floor(z)
      u = self:fade(x)
      v = self:fade(y)
      w = self:fade(z)
      a = self.p[_x + 1] + _y
      aa = self.p[a + 1] + _z
      ab = self.p[a + 2] + _z
      b = self.p[_x + 2] + _y
      ba = self.p[b + 1] + _z
      bb = self.p[b + 2] + _z
      return self:lerp(w, self:lerp(v, self:lerp(u, self:grad(self.p[aa + 1], x, y, z), self:grad(self.p[ba + 1], x - 1, y, z)), self:lerp(u, self:grad(self.p[ab + 1], x, y - 1, z), self:grad(self.p[bb + 1], x - 1, y - 1, z))), self:lerp(v, self:lerp(u, self:grad(self.p[ab + 2], x, y, z - 1), self:grad(self.p[ba + 2], x - 1, y, z - 1)), self:lerp(u, self:grad(self.p[ab + 2], x, y - 1, z - 1), self:grad(self.p[bb + 2], x - 1, y - 1, z - 1))))
    end,
    fade = function(self, t)
      return t * t * t * (t * (t * 6 - 15) + 10)
    end,
    lerp = function(self, t, a, b)
      return a + t * (b - a)
    end,
    grad = function(self, hash, x, y, z)
      local h, u, v
      h = hash % 16
      u = h < 8 and x or y
      v = h < 4 and y or ((h == 12 or h == 14) and x or z)
      return ((h % 2) == 0 and u or -u) + ((h % 3) == 0 and v or -v)
    end,
    generate = function(self, width, height)
      local grid
      grid = { }
      for j = 1, height do
        local temp
        temp = { }
        for i = 1, width do
          temp[i] = self:noise(j / 7, i / 7, math.random(15, 25) / 100)
        end
        grid[j] = temp
      end
      return grid
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, n)
      self.n = n
      self.p = { }
      self.permutation = { }
      for i = 1, self.n do
        self.permutation[#self.permutation + 1] = math.random(1, self.n)
      end
      self.gx = { }
      self.gy = { }
      self.randMax = self.n
      for i = 1, self.n do
        self.p[i] = self.permutation[i]
        self.p[self.n + i] = self.p[i]
      end
    end,
    __base = _base_0,
    __name = "Perlin"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Perlin = _class_0
end
return Perlin
