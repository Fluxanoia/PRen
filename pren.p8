pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- main loop
-- by fluxanoia, tyler wright

-- colours

black  = 0
white  = 7

-- screen size

lsx = -64
lsy = -64
usx = 63
usy = 63

-- main loop

root = nil

function _init()
	cls()
	camera(-64, -64)
	root = scene()
end

function _update()
	root:update()
end

function _draw()
 cls()
	root:draw()
end

-- helper
 
-- rotates the items of a list
function cycle(l)
	local i = #l
	while i > 1 do
		l[i], l[i - 1] = 
			l[i - 1], l[i]
		i -= 1
	end
end

-- sorts with a compare function
function sort(l, cmp)
 for i = 1, #l do
  local j = i
  while j > 1 
  	and cmp(l[j - 1], l[j]) do
   l[j], l[j - 1] = 
   	l[j - 1], l[j]   	
   j -= 1
  end
 end
end

-- a sorting function generator
function index_sort(i)
	return function (a, b)
			return a[i] > b[i]
		end
end

-- nth root function
-- from pico8lib
function nthroot(n, x)
 local s = 1
 if (x < 0) s, x = -1, -x
 local r = x ^ (1 / n)
 for _ = 1, 4 do
  r = r - r / n + x / r 
  	^ (n - 1) / n
 end
 return r * s
end

-- printing

function print_vec(t, x, y, c)
	if x == nil then x = lsx end
	if y == nil then y = lsy end
	if c == nil then c = white end
	local s = "( "
	for i in all(t) do
		s = s .. i .. " "
	end
	s = s .. ")"
	print(s, x, y, c)
end

function print_mat(t, x, y, c)
	for i = 1, #t do
		print_vec(t[i], x, 
			y + 6 * (i - 1), c) 
	end
end
-->8
-- scene

function scene()
	local u = function (s)
		if btn(⬅️) then
			mat_apply(rot_y(1), s.cpos)
		end
		if btn(➡️) then
		 mat_apply(rot_y(-1), s.cpos)
		end
		if btn(⬆️) then
			mat_apply(rot_x(1), s.cpos)
		end
		if btn(⬇️) then
		 mat_apply(rot_x(-1), s.cpos)
		end
		s:update_camera()
	end
	
	local d = function (s)
		-- todo better! ..
	 for f in all(s.room) do
	 	local _,_1 = rasterise(s, f.p1)
	 	local _,_2 = rasterise(s, f.p2)
	 	local _,_3 = rasterise(s, f.p3)
	 	for p in all({
	 		{_1, _2}, {_1, _3}, 
	 		{_2, _3}}) do
	 		line(p[1][1], p[1][2],
	 			p[2][1], p[2][2], f.c)
	 	end
	 end
	 -- todo better! ^^
		for p in all(s.objs) do
		 local b, v = rasterise(s, p)
		 if b then
		 	pset(v[1], v[2], 9)
		 end
	 end
	 -- rm
	 s:update_camera()
	end
	
	local r_c = function (s)
		s.cpos = { 0, 0, 100 }
		s:update_camera()
	end

	local u_c = function (s)
		orient(s.cori, s.cpos)
		if s.cori == nil then
 		s:reset_camera()
 	end
	end

	s = {
		cpos = nil,
		cori = mat_id(),
		focal = 20,

		room = cube(100),
		objs = grid(50),
		
		update = u,
		draw = d,
		
		reset_camera = r_c,
		update_camera = u_c
	}
	s:reset_camera(s)
	return s
end

function rasterise(s, _p)
	local v = { 0, 0 }
	local p = vec_clone(_p)
	vec_sum(p, s.cpos, -1)
	mat_apply(s.cori, p)
 if (p[3] != 0) then
		local k = s.focal / abs(p[3])
 	v[1] = flr(p[1] * k) 
 	v[2] = flr(-p[2] * k)
	end
	return p[3] < 0, v
end

function orient(o, p)
	o[3] = vec_clone(p)
	o[1] = vec_cross({0,1,0}, o[3])
	o[2] = vec_cross(o[3], o[1])
	for v in all(o) do
		vec_norm(v)
	end	
end
-->8
-- maths
		
-- vector functions
		
function vec_clone(u)
	return { unpack(u) }
end

function vec_sum(u, v, k)
	if k == nil then k = 1 end
	for i = 1, #u do
		u[i] += k * v[i]
	end
end
		
function vec_dot(u, v)
	local s = 0
	for i = 1, #u do
		s += u[i] * v[i]
	end
	return s
end
		
function vec_scale(u, k)
	for i = 1, #u do
		u[i] *= k
	end
end
	
function vec_len(u)
	return sqrt(vec_dot(u, u))
end
	 
function vec_norm(u)
	vec_scale(u, 1 / vec_len(u))
end
	 
function vec_cross(u, v)
	local w = {
		u[2] * v[3] - u[3] * v[2],
		u[3] * v[1] - u[1] * v[3],
		u[1] * v[2] - u[2] * v[1]
	}
	vec_norm(w)
	return w
end

-- matrix functions

function mat_clone(m)
	local n = {}
	for i = 1, #m do
	 n[#n + 1] = vec_clone(m[i])
	end
end

function mat_col(m, c)
	return { m[1][c], m[2][c], 
		m[3][c] }
end

function mat_trans(m)
	local c1 = mat_col(m, 1)
	local c2 = mat_col(m, 2)
	local c3 = mat_col(m, 3)
	m[1] = c1
	m[2] = c2
	m[3] = c3
end

function mat_mult(m, n)
	local o = {}
	for i = 1, 3 do		
		local r = {}
		for j = 1, 3 do
			r[#r + 1] = vec_dot(
				m[i], mat_col(n, j))
		end
		o[#o + 1] = r
	end
	return o
end
		
function mat_apply(m, v)
	local v1 = vec_dot(m[1], v)
	local v2 = vec_dot(m[2], v)
	local v3 = vec_dot(m[3], v)
	v[1] = v1
	v[2] = v2
	v[3] = v3
end
		
function mat_minor_det(m, i, j)
	local min_r = 1
	local min_c = 1
	local max_r = 3
	local max_c = 3
	if (i == 1) then min_r = 2 end
	if (j == 1) then min_c = 2 end
	if (i == 3) then max_r = 2 end
	if (j == 3) then max_c = 2 end
	return m[min_r][min_c] 
		* m[max_r][max_c]
		- m[min_r][max_c]
		* m[max_r][min_c]
end
		
function mat_scale(m, s)
	for r in all(m) do
		vec_scale(r, s)
	end
end
		
function mat_det(m)
	local md1 = mat_minor_det(
		m, 1, 1)
	local md2 = mat_minor_det(
		m, 2, 1)
	local md3 = mat_minor_det(
		m, 3, 1)
	return m[1][1] * md1
		- m[2][1] * md2
		+ m[3][1] * md3
end
		
function mat_inv(m)
	local d = mat_det(m)
	if d == 0 then return nil end
	mat_trans(m)
	for i = 1, 3 do
		for j = 1, 3 do
			m[i][j] = (-1 ^ (i + j))
				* mat_minor_det(m, i, j)
				/ d
		end
	end
end

function mat_max(m)
	local v = m[1][1]
	for r in all(m) do
		for i in all(r) do
			if i > v then v = i end
		end
	end
	return v
end

function trig(_a)
	local a = _a / 360
	return cos(a), -sin(a)
end

function rot_x(a)
	local c, s = trig(a)
	return { { 1, 0, 0 },
		{ 0, c, -s }, { 0, s, c } }
end

function rot_y(a)
	local c, s = trig(a)
	return { { c, 0, s },
		{ 0, 1, 0 }, { -s, 0, c } }
end

function rot_z(a)
	local c, s = trig(a)
	return { { c, -s, 0 },
	 { s, c, 0 }, { 0, 0, 1 } }
end

function mat_id()
	local m = { { 1, 0, 0 },
		{ 0, 1, 0 }, { 0, 0, 1 } }
	return m
end
-->8
-- geometry

function grid(size)
	local s = size / 2
	local g = {}
	for i = 1, 3 do
		for j = 1, 3 do
			for k = 1, 3 do
				g[#g + 1] = { s * (i - 2), 
					s * (j - 2), s * (k - 2) }
			end
		end
	end
	return g
end

function cube(size)
	local s = size / 2
	local fs = {}
	for i in all({-1, 1}) do
		for j in all({-1, 1}) do
			local p1 = { i * s, -s, -s }
			local p2 = { i * s, j * s, 
				-j * s }
			local p3 = { i * s, s, s }
		 for k = 1, 3 do
				fs[#fs + 1] = face(
					p1, p2, p3, 8)
				cycle(p1)
				cycle(p2)
				cycle(p3)
			end
		end
	end
	return fs
end

function face(_p1, _p2, _p3, _c)
	local ps = {_p1, _p2, _p3}
	sort(ps, index_sort(2))
	local f = {
		p1 = vec_clone(ps[1]),
		p2 = vec_clone(ps[2]),
		p3 = vec_clone(ps[3]),
		c = _c,
		e1 = vec_clone(ps[2]),
		e2 = vec_clone(ps[3])
	}
	local m1 = vec_clone(ps[1])
	vec_scale(m1, -1)
	vec_sum(f.e1, m1)
	vec_sum(f.e2, m1)
	return f
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
