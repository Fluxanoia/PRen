pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- main
-- by fluxanoia, tyler wright

-- globals

cam = nil

scene_index = 1
curr_scene = nil

room = nil

notif = ""
notif_time = 0

o_ready = true
x_ready = true

-- main loop

function _init()
	cls()
	camera(-64, -64)
	reset_camera()
	reload_scene()
end

function _update60()
	-- notification updating
	if (notif_time > 0) then
		notif_time -= 1
	end
	-- user input
	input()
	-- component updating
	for p in all(
		curr_scene.particles) do
		p:update()
	end
end

-- state

function reset_camera()
	cam = view()
end

function reload_scene()
	room = cube()

	curr_scene = get_scene(
		scene_index)
	curr_scene:populate()
	
	notif = "loaded "
		.. curr_scene.name
		.. ".scene"
	notif_time = 60
end

-- user input

function input()
	-- scene switching
	if not btn(🅾️) then
		o_ready = true
	elseif o_ready then
		switch_scenes()
		o_ready = false
	end
	-- camera mode switching
	if not btn(❎)  then
		x_ready = true
	elseif x_ready then
		cam.free = not cam.free
		x_ready = false
	end
	-- camera movement
	camera_movement()
end

function switch_scenes()
	scene_index += 1
		if (scene_index 
			> scene_count()) then
			scene_index = 1
		end
	reload_scene()
end

function camera_movement()
	if cam.free then
		if (btn(⬆️)) then
			cam.x_rot -= 1
		end
		if (btn(⬇️)) then
			cam.x_rot += 1
		end
		if (btn(⬅️)) then
			cam.y_rot -= 1
		end
		if (btn(➡️)) then
			cam.y_rot += 1
		end
	else
		cam.x_rot += 0.6
		cam.y_rot += 0.3
	end
end


-->8
-- rendering

function _draw()
 cls()
 -- prepare camera
 cmat = rot(cam.x_rot,
 	cam.y_rot, 0)
 cam.pos_inv = cmat:apply(
 	vec3(0, 0, cam.dist))
 cam.pos_inv:scale(-1)
 cam.look_inv = look(
 	cam.pos_inv)
 cam.look_inv = 
 	cam.look_inv:inv()
 if cam.look_inv == nil then
 	reset_camera()
 	return
 end
 -- draw room
 for f in all(room) do
 	_1 = raster(f.p1)[2]
 	_2 = raster(f.p2)[2]
 	_3 = raster(f.p3)[2]
 	line(_1.x, _1.y,
 		_2.x, _2.y, f.c)
 	line(_1.x, _1.y,
 		_3.x, _3.y, f.c)
 	line(_3.x, _3.y,
 		_2.x, _2.y, f.c)
 end
	-- draw particles
	for p in all(
		curr_scene.particles) do
	 ras = raster(p.pos)
	 if (ras[1]) then
	 	v = ras[2]
	 	pset(v.x, v.y, p.c)
	 end
 end
 -- draw notifications
 if (notif_time > 0) then
 	rectfill(-64, 58, 
 		64, 64, black)
 	print(notif, -64, 58, white)
 end
end

function to_camera_space(p)
	p = p:copy()
 p:sum(cam.pos_inv)
 return cam.look_inv:apply(p)
end

-- rasterise a 3d point
function raster(p)
	v = vec2(0, 0)
	p = to_camera_space(p)
 if (p.z != 0) then
		s = cam.foc / abs(p.z)
 	v.x = flr(p.x * s) 
 	v.y = flr(-p.y * s)
	end
	return { p.z < 0, v }
end
-->8
-- vectors and matrices

--[[

	view object

--]]

function view()
	return {
		x_rot = 0,
		y_rot = 0,
		dist = 100,
		foc = 20,
		
		free = true,
		
		pos_inv = nil,
		look_inv = nil
 }
end

--[[

	vector object

--]]

function vec2(_x, _y)
	return {
		x = _x,
		y = _y,
		
		-- indexing
		
		table = function (self)
			return {
				self.x,
				self.y
			}
		end,
		
		get = function (self, i)
			return (self:table())[i]
		end,
		
		copy = function (self)
			return vec2(self.x,
				self.y)
		end,
		
		-- maths
		
		sum = function (self, v)
			self.x += v.x
			self.y += v.y
		end,
		
		scale = function (self, s)
			self.x *= s
			self.y *= s
		end,
		
		-- visual
		
		draw = function (self, x, y)
			print(
				"(" .. self.x .. ", "
					.. self.y .. ")",
				x, y, white
			)
		end
		
	}
end

function vec3(_x, _y, _z)
	return {
		x = _x,
		y = _y,
		z = _z,
		
		-- indexing
		
		table = function (self)
			return {
				self.x,
				self.y,
				self.z
			}
		end,
		
		get = function (self, i)
			return (self:table())[i]
		end,
		
		copy = function (self)
			return vec3(self.x,
				self.y,
				self.z)
		end,
		
		-- maths
		
		sum = function (self, v)
			self.x += v.x
			self.y += v.y
			self.z += v.z
		end,
		
		dot = function (self, v)
			return self.x * v.x
				+ self.y * v.y
				+ self.z * v.z
		end,
		
		scale = function (self, s)
			self.x *= s
			self.y *= s
			self.z *= s
		end,
	
		len = function (self)
			return sqrt(self:sq_len())
		end,

	 sq_len = function (self)
	 	return self.x ^ 2
	 		+ self.y ^ 2
	 		+ self.z ^ 2
	 end,
	 
	 normalise = function (self)
	 	self:scale(1 / self:len())
	 end,
	 
	 cross = function (self, v)
			v = vec3(
				self.y * v.z - self.z * v.y,
				self.z * v.x - self.x * v.z,
				self.x * v.y - self.y * v.x
			)
			v:normalise()
			return v
	 end,
		
		-- visual
		
		draw = function (self, x, y)
			print(
				"(" .. self.x .. ", "
					.. self.y .. ", "
					.. self.z .. ")",
				x, y, white
			)
		end
		
	}
end

--[[ 
	
	matrix object
	
--]]

function mat3(_r1, _r2, _r3)
	return {
		r1 = _r1,
		r2 = _r2,
		r3 = _r3,
		
		-- indexing
		
		table = function (self)
			return {
				self.r1, 
				self.r2, 
				self.r3
			}
		end,
		
		get = function (self, r, c)
			return self:row(r):get(c)
		end,
		
		row = function (self, r)
			return (self:table())[r]
		end,
		
		col = function (self, c)
			return vec3(
				self.r1:get(c),
				self.r2:get(c),
				self.r3:get(c)
			)
		end,
		
		-- maths
		
		t = function (self)
				return mat3(
					self:col(1),
					self:col(2),
					self:col(3)
				)
		end,
		
		mult = function (self, m)
			m1 = self:table()
			m2 = (m:t()):table()
			vs = {}
			for i = 1, 3 do
				r = {}
				for j = 1, 3 do
					r[#r+1] = (m1[i]):dot(
						m2[j])
				end
				vs[#vs + 1] = vec3(r[1],
					r[2], r[3])
			end
			return mat3(vs[1],
				vs[2], vs[3])
		end,
		
		apply = function (self, v)
			return vec3(self.r1:dot(v),
				self.r2:dot(v),
				self.r3:dot(v))
		end,
		
		min_det = function (
			self, _i, _j)
			m = {}
			for i = 1, 3 do
				if (i != _i) then
					for j = 1, 3 do
						if (j != _j) then
							m[#m + 1] =
								self:get(i, j)
						end
					end
				end
			end
			return m[1] * m[4] 
				- m[2] * m[3]
		end,
		
		scale = function (self, s)
			rs = self:table()
			for r in all(rs) do
				r:scale(s)
			end
			return mat3(rs[1], rs[2],
				rs[3])
		end,
		
		det = function (self)
		md1 = self:min_det(1, 1)
		md2 = self:min_det(2, 1)
		md3 = self:min_det(3, 1)
			return self:get(1, 1) * md1
				- self:get(2, 1) * md2
				+ self:get(3, 1) * md3
		end,
		
		inv = function (self)
			det = self:det()
			if (det == 0) then
				return nil
			end
			mt = self:t()
			inv1 = vec3(
				mt:min_det(1, 1) / det,
				-mt:min_det(1, 2) / det,
				mt:min_det(1, 3) / det
			)
			inv2 = vec3(
				-mt:min_det(2, 1) / det,
				mt:min_det(2, 2) / det,
				-mt:min_det(2, 3) / det
			)
			inv3 = vec3(
				mt:min_det(3, 1) / det,
				-mt:min_det(3, 2) / det,
				mt:min_det(3, 3) / det
			)
			return mat3(inv1, inv2, 
				inv3)
		end,
		
		max = function (self)
			m = 0
			for i = 1, 3 do
				for j = 1, 3 do
					v = abs(self:get(i, j))
					if (v > m) then
					 m = v
					end
				end
			end
			return m
		end,
		
		-- visual
		
		draw = function (self, x, y)
			self.r1:draw(x, y)
			self.r2:draw(x, y + 6)
			self.r3:draw(x, y + 12)
		end
		
	}
end

--[[

	matrix functions

--]]

function trig(_a)
	a = _a / 360
	return { 
		c = cos(a),
		s = -sin(a)
	}
end

function rot_x(_a)
	t = trig(_a)
	return mat3(
		vec3(1, 0, 0),
		vec3(0, t["c"], -t["s"]),
		vec3(0, t["s"], t["c"])
	)
end

function rot_y(_a)
	t = trig(_a)
	return mat3(
		vec3(t["c"], 0, t["s"]),
		vec3(0, 1, 0),
		vec3(-t["s"], 0, t["c"])
	)
end

function rot_z(_a)
	t = trig(_a)
	return mat3(
		vec3(t["c"], -t["s"], 0),
		vec3(t["s"], t["c"], 0),
		vec3(0, 0, 1)
	)
end

function rot(_x, _y, _z)
	x = rot_x(_x)
	y = rot_y(_y)
	z = rot_z(_z)
	x = x:mult(y)
	x = x:mult(z)
	return x
end

function look(f)
	f = f:copy()
	f:normalise()
	f:scale(-1)
	r = (vec3(0, 1, 0)):cross(f)
	u = f:cross(r)
	
	l = (mat3(r, u, f)):t()
	lmax = l:max()
	if (lmax != 0) then
		l = l:scale(1 / lmax)
		l = l:scale(
			(1 / l:det()) ^ (1 / 3))
	end
	
	return l
end
-->8
-- scenes

--[[
	
	colours

--]]

black  = 0
d_gray = 5
l_gray = 6
white  = 7

colours = {8, 9, 10, 11, 12, 
	14, 15}
d_colours = {1, 2, 3, 4, 13}

function get_colour()
	return rnd(colours)
end

function get_d_colour()
	return rnd(colours)
end

--[[

	scene object
	
--]]

function scene(n, pf)
	return {
		name = n,
		p_func = pf,
		
		particles = {},
		populate = function (self)
			self.particles = 
				self.p_func()
		end
	}
end

function scene_count()
	return count(scenes)
end

function get_scene(i)
	s = scenes[i]
	if s == nil then
		s = scene("untitled", {})
	end
	return s
end

p_grid = function ()
	s = 40
	grid = {}
	for i = 1, 3 do
		for j = 1, 3 do
			for k = 1, 3 do
				grid[#grid + 1] =
					particle(
						vec3(s * (i - 2), 
					 	s * (j - 2),
					 	s * (k - 2)),
					 vec3(0, 0, 0),
					 white,
					 p_update_lin
					 )
			end
		end
	end
	return grid
end

p_explosion = function ()
	ps = {}
	ran = 5
	mran = ran * 2 + 1
	for i = 1, 150 do
		ps[#ps + 1] = particle(
			vec3(0, 0, 0),
			vec3(rnd(mran) - ran, 
				2 * rnd(mran),
				rnd(mran) - ran),
			get_colour(),
			p_update_fall
		)
	end
	return ps
end

scenes = {
 scene("cube grid", p_grid),
 scene("explosion", 
 	p_explosion)
}

--[[

	particle object
	
--]]

function particle(
	_pos, _vel, _c, _update)
	return {
		pos = _pos,
	 vel = _vel,
		c = _c,
		update = _update
	}
end

p_update_lin = function (self)
	self.pos:sum(self.vel)
end

p_update_fall = function (self)
 p_update_lin(self)
 self.vel:scale(0.9)
 self.vel:sum(
 	vec3(0, -2, 0))
end
-->8
-- geometry

function cube()
	s = 50
	fs = {}
	for i in all({-1, 1}) do
		for j in all({-1, 1}) do
		 for k = 0, 2 do
			 p1 = { i * s, -s, -s }
			 p2 = { i * s, 
			 	j * s, -j * s }
			 p3 = { i * s, s, s }
			 i1 = ((0 + k) % 3) + 1
			 i2 = ((1 + k) % 3) + 1
			 i3 = ((2 + k) % 3) + 1
				fs[#fs + 1] = face(
					vec3(p1[i1], 
						p1[i2], p1[i3]),
					vec3(p2[i1], 
						p2[i2], p2[i3]),
					vec3(p3[i1], 
						p3[i2], p3[i3]),
					8)
			end
		end
	end
	return fs
end

function sort(a, cmp)
  for i = 1, count(a) do
    j = i
    while j > 1 
    	and cmp(a[j-1],a[j]) do
     a[j], a[j-1] = a[j-1], a[j]
    	j = j - 1
    end
  end
end

function face(_p1, _p2, _p3, _c)
	ps = {_p1, _p2, _p3}
	sort(ps, function (a, b)
			return a.y > b.y
		end)
	_1 = ps[1]
	_2 = ps[2]
	_3 = ps[3]
	f = {
		p1 = _1,
		p2 = _2,
		p3 = _3,
		c = _c,
		
		e1 = _2:copy(),
		e2 = _3:copy()
	}
	p1_inv = _1:copy()
	p1_inv:scale(-1)
	f.e1:sum(p1_inv)
	f.e2:sum(p1_inv)
	return f
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
