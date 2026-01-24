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

function mix(c1, c2, t) -- totally fucked up this function, too far in to care
  local it = (1.0 - t)
  return {
    c1[1]*t + c2[1]*it,
    c1[2]*t + c2[2]*it,
    c1[3]*t + c2[3]*it,
    c1[4]*t + c2[4]*it,
  }
end

local wisp_len = 10

game = game or { 
  tick = 0,

  wisp = {},

  sound = {
    clap = {},

  },
}

function game.load()
  game.sound.clap[1] = love.audio.newSource("audio/clap1.ogg", "static")
  game.sound.clap[2] = love.audio.newSource("audio/clap2.ogg", "static")
  game.sound.clap[3] = love.audio.newSource("audio/clap3.ogg", "static")
end

player = player or {
  x = view_w/2,
  y = view_h/2,

  foot_tick = 0,
  lfoot = {
    x = view_w/2,
    y = view_h/2,
    c = grey,
  },

  rfoot = {
    x = view_w/2,
    y = view_h/2,
    c = grey,
  },

  lhand = {
    x = 0,
    y = 0,
    c = indigo,
  },

  rhand = {
    x = 0,
    y = 0,
    c = indigo,
  },

  fpn = 60,
  fpi = 0,
  fp = {

  },

  xspd = 0,
  yspd = 0,

  xl = 1,
  yl = 1,
}

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

function make_rng(x, y)
  return love.math.newRandomGenerator(x * 0x505 + 0xDDD, y * 0xDDD + 0x505)
end

function rwave(rng, f)
  return math.sin(game.tick*f + math.pi*rng:random(100)/100)
end

clap = 0
clap_down = true
mouse_x, mouse_y = 0, 0
last_mdown = false
R = make_rng(87111, 87035)

target_stuff = 0

shift = 0

sunflowers = {

}

leafs = {

}

function game.sfx(src, pitch)
  local s = src:clone()
  local p = pitch or 1.0
  s:setPitch(p + R:random(-25, 25)/1000)
  s:setVolume(0.33)
  s:play()
end

function game.spawn_leaf(x,y,shift) 
  leafs[#leafs+1] = {
    h = R:random(2, 3),
    x = x,
    y = y,
    shift = shift,
    tick = game.tick,
  }
end

function game.spawn_wisp(x,y,c)
  game.wisp[#game.wisp+1] = { 
    x = x,
    y = y,
    tick = game.tick,
    life =  R:random(5, 10)*60,

    p = 0, px = {}, py = {},
    aX = R:random(150, 300)/100,
    aY = R:random(150, 300)/100,

    tx = math.lerp(R:random(0, view_w), player.x, 0.1),
    ty = math.lerp(R:random(0, view_h), player.y, 0.1),

    c = c,
    len = R:random(16, 40),
    shift = 0,
  }
end

function game.spawn_flower(x,y,shift)
  sunflowers[1+#sunflowers] = {
    x = x,
    y = y,
    tick = game.tick,
    life = 60,
    tlife = R:random(30, 40)*60,
    shift = shift, tshift = shift
  }
end

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

  clap = false
  if not clap_down and love.keyboard.isDown("space") then
    clap = true
    game.sfx(game.sound.clap[1+R:random(2)], 1.2)

    local cc = yellow
    if shift > 30 then
      cc = red
    end
    game.spawn_wisp(player.x, player.y-20, cc)
  end
  clap_down = love.keyboard.isDown("space")

  local spd = 1.0
  local accel = 0.25
  if (not (ix == 0)) and (not (iy == 0)) then
    spd = spd / math.sqrt(2)
  end

  player.xspd = math.approach(player.xspd, ix*spd, accel)
  player.yspd = math.approach(player.yspd, iy*spd, accel)

  player.x = player.x + player.xspd
  player.y = player.y + player.yspd

  local border = 10
  player.x = math.clamp(player.x, -border, view_w+border)
  player.y = math.clamp(player.y, 0, view_h+border*2)

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
      player.fp[player.fpi] = {
        x = player.rfoot.x,
        y = player.rfoot.y,
        c = player.rfoot.c,
        tick = game.tick
      };
      player.fpi = (player.fpi + 1) % player.fpn
      player.rfoot.c = mix(mix(red, yellow, shift/60), player.rfoot.c, 0.1)
    end
    if player.foot_tick % 12 == 6 then
      player.lfoot.x = player.x + player.xspd * 4 - 2
      player.lfoot.y = player.y + player.yspd * ystep
      player.fp[player.fpi] = {
        x = player.lfoot.x,
        y = player.lfoot.y,
        c = player.lfoot.c,
        tick = game.tick
      };
      player.fpi = (player.fpi + 1) % player.fpn
      player.lfoot.c = mix(mix(red, yellow, shift/60), player.lfoot.c, 0.1)
    end
    player.foot_tick = player.foot_tick + 1
  else 
    if ix == 0 and iy == 0 then
      local s = 0.5
      player.rfoot.x = math.lerp(player.rfoot.x, player.x +0.5*player.xl+1.5, s)
      player.rfoot.y = math.lerp(player.rfoot.y, player.y, s)
      player.lfoot.x = math.lerp(player.lfoot.x, player.x+0.5*player.xl-2.5 , s)
      player.lfoot.y = math.lerp(player.lfoot.y, player.y, s)
    end
  end 

  local i = 1
  local N = #sunflowers
  local T_shift = 0
  while i <= N do
    local o = sunflowers[i]

    T_shift = T_shift + o.shift

    if clap and (math.dist(o.x, o.y, player.x, player.y-10) < 30) then
      o.tshift = 1.0 - o.tshift
      o.tlife = math.lerp(o.life, game.tick-o.tick, 0.30) -- take away 30% of remaining life
    end

    o.shift = math.lerp(o.shift, o.tshift, 0.5)
    o.life = math.lerp(o.tlife, o.life, 0.5)

    if game.tick > o.tick+o.life then
      local r = R:random(100, 250) - (#sunflowers + #game.wisp)
      local c = yellow
      if o.shift < 0.5 then
        if r >= 100 then
          game.spawn_wisp(o.x, o.y, c)
        end
        if r >= 200 then
          game.spawn_wisp(o.x, o.y+1, c)
        end
      end

      sunflowers[i] = sunflowers[N]
      sunflowers[N] = nil
      N = N - 1
    else
      i = i + 1
    end
  end

  if T_shift > 0.5*N then
    shift = shift + 3
  else 
    shift = shift - 3
  end
  shift = math.clamp(shift, 0, 60)

  local i = 1
  local N = #game.wisp
  while i <= N do
    local wisp = game.wisp[i]

    local lt = (game.tick - wisp.tick)/wisp.life
    local st = math.clamp(lt * 4 - 3, 0, 1)

    local tx = player.x
    local ty = player.y
    local aY = wisp.aY

    if lt > 0.5 then
      tx = wisp.tx
      ty = wisp.ty
      aY = wisp.aX
    end

    wisp.p = (wisp.p + 1) % wisp.len
    wisp.px[wisp.p] = wisp.x
    wisp.py[wisp.p] = wisp.y

    wisp.x = math.lerp(wisp.x, tx, math.lerp(0.04, 0.6, st))
    wisp.y = math.lerp(wisp.y, ty, math.lerp(0.04, 0.6, st))

    local ax = wisp.aX*(1 - math.clamp(math.abs(wisp.x - wisp.px[wisp.p])/10, 0, 1))
    local ay = wisp.aY*(1 - math.clamp(math.abs(wisp.y - wisp.py[wisp.p])/10, 0, 1))

    ax = ax*(1 - st)
    ay = ay*(1 - st)

    wisp.x = wisp.x + ax*math.cos(0.01*aY*(game.tick+wisp.tick))
    wisp.y = wisp.y + ay*math.sin(0.01*wisp.aX*(game.tick+wisp.tick))

    if clap and (math.dist(wisp.x, wisp.y, player.x, player.y-10) < 30) then

      if game.tick > wisp.tick then
        if wisp.c == yellow then
          wisp.c = blue
        elseif wisp.c == blue then
          wisp.c = red
        elseif wisp.c == red then
          wisp.c = yellow
        end
      end

      wisp.aX = R:random(150, 300)/100
      wisp.aY = R:random(150, 300)/100
    end 

    if game.tick > wisp.tick+wisp.life then

      -- spawn a thing
      if wisp.c == yellow then
        game.spawn_flower(wisp.x, wisp.y, 0.0)
      end
      if wisp.c == red then
        game.spawn_flower(wisp.x, wisp.y, 1.0)
      end
      if wisp.c == blue then
        game.spawn_leaf(wisp.x, wisp.y, math.clamp(math.floor(0.5+(shift/60)), 0, 1))
      end

      game.wisp[i] = game.wisp[N]
      game.wisp[N] = nil
      N = N - 1
    else
      i = i + 1
    end
  end
end

function game.draw_player()
  -- footprints
  for i = 0, player.fpn do
    local fp = player.fp[i]
    if fp then
      love.graphics.setColor(fp.c)
      depth_shader:send("z", fp.y-10)
      local t = math.clamp((game.tick - fp.tick)/360, 0, 2)
      local it2 = (1-0.5*t)
      love.graphics.rectangle("fill", fp.x-1, fp.y-2 - 10*t, 3*it2, 2*it2)          
    end
  end


  local width = 9
  local height = 18

  local x = math.floor(player.x+0.5)
  local y = math.floor(player.y+0.5)

  local c1 = mix(black, white, 2*shift/60)
  local c2 = mix(red, black, 2*shift/60)
  local c3 = mix(red, yellow, 2*shift/60)
  local c4 = mix(red, brown, 2*shift/60)

  depth_shader:send("z", y)

  -- legs
  love.graphics.setColor(c1)
  local legy = y - 8
  local rx = x+0.5*player.xl+1.5
  local lx = x+0.5*player.xl-2.5
  love.graphics.polygon("fill", {rx - 1, legy, rx + 1, legy, player.rfoot.x + 1, player.rfoot.y, player.rfoot.x - 1, player.rfoot.y})
  love.graphics.polygon("fill", {lx - 1, legy, lx + 1, legy, player.lfoot.x + 1, player.lfoot.y, player.lfoot.x - 1, player.lfoot.y})

  love.graphics.setColor(c4)
  love.graphics.rectangle("fill", x - width/2, y - height + 1, width, 10)

  love.graphics.setColor(c2)
  love.graphics.rectangle("fill", x - 3.5 + 0.5*player.xl, y - height, 6, 4)

  love.graphics.setColor(c1)
  love.graphics.rectangle("fill", x - 2.5 + 0.5*player.xl, y - height + 4, 4, 8)

  love.graphics.rectangle("fill", x - 2.5 + 0.5*player.xl, y - height - 1, 4, 4)

  -- hands
  if clap_down then
    player.rhand.y = -height 
    player.rhand.x = -1 + 1.5 + 4*player.xl - 0.5*(1-player.xl)

    player.lhand.y = -height
    player.lhand.x = -1 - 1.5 + 4*player.xl + 0.5*(1+player.xl)

    local handc = c3
    player.rhand.c = handc
    player.lhand.c = handc
  else
    player.rhand.x = math.approach(player.rhand.x, -1.5 + 6, 1)
    player.rhand.y = math.approach(player.rhand.y, -height/2, 1)
    player.rhand.c = c1

    player.lhand.x = math.approach(player.lhand.x, -0.5 - 6, 1)
    player.lhand.y = math.approach(player.lhand.y, -height/2, 1)
    player.lhand.c = c1
  end

  love.graphics.setColor(player.rhand.c)
  love.graphics.rectangle("fill", x + player.rhand.x, y + player.rhand.y, 2, 3 + 2*(clap_down and 1 or 0))
  love.graphics.setColor(player.lhand.c)
  love.graphics.rectangle("fill", x + player.lhand.x, y + player.lhand.y, 2, 3 + 2*(clap_down and 1 or 0))

  love.graphics.setColor(1, 1, 1, 1)
end

function game.draw_flower(sunflower)
  local x = sunflower.x
  local y = sunflower.y

  depth_shader:send("z", y)

  local shy = shift/60
  shy = math.lerp(shy, 1 - shy, sunflower.shift)
  local rng = make_rng(x, y)

  local ti = ((game.tick - sunflower.tick))/sunflower.life
  ti = math.clamp(ti, 0, 1)
  local gt = math.clamp(5*ti, 0, 1)
  local dt = 1.0-math.clamp(9*ti - 8, 0, 1)
  local wt = 1.0-math.clamp(9*ti - 6, 0, 1)

  local tt = gt*dt

  local h = dt*tt*rng:random(35, 45) + 2*rwave(rng, rng:random(10, 20)/1000)
  local x1, y1 = x + tt*rng:random(-3, 3), y - h * rng:random(20, 30)/100.
  local x2, y2 = x + tt*rng:random(-3, 3) + 2*rwave(rng, 0.01), y - h * rng:random(55, 65)/100.
  local x3, y3 = x + tt*rng:random(-4, 4) + 4*rwave(rng, 0.02), y - h

  local d = math.dist(x, y, player.x, player.y)
  local dmin = 5
  local dmax = 80

  local t = math.clamp(1.0 - ((d - dmin)/(dmax - dmin)), 0., 1.)
  t = t*t

  x2 = math.lerp(x2, player.x, -0.2*t*tt)
  y2 = math.lerp(y2, player.y, -0.2*t*tt)

  x3 = math.lerp(x3, player.x, 0.3*t*gt*wt)
  y3 = math.lerp(y3, player.y, 0.3*t*gt*wt)

  local ry = rng:random(7, 9)
  local rx = ry * rng:random(85, 95)/100.
  ry = ry*math.lerp(0.75, 1.0, math.clamp(2.0*wt, 0, 1))

  local cw = mix(black, grey, shift/60)
  local c0 = mix(mix(green, cw, wt), indigo, tt)
  local c1 = mix(mix(yellow, brown, gt), cw, wt)
  local c2 = mix(mix(brown, cw, wt), indigo, tt)
  local c3 = mix(black, black, tt)
  local c4 = c3
  c0 = mix(mix(mix(purple, navy, wt), indigo, tt), c0, shy)
  c1 = mix(mix(mix(red, purple, gt*wt), indigo, tt), c1, shy)
  c2 = mix(c1, c2, shy) 
  c3 = mix(black, c3, shy)
  c4 = mix(mix(yellow, indigo, math.clamp(4*tt, 0, 1)), c4, 2*shy)
  -- c1, c2, c3, c4 = red, red, black, yellow

  love.graphics.setColor(c0)
  love.graphics.line(
    x, y,
    x1, y1,
    x2, y2,
    x3, y3
  )
  if tt > 0.5 then
    love.graphics.line(    
      x+tt, y,
      math.lerp(x1-tt, x2, tt*rng:random(10, 20)/100.), y1,
      math.lerp(x2+tt, x3, tt*rng:random(10, 25)/100.), y2,
      x3-tt, y3
    )
  end

  love.graphics.setColor(c1) 
  local deg2rad = math.pi/180
  local N = math.floor(ry) + rng:random(2)
  local dir = rng:random(-15, 15)*deg2rad + rwave(rng, 0.00505)
  local step = 2*math.pi/N
  for i = 0, N, 1 do
    local l = gt*wt*(ry + rng:random(50, 60)/10.)
    local la = rng:random(50, 70)*deg2rad/2
    love.graphics.polygon("fill", 
      x3 + l*math.cos(dir), y3 + l*math.sin(dir),
      x3 + 0.4*l*math.cos(dir-la), y3 + 0.5*l*math.sin(dir-la), 
      x3 + 0.4*l*math.cos(dir+la), y3 + 0.5*l*math.sin(dir+la)
    )
    dir = dir + step
  end

  local x4 = math.approach(x3 + tt*0.5*rwave(rng, 0.02), player.x, 2.*t*gt*wt)
  local y4 = math.approach(y3 + tt*0.5*rwave(rng, 0.025), player.y, 2.*t*gt*wt)

  local x5 = math.approach(x4, player.x, 5*t*gt*wt)
  local y5 = math.approach(y4, player.y- 15, 5*t*gt*wt)

  love.graphics.setColor(c2)
  local ss = math.lerp(0.25, 1.0, tt)
  love.graphics.ellipse("fill", x3, y3, ss*rx, ss*ry)

  love.graphics.setColor(c3)
  local sss = tt*gt*0.65
  love.graphics.ellipse("fill", x4, y4, sss*rx, sss*ry)
  love.graphics.ellipse("fill", x4+1, y4, sss*rx, sss*ry)
  love.graphics.ellipse("fill", x4-1, y4, sss*rx, sss*ry)
  love.graphics.ellipse("fill", x4, y4+1, sss*rx, sss*ry)
  love.graphics.ellipse("fill", x4, y4-1, sss*rx, sss*ry)

  love.graphics.setColor(c4)
  love.graphics.line(x5, y5-2, x5, y5+2)

  love.graphics.setColor(1, 1, 1, 1)
end


function game.draw_bigleaf(leaf)
  local X = leaf.x
  local Y = leaf.y
  local rng = make_rng(X, Y)
  local deg2rad = math.pi/180

  local base_angle = -deg2rad*( rng:random(-30, 30) )
  local bx = math.cos(base_angle)
  local by = math.sin(base_angle) 

  local ht = leaf.h/4

  local gt = math.clamp((game.tick - leaf.tick)/60, 0, 1)

  local s = rng:random(10, 15)
  local h = rng:random(20, 30)

  function draw_leaf(i, j, a)
    local x = X + i*bx - j*by
    local y = Y + i*by + j*bx

    local shy = shift/60

    local c1
    local c2 = mix(grey, black, shift/60)
    local c3 = mix(indigo, blue, shy)
    if (x + y) % 16 < 4 then 
      c1 = mix(purple, indigo, shy)
      depth_shader:send("z", y-15)
    else  
      c1 = mix(brown, navy, shy)
      depth_shader:send("z", y-30)
    end

    c1 = mix(c1, c2, math.clamp(5*gt, 0, 1))

    local angle = base_angle - deg2rad*(90+a+rng:random(-10, 10))
    local arc = deg2rad*rng:random(10, 15)

    local ax = math.cos(angle)
    local ay = math.sin(angle)

    local r1 = rng:random(4, 7) + (- math.abs(a))/30
      r1 = r1 * math.clamp(game.tick - leaf.tick - 2*j, 0, 30)/30
    local r2 = r1 * rng:random(75, 85)/100

    local o2 = rng:random(-20, 20)/10.
    local x1 = x - 0.8*r1*ax + o2*ay
    local y1 = y - 0.8*r2*ay - o2*ax

    if (math.dist(x1, y1, player.rfoot.x, player.rfoot.y) < r1)
    or (math.dist(x1, y1, player.lfoot.x, player.lfoot.y) < r1)
     then
      player.rfoot.c = c3
      player.lfoot.c = c3

      c2 = c1
      c1 = c3

      y = y + 2
      y1 = y1 + 1
    end

    if math.dist(x1, y1, player.x, player.y) < r1*2 then
      if clap then
        leaf.h = leaf.h - 1

        local r = rng:random(100) + (#leafs + #game.wisp)
        if r < 35 then
          if shift > 30 then
            game.spawn_wisp(x1, y1, red)
          else
            game.spawn_wisp(x1, y1, blue)
          end
        end
      end
    end

    love.graphics.setColor(c2)
    love.graphics.circle("fill", x, y+1, r1, 10)

    love.graphics.setColor(c1)
    love.graphics.arc("fill", x, y, r1, angle+arc, angle+2*(math.pi - arc), 10)
    love.graphics.circle("fill", x1, y1, r2, 10)
  end

  for j = 0, h*ht, 0.8*s do
    local w = 12*(h-j)/h

    local o = rng:random(-5, 5)
    for i = -w, w, 12 do
      draw_leaf(i+o, j, 2*i+3*o)
    end
  end

  love.graphics.setColor(1, 1, 1, 1)
end

function game.draw_wisp(wisp)
  depth_shader:send("z", wisp.y+8)

  local lt = (game.tick - wisp.tick)/wisp.life
  local st = math.clamp(lt * 4 - 3, 0, 1) 

  local shy = shift/60
  shy = math.lerp(shy, 1 - shy, wisp.shift)

  for i = 0, wisp_len-2, 1 do
   love.graphics.setColor(mix(black, wisp.c, st))
    local I = (wisp.p + wisp.len - i) % wisp.len
    local J = (wisp.p + wisp.len - i-1) % wisp.len
    if wisp.px[I] and wisp.px[J] then
      love.graphics.line(wisp.px[I], wisp.py[I], wisp.px[J], wisp.py[J])
    end
  end
  
  if wisp.p > 0 then
    love.graphics.circle("fill", wisp.px[wisp.p], wisp.py[wisp.p], 3, 5)
  end

  love.graphics.setColor(mix(indigo, white, shy+st))
  love.graphics.circle("fill", wisp.x, wisp.y, 2, 6)
  love.graphics.setColor(1, 1, 1, 1)
end

function game.draw()
  love.graphics.clear(mix(grey, black, shift/60))

  love.graphics.setLineStyle("rough")

  local i = 1
  local N = #leafs
  while i <= N do 
    game.draw_bigleaf(leafs[i])

    if leafs[i].h <= 0 then
      leafs[i] = leafs[#leafs]
      leafs[#leafs] = nil
      N = N - 1
    else
      i = i + 1
    end
  end

  for i = 1, #sunflowers do 
    game.draw_flower(sunflowers[i])
  end

  game.draw_player()

  for i = 1, #game.wisp do
    game.draw_wisp(game.wisp[i])
  end


end

return game