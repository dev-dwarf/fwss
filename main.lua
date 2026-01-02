-- Optional: simple conf embedded (LÖVE allows it if no conf.lua)
function love.conf(t)
  t.window.title = "FWSS"
end

local lurker = require "lurker"

function color(hex)
  c =  {
    (math.floor((hex / 0x01000000)) % 0x100) / 0xFF,
    (math.floor((hex / 0x00010000)) % 0x100) / 0xFF,
    (math.floor((hex / 0x00000100)) % 0x100) / 0xFF,
    (math.floor((hex / 0x00000001)) % 0x100) / 0xFF
  }
  print(hex)
  for index, value in ipairs(c) do
    print(value)
  end
  return c
end

local white  = color(0xFFFFF7FF)
local black  = color(0x0A030DFF)
local indigo = color(0x230C45FF)
local navy   = color(0x192669FF)
local green  = color(0x004D57FF)
local pink   = color(0xFF6DEBFF)
local red    = color(0xFF0059FF)
local purple = color(0x7D2160FF)
local brown  = color(0x96531DFF)
local grey   = color(0x797366FF)
local yellow = color(0xFFCF00FF)
local blue   = color(0x2CE8F4FF)

local game_w = 256
local game_h = 256
local window_scale = 3
local canvas
function love.load()
  love.window.setMode( game_w*window_scale, game_h*window_scale, {})
  love.graphics.setDefaultFilter("nearest", "nearest")
  love.graphics.setBackgroundColor(black)
  canvas = love.graphics.newCanvas(game_w, game_h)
end

local x = game_w/2
local y = 200
local speed = 200

function love.update(dt)
  lurker.update() 

  if love.keyboard.isDown("left")  then x = x - speed * dt end
  if love.keyboard.isDown("right") then x = x + speed * dt end
  if love.keyboard.isDown("up")    then y = y - speed * dt end
  if love.keyboard.isDown("down")  then y = y + speed * dt end

  x = math.clamp(x, 0, love.graphics.getWidth())
  y = math.clamp(y, 0, love.graphics.getHeight())
end

function love.draw()
  -- draw game world to canvas
  love.graphics.setCanvas(canvas)
  love.graphics.clear()
  love.graphics.setColor(red)
  love.graphics.circle("fill", x, y, 50)
  love.graphics.setColor(1, 1, 1)

  -- TODO apply shaders here
  love.graphics.setCanvas()
  love.graphics.draw(canvas, 0, 0, 0, window_scale, window_scale)

  love.graphics.print(string.format("avg frame: %.3f ms", 1000 * love.timer.getAverageDelta()), 10, 10)
end

-- Helper
function math.clamp(v, min, max)
  if v < min then return min end
  if v > max then return max end
  return v
end