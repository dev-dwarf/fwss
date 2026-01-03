
function math.clamp(v, min, max)
  if v < min then return min end
  if v > max then return max end
  return v
end

function math.approach(a, b, s)
  if a < b then 
    return math.min(a+s, b)
  else
    return math.max(a-s, b)
  end
end

function math.lerp(a, b, x)
  return x*a + (1-x)*b
end

local game = { 
  tick = 0
}

local player = {
  x = view_w/2,
  y = view_h/2,

  foot_tick = 0,
  lfoot = {
    x = 0,
    y = 0,
  },

  rfoot = {
    x = 0,
    y = 0,
  },

  xspd = 0,
  yspd = 0,

  xl = 1,
  yl = 1,
}


function game.update(dt)
  game.tick = game.tick + 1

  local ix = 0
  local iy = 0
  if love.keyboard.isDown("left") then ix = ix - 1 end
  if love.keyboard.isDown("right") then ix = ix + 1 end
  if love.keyboard.isDown("up") then iy = iy - 1 end
  if love.keyboard.isDown("down") then iy = iy + 1 end

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

  -- legs
  love.graphics.setColor(white)
  local legy = y - height/4
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

--   love.graphics.setColor(red)
--   love.graphics.circle("fill", player.rfoot.x, player.rfoot.y, 2)
--   love.graphics.setColor(blue)
--   love.graphics.circle("fill", player.lfoot.x, player.lfoot.y, 2)

  love.graphics.setColor(1, 1, 1, 1)


end

function game.draw()
  game.draw_player()
end

return game