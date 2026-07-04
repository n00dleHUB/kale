@tool
extends Node


const MAP_PRESETS := {
	"Full_BR_Map": [
		{ "tex": "res://raw/maptiles/MP_Granite_ClubHouse_Portal.jpg", "pos": Vector3(-449.99, 193.79, -574.91), "size": Vector3(1000, 1000, 1000), "ee": 0.0, "nf": 0.508, "uf": 0.010048, "lf": 0.000287 },
		{ "tex": "res://raw/maptiles/MP_Granite_MainStreet_Portal.jpg", "pos": Vector3(-1106.69, 0.0, 152.56), "size": Vector3(1000, 1000, 1000), "ee": 0.0, "nf": 0.51, "uf": 0.000018, "lf": 0.000019 },
		{ "tex": "res://raw/maptiles/MP_Granite_Marina_Portal.jpg", "pos": Vector3(-1201.90, 122.79, -604.90), "size": Vector3(1000, 1000, 1000), "ee": 0.0, "nf": 0.504, "uf": 0.000013, "lf": 0.000019 },
		{ "tex": "res://raw/maptiles/MP_Granite_MilitaryRnD_Portal.jpg", "pos": Vector3(469.0, 0.0, -685.40), "size": Vector3(1000, 1000, 1000), "ee": 0.0, "nf": 0.51, "uf": 0.000071, "lf": 0.000030 },
		{ "tex": "res://raw/maptiles/MP_Granite_MilitaryStorage_Portal.jpg", "pos": Vector3(561.77, 0.0, 388.34), "size": Vector3(1000, 1000, 1000), "ee": 0.0, "nf": 0.527, "uf": 0.000029, "lf": 0.000015 },
		{ "tex": "res://raw/maptiles/MP_Granite_TechCampus_Portal.jpg", "pos": Vector3(-209.75, 0.0, 320.75), "size": Vector3(1000, 1000, 1000), "ee": 0.0, "nf": 0.502, "uf": 0.000022, "lf": 0.000028 },
		{ "tex": "res://raw/maptiles/MP_Granite_Underground_Portal.jpg", "pos": Vector3(785.05, 239.37, -404.12), "size": Vector3(1000, 200, 1000), "ee": 0.0, "nf": 0.5, "uf": 0.000012, "lf": 0.000011 },
	],
	"MP_Abbasid": { "tex": "res://raw/maptiles/MP_Abbasid.jpg", "pos": Vector3(-84.69, 64.87, 122.93), "size": Vector3(1085, 100, 1085), "ee": 0.0, "nf": 0.49, "uf": 0.000035, "lf": 0.000128 },
	"MP_Aftermath": { "tex": "res://raw/maptiles/MP_Aftermath.jpg", "pos": Vector3(-576.83, 61.62, -30.16), "size": Vector3(878, 150, 878), "ee": 0.0, "nf": 0.514, "uf": 0.000022, "lf": 0.000017 },
	"MP_Badlands": { "tex": "res://raw/maptiles/MP_Badlands.jpg", "pos": Vector3(0.47, 95.29, -100.41), "size": Vector3(1400, 100, 1400), "ee": 0.0, "nf": 0.515, "uf": 0.000020, "lf": 0.000013 },
	"MP_Battery": { "tex": "res://raw/maptiles/MP_Battery.jpg", "pos": Vector3(696.98, 0.0, 88.53), "size": Vector3(1400, 500, 1400), "ee": 0.0, "nf": 0.51, "uf": 0.000012, "lf": 0.000016 },
	"MP_Capstone": { "tex": "res://raw/maptiles/MP_Capstone.jpg", "pos": Vector3(0.11, 0.0, -168.57), "size": Vector3(1400, 1000, 1400), "ee": 0.0, "nf": 0.408, "uf": 0.000034, "lf": 0.000031 },
	"MP_Contaminated": { "tex": "res://raw/maptiles/MP_Contaminated.jpg", "pos": Vector3(-0.36, 262.19, -99.71), "size": Vector3(1400, 1000, 1400), "ee": 0.0, "nf": 0.471, "uf": 0.000016, "lf": 0.000023 },
	"MP_Dumbo": { "tex": "res://raw/maptiles/MP_Dumbo.jpg", "pos": Vector3(0.14, 0.0, -154.76), "size": Vector3(1400, 1000, 1400), "ee": 0.0, "nf": 0.496, "uf": 0.000034, "lf": 0.000014 },
	"MP_Eastwood": { "tex": "res://raw/maptiles/MP_Eastwood.jpg", "pos": Vector3(0.07, 0.0, -187.89), "size": Vector3(1400, 1000, 1400), "ee": 0.0, "nf": 0.0, "uf": 0.000045, "lf": 0.000028 },
	"MP_FireStorm": { "tex": "res://raw/maptiles/MP_FireStorm.jpg", "pos": Vector3(0.14, 0.0, 21.26), "size": Vector3(1642, 1000, 1642), "ee": 0.0, "nf": 0.492, "uf": 0.000032, "lf": 0.000017 },
	"MP_GolmudRailway": { "tex": "res://raw/maptiles/MP_GolmudRailway.jpg", "pos": Vector3(-125.62, 637.72, 850.34), "size": Vector3(2100, 1000, 2100), "ee": 0.0, "nf": 0.489, "uf": 0.000045, "lf": 0.000023 },
	"MP_Granite_ClubHouse_Portal": { "tex": "res://raw/maptiles/MP_Granite_ClubHouse_Portal.jpg", "pos": Vector3(-449.99, 193.79, -574.91), "size": Vector3(1000, 1000, 1000), "ee": 0.0, "nf": 0.508, "uf": 0.000064, "lf": 0.000028 },
	"MP_Granite_MainStreet_Portal": { "tex": "res://raw/maptiles/MP_Granite_MainStreet_Portal.jpg", "pos": Vector3(-1106.69, 0.0, 152.56), "size": Vector3(1000, 1000, 1000), "ee": 0.0, "nf": 0.51, "uf": 0.000018, "lf": 0.000019 },
	"MP_Granite_Marina_Portal": { "tex": "res://raw/maptiles/MP_Granite_Marina_Portal.jpg", "pos": Vector3(-1201.90, 122.79, -604.90), "size": Vector3(1000, 1000, 1000), "ee": 0.0, "nf": 0.504, "uf": 0.000013, "lf": 0.000019 },
	"MP_Granite_MilitaryRnD_Portal": { "tex": "res://raw/maptiles/MP_Granite_MilitaryRnD_Portal.jpg", "pos": Vector3(469.0, 0.0, -685.40), "size": Vector3(1000, 1000, 1000), "ee": 0.0, "nf": 0.51, "uf": 0.000071, "lf": 0.000030 },
	"MP_Granite_MilitaryStorage_Portal": { "tex": "res://raw/maptiles/MP_Granite_MilitaryStorage_Portal.jpg", "pos": Vector3(561.77, 0.0, 388.34), "size": Vector3(1000, 1000, 1000), "ee": 0.0, "nf": 0.527, "uf": 0.000029, "lf": 0.000015 },
	"MP_Granite_TechCampus_Portal": { "tex": "res://raw/maptiles/MP_Granite_TechCampus_Portal.jpg", "pos": Vector3(-209.75, 0.0, 320.75), "size": Vector3(1000, 1000, 1000), "ee": 0.0, "nf": 0.502, "uf": 0.000022, "lf": 0.000028 },
	"MP_Granite_Underground_Portal": { "tex": "res://raw/maptiles/MP_Granite_Underground_Portal.jpg", "pos": Vector3(785.05, 239.37, -404.12), "size": Vector3(1000, 200, 1000), "ee": 0.0, "nf": 0.5, "uf": 0.000012, "lf": 0.000011 },
	"MP_Limestone": { "tex": "res://raw/maptiles/MP_Limestone.jpg", "pos": Vector3(696.71, 22.57, 88.36), "size": Vector3(1400, 1000, 1400), "ee": 0.0, "nf": 0.481, "uf": 0.000034, "lf": 0.000047 },
	"MP_Outskirts": { "tex": "res://raw/maptiles/MP_Outskirts.jpg", "pos": Vector3(-382.0, 0.0, -89.80), "size": Vector3(1740, 1000, 1740), "ee": 0.0, "nf": 0.532, "uf": 0.000029, "lf": 0.000039 },
	"MP_Plaza": { "tex": "res://raw/maptiles/MP_Plaza.jpg", "pos": Vector3(14.26, 0.0, 100.16), "size": Vector3(1000, 1000, 1000), "ee": 0.0, "nf": 0.512, "uf": 0.000064, "lf": 0.000032 },
	"MP_Portal_Sand": { "tex": "res://raw/maptiles/MP_Portal_Sand.jpg", "pos": Vector3(0.0, 0.0, 0.0), "size": Vector3(1000, 100, 1000), "ee": 0.0, "nf": 0.549, "uf": 0.000041, "lf": 0.000052 },
	"MP_Subsurface": { "tex": "res://raw/maptiles/MP_Subsurface.jpg", "pos": Vector3(0.51, 66.44, -104.04), "size": Vector3(1420, 100, 1420), "ee": 0.0, "nf": 0.511, "uf": 0.000048, "lf": 0.000018 },
	"MP_Tungsten": { "tex": "res://raw/maptiles/MP_Tungsten.jpg", "pos": Vector3(60.24, 86.51, -25.08), "size": Vector3(1550, 100, 1550), "ee": 0.0, "nf": 0.507, "uf": 0.000039, "lf": 0.000033 },
}


static func get_names() -> PackedStringArray:
	var names: Array[String] = []
	for key in MAP_PRESETS:
		names.append(key)
	names.sort()
	return PackedStringArray(names)


static func get_preset(name: String):
	return MAP_PRESETS.get(name, {})
