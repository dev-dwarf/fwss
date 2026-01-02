
function math.clamp(v, min, max)
  if v < min then return min end
  if v > max then return max end
  return v
end

local game = { }
local x = view_w/2
local y = 200
local speed = 200

function game.update(dt)
  if love.keyboard.isDown("left")  then x = x - speed * dt end
  if love.keyboard.isDown("right") then x = x + speed * dt end
  if love.keyboard.isDown("up")    then y = y - speed * dt end
  if love.keyboard.isDown("down")  then y = y + speed * dt end

  x = math.clamp(x, 0, view_w)
  y = math.clamp(y, 0, view_h)

end

function game.draw()
  love.graphics.setColor( love.keyboard.isDown("space") and white or red)
  love.graphics.rectangle("fill", x-5, y-10, 10, 10)
  love.graphics.setColor(1, 1, 1, 1)
end

return game