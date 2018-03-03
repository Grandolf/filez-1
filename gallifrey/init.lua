--nodes
minetest.register_node("gallifrey:stone", {
	description = "gallifreian stone",
	tiles = {"gallifrey_stone.png"},
	is_ground_content = false,
	groups = {cracky = 3},
	sounds = default.node_sound_stone_defaults(),
})
minetest.register_node("gallifrey:dalek_ship", {
	description = "dalek ship piece",
	tiles = {"gallifrey_dalek_ship.png"},
	is_ground_content = false,
	groups = {cracky = 3},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("gallifrey:sand", {
	description = "gallifreian sand",
	tiles = {"gallifrey_sand.png"},
	is_ground_content = false,
	groups = {crumbly = 3},
	sounds = default.node_sound_dirt_defaults(),
})

minetest.register_node("gallifrey:sands_of_time", {
	description = "sands of time",
	tiles = {"gallifrey_sand.png"},
	is_ground_content = false,
	groups = {crumbly = 3},
	sounds = default.node_sound_dirt_defaults(),
})
minetest.register_node("gallifrey:glass", {
	description = "gallifreian glass",
	tiles = {"gallifrey_glass.png"},
	is_ground_content = false,
	groups = {crumbly = 3},
	sounds = default.node_sound_dirt_defaults(),
})
minetest.register_node("gallifrey:sand_with_junk", {
	description = "gallifreian sand",
	tiles = {"gallifrey_sand_with_junk.png"},
	is_ground_content = false,
	groups = {crumbly = 3},
	sounds = default.node_sound_dirt_defaults(),
})
minetest.register_node("gallifrey:realm_barrier", {
	description = "this item is illegal to have in your possesion. any admins on while this is in a player iventory or chest will be notified, and ban you. goodbye h4k3r",
	tiles = {"gallifrey_realm_barrier.png"},
	is_ground_content = false,
	groups = {unbreakable = 1, not_in_creative_inventory = 1},
})
--items
minetest.register_craftitem("gallifrey:hourglass", {
	description = "gallifreyian hourglass",
	inventory_image = "gallifrey_hourglass.png",
})
minetest.register_craftitem("gallifrey:eventcoin", {
	description = "Event Coin",
	inventory_image = "gallifrey_eventcoin.png",
})
--crafts
--skybox
pos = {x=0, y=0, z=0 }
local space = 5000 

local spaceskybox = {
    "sky_pos_y.png",
    "sky_neg_y.png",
    "sky_pos_z.png",
    "sky_neg_z.png",
    "sky_neg_x.png",
    "sky_pos_x.png",
}

local time = 0
minetest.register_globalstep (function (dtime)
    time = time + dtime
    if time <= 1 then
        return
    end        

    for _, player in ipairs(minetest.get_connected_players()) do
        time = 0
        local name = player:get_player_name()
        local pos = player:getpos()
        --If the player has reached Space
        if minetest.get_player_by_name(name) and pos.y >= space then
            player:set_sky({}, "skybox", spaceskybox) -- Sets skybox

        --If the player is on Earth
        elseif minetest.get_player_by_name(name) and pos.y < space then
            player:set_sky({}, "regular", {}) -- Sets skybox, in this case it sets the skybox to it's default setting if and only if the player's Y value is less than the value of space.
        end
    end
end)

minetest.register_on_leaveplayer (function (player)
    local name = player:get_player_name()
    if name then
        player:set_sky({}, "regular", {})
    end
end)
--mapgen
local miny = 5000
local maxy = 7000

local base = math.ceil(miny / 4) * 4

local np_ter = {
	offset = 0,
	scale = 2,
	spread = {x=128, y=128, z=128},
	seed = 543213,
	octaves = 1.25,
	persist = 0.7
}

local np_terflat = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=512, z=512},
	seed = 543213,
	octaves = 1,
	persist = 0.5
}

local np_dec = {
	offset = 0,
	scale = 1,
	spread = {x = 92, y = 92, z = 92},
	seed = 345432,
	octaves = 2,
	persist = 0.5,
}

local np_cave = {
	offset = 0,
	scale = 1,
	spread = {x=40, y=18, z=40},
	octaves = 2,
	seed = -11842,
	persist = 0.7,
	flags = "eased",
	eased = true,
}

minetest.register_node(":realm:tmp", {
	drawtype = "airlike",
})

-- Stuff
local nobj_ter = nil
local nobj_terflat = nil
local nobj_dec = nil
local nobj_cave = nil
local nbuf_ter = {}
local nbuf_terflat = {}
local nbuf_dec = {}
local nbuf_cave = {}
local dbuf = {}
local p2dbuf = {}
local heightmap = {}
local times = {}

-- On generated function
minetest.register_on_generated(function(minp, maxp, seed)
	if minp.y < miny or minp.y > maxy then
		return
	end

	local t1 = os.clock()
	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z

	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data(dbuf)
	local p2data = vm:get_param2_data(p2dbuf)

	local c_air = minetest.get_content_id("air")
	local c_tmp = minetest.get_content_id("realm:tmp") -- For caves.
	local c_dirt_with_grass = minetest.get_content_id("gallifrey:sand")
	local c_unbreakable = minetest.get_content_id("gallifrey:realm_barrier")
	local c_dirt = minetest.get_content_id("gallifrey:sand")
	local c_sand = minetest.get_content_id("gallifrey:sand_with_junk")
	local c_stone = minetest.get_content_id("gallifrey:stone")
	local c_water = minetest.get_content_id("gallifrey:sands_of_time")
	local c_lava = minetest.get_content_id("air")

	local sidelen = x1 - x0 + 1
	local chulens = {x=sidelen, y=sidelen, z=sidelen}
	local minposxz = {x=x0, y=z0}
	local minposxyz = {x=x0, y=y0, z=z0}
	local border_amp = 128

	nobj_ter = nobj_ter or minetest.get_perlin_map(np_ter, chulens)
	nobj_terflat = nobj_terflat or minetest.get_perlin_map(np_terflat, chulens)
	nobj_dec = nobj_dec or minetest.get_perlin_map(np_dec, chulens)
	nobj_cave = nobj_cave or minetest.get_perlin_map(np_cave, chulens)

	local nvals_ter = nobj_ter:get2dMap_flat(minposxz, nbuf_ter)
	local nvals_terflat = nobj_terflat:get2dMap_flat(minposxz, nbuf_terflat)
	local nvals_dec = nobj_dec:get2dMap_flat(minposxz, nbuf_dec)
	local nvals_cave = nobj_cave:get3dMap_flat(minposxyz, nbuf_cave)

	local offset = math.random(5,20)
	local nixyz = 1
	local nixz = 1
	local schems = {}
	local mid = (miny + maxy) / 2

	for z = z0, z1 do
		for y = y0, y1 do -- Caves
			local vi = area:index(x0, y, z)
			for x = x0, x1 do -- for each node do
				local cave_d = 0.6
				if y > mid + 10 then
					cave_d = 1.2
				elseif y <= mid + 10 and y >= mid - 50 then
					cave_d = y/100 + 1.1
				end
				if nvals_cave[nixyz] > cave_d then
					data[vi] = c_tmp
				end
				vi = vi + 1
				nixyz = nixyz + 1
			end
		end
		for x = x0, x1 do -- for each column do
			local noise_1 = nvals_dec[nixz]
			local stone_depth = (math.floor(((nvals_ter[nixz] + 1)) *
				(14 * math.abs(math.abs(nvals_terflat[nixz] / 1.5) - 1.01)))) + mid
			for y = y1, y0, -1 do -- working down each column for each node do
				local vi = area:index(x, y, z)
				local nodid = data[vi]
				local viuu = area:index(x, y - 1, z)
				local nodiduu = data[viuu]
				local via = area:index(x, y + 1, z)
				local nodida = data[via]
				if nodid == c_tmp then
					data[vi] = c_air
				elseif y == stone_depth and y >= mid then
					data[vi] = c_dirt_with_grass
				elseif y < stone_depth then
					data[vi] = c_stone
					if y >= stone_depth - 2 - math.abs(nvals_ter[nixz] * 3) and y >= mid - 1 then
							data[vi] = c_dirt
					end
				elseif y <= mid then
					if y == stone_depth then
						data[vi] = c_sand
					else
						data[vi] = c_water
					end
				end
			end
		nixz = nixz + 1
		end
	end
	if minp.y == base then
		for z = z0, z1 do
		for x = x0, x1 do
			local vi = area:index(x, minp.y, z)
			data[vi] = c_unbreakable
		end
		end
	end
	vm:set_data(data)
	minetest.generate_ores(vm, minp, maxp)
	vm:set_lighting({day=0, night=0})
	if minp.y == base then
		vm:calc_lighting(nil, nil, false)
	else
		vm:calc_lighting()
	end
	vm:update_liquids()
	vm:write_to_map(data)
	local chugent = math.ceil((os.clock() - t1) * 1000)
	print(chugent)
end)
