/*
	--------------------------------------------------------
	see brownian noise, value noise, perlin noise
	--------------------------------------------------------
*/

//todo: map loads on restart, mountain percentage in cfg, mirroring, caves, resources, flora (bushes, trees, flowers, grass doesn't spawn everywhere), animals, ruins (optional),
//biomes (different landscapes, forest, flower fields, wheat fields, mountains, plains)
//map types: normal, cave world
//seed support: !getseed command, cfg seeds for their favorite seeds, !loadmap seed / seednum in cfg 
//item support: they can add items to the cfg that will spawn in the world
//spawners support: they provide a spawner blob in the cfg that players spawn from
//progress notifications when loading the map (Prints)

//#include "MapGenFunctions.as";
#include "MapGenIncludes.as"
//not sure if we need these includes
#include "LoaderUtilities.as";
#include "MinimapHook.as";


bool loadMap(CMap@ _map, const string& in filename)
{
	CMap@ map = _map;

	MiniMap::Initialise();

	if (!getNet().isServer() || filename == "")
	{
		SetupMap(map, 0, 0);
		SetupBackgrounds(map);
		return true;
	}

	//SET UP MAP
	ConfigFile@ cfg = ConfigFile(filename);

	const s32 width = cfg.read_s32("width");
	const s32 height = cfg.read_s32("height");
	const s32 baseline = cfg.read_s32("baseline") * 0.01f * height; //ground height
	const u8 noise_height = cfg.read_u8("noise_height");
	const u8 smooth_cycles = cfg.read_u8("smooth_cycles");
	const u8 cave_depth = cfg.read_u8("cave_depth");

	SetupSeed(@cfg);
	SetupMap(map, width, height);

	//terrain generation
	print("*SETTING TERRAIN*");
	TerrainManager@ tm = GetWaveTerrain(@map, width, baseline, @cfg);

	ApplyNoise(@tm, @cfg);
	SmoothTerrain(@tm, @cfg);

	int[] values = tm.getValues();

	BuildTerrains(@map, width, height, @tm); //creates dirt tiles off values
	print("-finished-");

	//temp noise manager init
	NoiseManager::init(width, height);

	print("*SETTING ORES*");
	GenPerlinOres(@map, width, height, values, baseline);
	print("-finished-");

	print("*SETTING CAVES*");
	GenPerlinCaves(@map, width, height, values);
	print("-finished-");

	print("*SETTING PLANT LIFE*");
	//values = UpdateTerrainValues(@map, width, values);
	AddGrass(@map, values);

	//todo: change this function name to AddPlantLife. Check plant life added in terrains. 
	//SpawnTrees(@map, values);
	InitBlobInfo(@tm);
	SpawnChancedBlobs(@map, @tm);
	SpawnTrees(@tm);
	print("-finished-");

	print("*SETTING STRUCTURES*");
	BuildStructures(@tm);
	//BuildPath(Vec2f(30.0f, 30.0f), Vec2f(60.0f, 60.0f), 3, CMap::tile_gold);
	print("-finished-");

	SetupBackgrounds(map);
	return true;
}

void SetupSeed(ConfigFile@ cfg)
{
	uint seed;
	const bool rand_seed = cfg.read_bool("random_seed");

	if (rand_seed) {
		seed = getGameTime();
	}
	else {
		seed = cfg.read_u32("seed");
	}
	setSeed(seed);
}

void SetupMap(CMap@ map, int width, int height)
{
	map.CreateTileMap(width, height, 8.0f, "Sprites/world.png");
}

void SetupBackgrounds(CMap@ map)
{
	// sky

	map.CreateSky(color_black, Vec2f(1.0f, 1.0f), 200, "Sprites/Back/cloud", 0);
	map.CreateSkyGradient("Sprites/skygradient.png");   // override sky color with gradient

	// plains

	map.AddBackground("Sprites/Back/BackgroundPlains.png", Vec2f(0.0f, 0.0f), Vec2f(0.3f, 0.3f), color_white);
	map.AddBackground("Sprites/Back/BackgroundTrees.png", Vec2f(0.0f,  19.0f), Vec2f(0.4f, 0.4f), color_white);
	//map.AddBackground( "Sprites/Back/BackgroundIsland.png", Vec2f(0.0f, 50.0f), Vec2f(0.5f, 0.5f), color_white );
	map.AddBackground("Sprites/Back/BackgroundCastle.png", Vec2f(0.0f, 50.0f), Vec2f(0.6f, 0.6f), color_white);

	// fade in
	SetScreenFlash(255, 0, 0, 0);
}

bool LoadMap(CMap@ map, const string& in fileName)
{
	print("GENERATING PROCEDURAL MAP " + fileName);

	return loadMap(map, fileName);
}