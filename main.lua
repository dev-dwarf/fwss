
if love.system.getOS() == "Linux" then
  lurker = require "lurker"
end

require "conf"

function color(hex)
  return {
    (math.floor((hex / 0x01000000)) % 0x100) / 0xFF,
    (math.floor((hex / 0x00010000)) % 0x100) / 0xFF,
    (math.floor((hex / 0x00000100)) % 0x100) / 0xFF,
    (math.floor((hex / 0x00000001)) % 0x100) / 0xFF
  }
end


local kw_w = 256
local kw_h = 256
local kw_x = 0.5*(kw_w - view_w)
local kw_y = 0.5*(kw_h - view_h)
local canvas, depth

depth_shader = 0
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

-- NOTE(dd) this is kinda stupid but seems`like the best way do depth 
-- for this game, since i'm not using sprites its easiest to just set
-- a z for everything while I draw an obj. 
local depth_shader_code = [[
extern number z;
vec4 position(mat4 transform_projection, vec4 vertex_position) {

	vec4 vtx = vertex_position;
  vec4 pos = transform_projection * vtx;
	
	pos.z = -z*0.00001;
	pos.z *= pos.w;

  return pos;
}
]]

local kw_buf = {}
local levels = 4  -- adjust for blur strength (3-6 typical)
local offset = 1.0
local bloom = 1.0

local game = require "game"

function love.load()
  love.graphics.setBackgroundColor(black)
  love.graphics.setDefaultFilter("nearest", "nearest")
  canvas = love.graphics.newCanvas(kw_w, kw_h)
  depth = love.graphics.newCanvas(kw_w, kw_h, {format = "depth16"})

  down_shader = love.graphics.newShader(down_shader_code)
  up_shader = love.graphics.newShader(up_shader_code)
  depth_shader = love.graphics.newShader(depth_shader_code)

  local cur_w, cur_h = kw_w, kw_h
  for i = 1, levels do
    kw_buf[i] = love.graphics.newCanvas(cur_w, cur_h)
    kw_buf[i]:setFilter("linear", "linear")
    cur_w = math.max(1, math.floor(cur_w / 2))
    cur_h = math.max(1, math.floor(cur_h / 2))
  end

  game.load()
end


function love.update(dt)
  if lurker then 
    lurker.update() 
  end

  game.update(dt)
end

function love.draw()
  -- draw game world to canvas

  love.graphics.setCanvas({canvas, depthstencil = depth})
  love.graphics.push()
  love.graphics.translate(kw_x, kw_y)
  love.graphics.clear(0, 0, 0, 0, true, 1.0)
  love.graphics.setDepthMode("lequal", true)
  love.graphics.setShader(depth_shader)

  	game.draw()
  love.graphics.setShader()
  love.graphics.setDepthMode()
  love.graphics.pop()

  -- Dual Kawase blur
  local source = kw_buf[1]
  love.graphics.setCanvas(source)

  -- NOTE(dd): only partially clearing kawase buffer to get temporal blur
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("fill", 0, 0, kw_w, kw_h)
  love.graphics.setColor(1, 1, 1, 1)

  love.graphics.setBlendMode("add")
  love.graphics.draw(canvas, 0, 0, 0, 1, 1)
  love.graphics.setBlendMode("alpha")

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

  if lurker then
    love.graphics.print(string.format("avg frame: %.3f ms", 1000 * love.timer.getAverageDelta()), 10, 10)
  end
end

