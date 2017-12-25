-- A water mill produces HV EUs by exploiting flowing water across it
-- It is a HV EU supplyer and fairly low yield (max 120EUs)
-- It is a little under half as good as the thermal generator.

local S = technic.getter

local cable_entry = "^technic_cable_connection_overlay.png"

minetest.register_alias("hv_water_mill", "technic:hv_water_mill")

minetest.register_craft({
	output = 'technic:hv_water_mill',
	recipe = {
		{'default:mese', 'group:wood',        'default:mese'},
		{'group:wood',     'technic:mv_water_mill', 'default:diamondblock'},
		{'default:mese', 'technic:hv_cable',       'default:mese'},
	}
})

local function check_node_around_mill(pos)
	local node = minetest.get_node(pos)
	if node.name == "default:water_flowing"
	  or node.name == "default:river_water_flowing" then
		return node.param2 -- returns approx. water flow, if any
	end
	return false
end

local run = function(pos, node)
	local meta             = minetest.get_meta(pos)
	local water_flow       = 0
	local lava_nodes       = 0
	local production_level = 0
	local eu_supply        = 0
	local max_output       = 78 * 45 -- four param2's at 15 makes 60, cap it lower for "overload protection"
									 -- (plus we want the gen to report 100% if three sides have full flow)

	local positions = {
		{x=pos.x+1, y=pos.y, z=pos.z},
		{x=pos.x-1, y=pos.y, z=pos.z},
		{x=pos.x,   y=pos.y, z=pos.z+1},
		{x=pos.x,   y=pos.y, z=pos.z-1},
	}

	for _, p in pairs(positions) do
		local check = check_node_around_mill(p)
		if check then
			water_flow = water_flow + check
		end
	end

	eu_supply = math.min(78 * water_flow, max_output)
	production_level = math.floor(100 * eu_supply / max_output)

	meta:set_int("HV_EU_supply", eu_supply)

	meta:set_string("infotext",
		S("Hydro %s Generator"):format("HV").." ("..production_level.."%)")

	if production_level > 0 and
	   minetest.get_node(pos).name == "technic:hv_water_mill" then
		technic.swap_node (pos, "technic:hv_water_mill_active")
		meta:set_int("HV_EU_supply", 0)
		return
	end
	if production_level == 0 then
		technic.swap_node(pos, "technic:hv_water_mill")
	end
end

minetest.register_node("technic:hv_water_mill", {
	description = S("Hydro %s Generator"):format("HV"),
	tiles = {
		"hv_technic_water_mill_top.png",
		"hv_technic_machine_bottom.png"..cable_entry,
		"hv_technic_water_mill_side.png",
		"hv_technic_water_mill_side.png",
		"hv_technic_water_mill_side.png",
		"hv_technic_water_mill_side.png"
	},
	paramtype2 = "facedir",
	groups = {snappy=2, choppy=2, oddly_breakable_by_hand=2,
		technic_machine=2,  technic_hv=1},
	legacy_facedir_simple = true,
	sounds = default.node_sound_wood_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", S("Hydro %s Generator"):format("HV"))
		meta:set_int("HV_EU_supply", 0)
	end,
	technic_run = run,
})

minetest.register_node("technic:hv_water_mill_active", {
	description = S("Hydro %s Generator"):format("HV"),
	tiles = {"hv_technic_water_mill_top_active.png", "hv_technic_machine_bottom.png",
	         "hv_technic_water_mill_side.png",       "hv_technic_water_mill_side.png",
	         "hv_technic_water_mill_side.png",       "hv_technic_water_mill_side.png"},
	paramtype2 = "facedir",
	groups = {snappy=2, choppy=2, oddly_breakable_by_hand=2,
		technic_machine=2, not_in_creative_inventory=1, technic_hv=1},
	legacy_facedir_simple = true,
	sounds = default.node_sound_wood_defaults(),
	drop = "technic:hv_water_mill",
	technic_run = run,
	technic_disabled_machine_name = "technic:hv_water_mill",
})

technic.register_machine("HV", "technic:hv_water_mill",        technic.producer)
technic.register_machine("HV", "technic:hv_water_mill_active", technic.producer)
