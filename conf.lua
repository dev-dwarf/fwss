view_w = 224
view_h = 224
window_scale = 4

function love.conf(t)
  t.window.title = "FWSS"
  t.window.depth = 16
  t.window.width = view_w * window_scale
  t.window.height = view_h * window_scale
  t.window.vsync = true;
end
