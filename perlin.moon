class Perlin
  new: (@n) =>
    @p = {}
    @permutation = {}
    for i = 1, @n
      @permutation[#@permutation+1] = math.random(1, @n)

    @gx = {}
    @gy = {}
    @randMax = @n

    for i = 1, @n
      @p[i] = @permutation[i]
      @p[@n+i] = @p[i]

  noise: (x, y, z) =>
    local a, aa, ab, b, ba, bb, u, v, w, _x, _y, _z
    _x = math.floor(x) % @n
    _y = math.floor(y) % @n
    _z = math.floor(z) % @n
    x = x - math.floor x
    y = y - math.floor y
    z = z - math.floor z
    u = @fade x
    v = @fade y
    w = @fade z
    a = @p[_x + 1] + _y
    aa = @p[a + 1] + _z
    ab = @p[a + 2] + _z
    b = @p[_x + 2] + _y
    ba = @p[b + 1] + _z
    bb = @p[b + 2] + _z

    return @lerp(w, @lerp(v, @lerp(u, @grad(@p[aa+1], x  , y  , z  ),
                                      @grad(@p[ba+1], x-1, y  , z  )),
                             @lerp(u, @grad(@p[ab+1], x  , y-1, z  ),
                                      @grad(@p[bb+1], x-1, y-1, z  ))),
                    @lerp(v, @lerp(u, @grad(@p[ab+2], x  , y  , z-1),
                                      @grad(@p[ba+2], x-1, y  , z-1)),
                             @lerp(u, @grad(@p[ab+2], x  , y-1, z-1),
                                      @grad(@p[bb+2], x-1, y-1, z-1))))

  fade: (t) =>
    return t * t * t * (t * (t * 6 - 15) + 10)

  lerp: (t, a, b) =>
    return a + t * (b - a)

  grad: (hash, x, y, z) =>
    local h, u, v
    h = hash % 16
    u = h < 8 and x or y
    v = h < 4 and y or ((h == 12 or h == 14) and x or z)
    return ((h % 2) == 0 and u or -u) + ((h % 3) == 0 and v or -v)

  generate: (width, height) =>
    local grid
    grid = {}
    for j = 1, height
      local temp
      temp = {}
      for i = 1, width
        temp[i] = @noise j / 7, i / 7, math.random(15,25)/100
      grid[j] = temp
    return grid

return Perlin