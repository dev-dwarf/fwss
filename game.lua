

white  = color(0xFFFFF7FF)
black  = color(0x0A030DFF)
indigo = color(0x230C45FF)
navy   = color(0x192669FF)
green  = color(0x004D57FF)
pink   = color(0xFF6DEBFF)
red    = color(0xFF0059FF)
purple = color(0x7D2160FF)
brown  = color(0x96531DFF)
grey   = color(0x797366FF)
yellow = color(0xFFCF00FF)
blue   = color(0x2CE8F4FF)

function math.clamp(v, min, max)
  if v < min then return min end
  if v > max then return max end
  return v
end

function math.dist(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end

function math.approach(a, b, s)
  if a < b then 
    return math.min(a+s, b)
  else
    return math.max(a-s, b)
  end
end

function math.lerp(a, b, x)
  return x*b + (1-x)*a
end

local game = { 
  tick = 0
}

local player = {
  x = view_w/2,
  y = view_h/2,

  foot_tick = 0,
  lfoot = {
    x = view_w/2,
    y = view_h/2,
  },

  rfoot = {
    x = view_w/2,
    y = view_h/2,
  },

  xspd = 0,
  yspd = 0,

  xl = 1,
  yl = 1,
}

mouse_x, mouse_y = 0, 0
function game.update(dt)
  love.graphics.push()
  love.graphics.scale(window_scale, window_scale)
  mouse_x, mouse_y = love.graphics.inverseTransformPoint(love.mouse.getPosition())
  love.graphics.pop()

  game.tick = game.tick + 1

  local ix = 0
  local iy = 0
  if love.keyboard.isDown("a", "left") then ix = ix - 1 end
  if love.keyboard.isDown("d", "right") then ix = ix + 1 end
  if love.keyboard.isDown("w", "up") then iy = iy - 1 end
  if love.keyboard.isDown("s", "down") then iy = iy + 1 end

  local spd = 1.0
  local accel = 0.25
  if (not (ix == 0)) and (not (iy == 0)) then
    spd = spd / math.sqrt(2)
  end

  player.xspd = math.approach(player.xspd, ix*spd, accel)
  player.yspd = math.approach(player.yspd, iy*spd, accel)

  player.x = player.x + player.xspd
  player.y = player.y + player.yspd

  -- visuals
  if not (ix == 0) then
    player.xl = ix
  end
  if not (iy == 0) then
    player.yl = iy
  end
  if (not (ix == 0)) or (not (iy == 0)) then
    local ystep = 2
    if player.yspd < 0 then ystep = 4 end

    if player.foot_tick % 12 == 0 then
      player.rfoot.x = player.x + player.xspd * 4 + 2
      player.rfoot.y = player.y + player.yspd * ystep
    end
    if player.foot_tick % 12 == 6 then
      player.lfoot.x = player.x + player.xspd * 4 - 2
      player.lfoot.y = player.y + player.yspd * ystep
    end
    player.foot_tick = player.foot_tick + 1
  else 
    if ix == 0 and iy == 0 then
      local s = 0.5
      player.rfoot.x = math.lerp(player.rfoot.x, player.x + 0.5*player.xl + 2, s)
      player.rfoot.y = math.lerp(player.rfoot.y, player.y, s)
      player.lfoot.x = math.lerp(player.lfoot.x, player.x + 0.5*player.xl - 2, s)
      player.lfoot.y = math.lerp(player.lfoot.y, player.y, s)
    end
  end 


end

function game.draw_player()
  local width = 9
  local height = 18

  local x = math.floor(player.x+0.5)
  local y = math.floor(player.y+0.5)

  depth_shader:send("z", y)

  -- legs
  love.graphics.setColor(white)
  local legy = y - 8
  local lx = x+0.5*player.xl-2
  local rx = x+0.5*player.xl+2
  love.graphics.polygon("fill", {rx - 1, legy, rx + 1, legy, player.rfoot.x + 1, player.rfoot.y, player.rfoot.x - 1, player.rfoot.y})
  love.graphics.polygon("fill", {lx - 1, legy, lx + 1, legy, player.lfoot.x + 1, player.lfoot.y, player.lfoot.x - 1, player.lfoot.y})

  love.graphics.setColor(brown)
  love.graphics.rectangle("fill", x - width/2, y - height + 1, width, 10)

  love.graphics.setColor(black)
  love.graphics.rectangle("fill", x - 3.5 + 0.5*player.xl, y - height, 6, 4)


  love.graphics.setColor(white)
  love.graphics.rectangle("fill", x - 2.5 + 0.5*player.xl, y - height + 4, 4, 8)

  love.graphics.rectangle("fill", x - 2.5 + 0.5*player.xl, y - height - 1, 4, 4)

  -- hands
  love.graphics.rectangle("fill", x - 1.5 + 6 - 0*player.xl, y - height/2, 3, 2)
  love.graphics.rectangle("fill", x - 1.5 - 6 - 0*player.xl, y - height/2, 3, 2)

  love.graphics.setColor(1, 1, 1, 1)
end

function make_rng(x, y)
  return love.math.newRandomGenerator(x * 0x505 + 0xDDD, y * 0xDDD + 0x505)
end

function rwave(rng, f)
  return math.sin(game.tick*f + math.pi*rng:random(100)/100)
end

function game.draw_flower(x, y)
  depth_shader:send("z", y)

  local rng = make_rng(x, y)

  local h = rng:random(35, 45) + 2*rwave(rng, rng:random(10, 20)/1000)
  local x1, y1 = x + rng:random(-3, 3), y - h * rng:random(20, 30)/100.
  local x2, y2 = x + rng:random(-3, 3) + 2*rwave(rng, 0.01), y - h * rng:random(55, 65)/100.
  local x3, y3 = x + rng:random(-4, 4) + 4*rwave(rng, 0.02), y - h

  local d = math.dist(x, y, player.x, player.y)
  local dmin = 5
  local dmax = 80

  local t = math.clamp(1.0 - ((d - dmin)/(dmax - dmin)), 0., 1.)
  t = t*t

  x2 = math.lerp(x2, player.x, -0.2*t)
  y2 = math.lerp(y2, player.y, -0.2*t)

  x3 = math.lerp(x3, player.x, 0.3*t)
  y3 = math.lerp(y3, player.y, 0.3*t)

  local ry = rng:random(7, 9)
  local rx = ry * rng:random(85, 95)/100.

  love.graphics.setLineStyle( "rough" )
  love.graphics.setColor(green)
  love.graphics.line(
    x, y,
    x1, y1,
    x2, y2,
    x3, y3
  )
  love.graphics.line(    
    x+1, y,
    math.lerp(x1-1, x2, rng:random(10, 20)/100.), y1,
    math.lerp(x2+1, x3, rng:random(10, 25)/100.), y2,
    x3-1, y3
  )

  love.graphics.setColor(yellow)
  local deg2rad = math.pi/180
  local N = math.floor(ry) + rng:random(2)
  local dir = rng:random(-15, 15)*deg2rad + rwave(rng, 0.00505)
  local step = 2*math.pi/N
  for i = 0, N, 1 do
    local l = ry + rng:random(50, 60)/10.
    local la = rng:random(50, 70)*deg2rad/2
    love.graphics.polygon("fill", 
      x3 + l*math.cos(dir), y3 + l*math.sin(dir),
      x3 + 0.4*l*math.cos(dir-la), y3 + 0.5*l*math.sin(dir-la), 
      x3 + 0.4*l*math.cos(dir+la), y3 + 0.5*l*math.sin(dir+la)
    )
    dir = dir + step
  end

  local x4 = math.approach(x3 + 0.5*rwave(rng, 0.02), player.x, 2.*t)
  local y4 = math.approach(y3 + 0.5*rwave(rng, 0.025), player.y, 2.*t)

  love.graphics.setColor(brown)
  love.graphics.ellipse("fill", x3, y3, rx, ry)

  love.graphics.setColor(black)
  love.graphics.ellipse("fill", x4, y4, 0.65*rx, 0.65*ry)
  love.graphics.ellipse("fill", x4+1, y4, 0.65*rx, 0.65*ry)
  love.graphics.ellipse("fill", x4-1, y4, 0.65*rx, 0.65*ry)
  love.graphics.ellipse("fill", x4, y4+1, 0.65*rx, 0.65*ry)
  love.graphics.ellipse("fill", x4, y4-1, 0.65*rx, 0.65*ry)


  love.graphics.setColor(1, 1, 1, 1)
end


function game.draw_bigleaf(X, Y)
  local rng = make_rng(X, Y)
  local deg2rad = math.pi/180

  local base_angle = -deg2rad*( rng:random(-30, 30) )
  local bx = math.cos(base_angle)
  local by = math.sin(base_angle) 

  function draw_leaf(i, j, a)
    local x = X + i*bx - j*by
    local y = Y + i*by + j*bx

    local c1
    if (x + y) % 16 < 4 then 
      c1 = indigo 
      depth_shader:send("z", y)
    else 
      c1 = navy
      depth_shader:send("z", y-16)
    end
    local c2 = black

    local angle = base_angle - deg2rad*(90+a+rng:random(-10, 10))
    local arc = deg2rad*rng:random(10, 15)

    local ax = math.cos(angle)
    local ay = math.sin(angle)

    local r1 = rng:random(8, 10) + (- math.abs(a))/30
    local r2 = r1 * rng:random(75, 85)/100

    local o2 = rng:random(-20, 20)/10.
    local x1 = x - 0.8*r1*ax + o2*ay
    local y1 = y - 0.8*r2*ay - o2*ax

    if (math.dist(x1, y1, player.rfoot.x, player.rfoot.y) < r1)
    or (math.dist(x1, y1, player.lfoot.x, player.lfoot.y) < r1)
     then
      c2 = c1
      c1 = blue

      y = y + 2
      y1 = y1 + 1
    end

    if c2 == black then
      love.graphics.setColor(black)
      love.graphics.circle("fill", x, y+1, r1, 10)
      -- love.graphics.circle("fill", x1, y1+1, r1, 10)
    end

    love.graphics.setColor(c1)
    love.graphics.arc("fill", x, y, r1, angle+arc, angle+2*(math.pi - arc), 10)
    love.graphics.circle("fill", x1, y1, r2, 10)
  end

  local s = rng:random(18, 25)
  local h = rng:random(40, 50)

  for j = 0, h, 0.8*s do
    local w = 18*(h-j)/h

    local o = rng:random(-5, 5)
    for i = -w, w, 18 do
      draw_leaf(i+o, j, 2*i+3*o)
    end
  end

  love.graphics.setColor(1, 1, 1, 1)
end

function game.draw()

  game.draw_flower(100, view_h/2)
  game.draw_flower(60, view_h/2)


  game.draw_flower(140, view_h/2)
  game.draw_flower(180, view_h/2)

  for j = view_h - 200, view_h, 100 do 
  for i = 0, view_w, 100 do
    game.draw_bigleaf(i, j)
  end
  end

  game.draw_bigleaf(mouse_x, mouse_y)


  game.draw_player()

end

return game