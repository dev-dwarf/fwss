-- Optional: simple conf embedded (LÖVE allows it if no conf.lua)
function love.conf(t)
  t.window.title = "FWSS"
end

local lurker = require "lurker"

function color(hex)
  return {
    (math.floor((hex / 0x01000000)) % 0x100) / 0xFF,
    (math.floor((hex / 0x00010000)) % 0x100) / 0xFF,
    (math.floor((hex / 0x00000100)) % 0x100) / 0xFF,
    (math.floor((hex / 0x00000001)) % 0x100) / 0xFF
  }
end

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

view_w = 224
view_h = 224
local kw_w = 256
local kw_h = 256
local kw_x = 0.5*(kw_w - view_w)
local kw_y = 0.5*(kw_h - view_h)
local window_scale = 4
local canvas

local game = require "game"

local down_shader, up_shader
local down_shader_code = [[
extern vec2 txl;
extern number offset;

vec4 effect(vec4 col, Image tex, vec2 tc, vec2 sc) {
    vec2 halfpixel = txl * 0.5;
    vec2 o = halfpixel * offset;

    vec4 sum = Texel(tex, tc) * 4.0;
    sum += Texel(tex, tc + vec2(-o.x, -o.y));
    sum += Texel(tex, tc + vec2( o.x, -o.y));
    sum += Texel(tex, tc + vec2(-o.x,  o.y));
    sum += Texel(tex, tc + vec2( o.x,  o.y));

    return sum / 8.0;
}
]]

local up_shader_code = [[
extern vec2 txl;
extern number offset;

vec4 effect(vec4 col, Image tex, vec2 tc, vec2 sc) {
    vec2 halfpixel = txl * 0.5;
    vec2 o = halfpixel * offset;

    vec4 sum = vec4(0.0);
    sum += Texel(tex, tc + vec2(-o.x * 2.0, 0.0));
    sum += Texel(tex, tc + vec2( o.x * 2.0, 0.0));
    sum += Texel(tex, tc + vec2(0.0, -o.y * 2.0));
    sum += Texel(tex, tc + vec2(0.0,  o.y * 2.0));
    sum += Texel(tex, tc + vec2(-o.x,  o.y)) * 2.0;
    sum += Texel(tex, tc + vec2( o.x,  o.y)) * 2.0;
    sum += Texel(tex, tc + vec2(-o.x, -o.y)) * 2.0;
    sum += Texel(tex, tc + vec2( o.x, -o.y)) * 2.0;

    return sum / 12.0;
}
]]

local kw_buf = {}
local levels = 4  -- adjust for blur strength (3-6 typical)
local offset = 1.0
local bloom = 1.0

function love.load()
  love.window.setMode( view_w*window_scale, view_h*window_scale, {})
  love.graphics.setBackgroundColor(black)
  love.graphics.setDefaultFilter("nearest", "nearest")
  canvas = love.graphics.newCanvas(kw_w, kw_h)

  down_shader = love.graphics.newShader(down_shader_code)
  up_shader = love.graphics.newShader(up_shader_code)

  local cur_w, cur_h = kw_w, kw_h
  for i = 1, levels do
    kw_buf[i] = love.graphics.newCanvas(cur_w, cur_h)
    kw_buf[i]:setFilter("linear", "linear")
    cur_w = math.max(1, math.floor(cur_w / 2))
    cur_h = math.max(1, math.floor(cur_h / 2))
  end
end

function love.update(dt)
  lurker.update() 

  game.update(dt)
end

function love.draw()
  -- draw game world to canvas

  love.graphics.setCanvas(canvas)
  love.graphics.push()
  love.graphics.translate(kw_x, kw_y)
  love.graphics.clear(0, 0, 0, 0)
  game.draw()
  love.graphics.pop()

  -- Dual Kawase blur
  local source = kw_buf[1]
  love.graphics.setCanvas(source)

  -- NOTE(lf): only partially clearing kawase buffer to get temporal blur
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("fill", 0, 0, kw_w, kw_h)
  love.graphics.setColor(1, 1, 1, 1)

  love.graphics.draw(canvas, 0, 0, 0, 1, 1) -- todo adjust to pad game view 

  for i = 2, levels do
    local target = kw_buf[i]
    love.graphics.setCanvas(target)
    love.graphics.clear(0, 0, 0, 1)
    local tw, th = target:getDimensions()
    local sw, sh = source:getDimensions()
    down_shader:send("txl", {1 / tw, 1 / th})
    down_shader:send("offset", offset)
    love.graphics.setShader(down_shader)
    love.graphics.draw(source, 0, 0, 0, tw / sw, th / sh)
    source = target
  end

  for i = levels - 1, 1, -1 do
    local target = kw_buf[i]
    love.graphics.setCanvas(target)
    local tw, th = target:getDimensions()
    local sw, sh = source:getDimensions()
    up_shader:send("txl", {1 / sw, 1 / sh})
    up_shader:send("offset", offset)
    love.graphics.setShader(up_shader)
    love.graphics.draw(source, 0, 0, 0, tw / sw, th / sh)
    source = target
  end
  love.graphics.setShader()

  love.graphics.setCanvas()
  love.graphics.push()
  love.graphics.scale(window_scale, window_scale)
  love.graphics.translate(-kw_x, -kw_y)

  love.graphics.clear(black)

  love.graphics.draw(canvas, 0, 0)

  love.graphics.setBlendMode("add")
  love.graphics.setColor(bloom, bloom, bloom, 1)
  love.graphics.draw(kw_buf[1], 0, 0)
  love.graphics.setBlendMode("alpha")

  love.graphics.pop()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print(string.format("avg frame: %.3f ms", 1000 * love.timer.getAverageDelta()), 10, 10)
end

