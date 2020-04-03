//terrain gen
#include "BuildFunctions.as"
#include "Terrains.as"

void ApplyNoise(TerrainManager@ tm, ConfigFile@ cfg)
{
	int[] values = tm.getValues();

	for (int x = 0; x < values.length; x++)
	{
		u32 noise_height;

		//get noise value
		const int type = tm.getTerrainAtX(x).getType();

		switch (type)
		{
			case terrain::plains: 			noise_height = cfg.read_u32("plains_noise_height"); break;
			case terrain::plains_flower: 	noise_height = cfg.read_u32("plains_flower_noise_height"); break;
			case terrain::mountains: 		noise_height = cfg.read_u32("mountains_noise_height"); break;
			case terrain::mountains_rocky:	noise_height = cfg.read_u32("mountains_rocky_noise_height"); break;
			case terrain::forest: 			noise_height = cfg.read_u32("forest_noise_height");
			case terrain::forest_pine: 		noise_height = cfg.read_u32("forest_pine_noise_height"); break;
			default: 						noise_height = cfg.read_u32("noise_height");
		}

		//white noise
		int y = values[x] - ranged(noise_height + 1);
		values[x] = y;
	}

	//red noise
	for (int x = 0; x < values.length - 1; x++)
	{
		const int y = (values[x] + values[x + 1]) / 2;
		values[x] = y;
	}
	//the last tile height
	const int y = (values[values.length - 1] + values[values.length - 2]) / 2;
	values[values.length - 1] = y;

	tm.setValues(values);
}

void SmoothTerrain(TerrainManager@ tm, ConfigFile@ cfg)
{
	int[] values = tm.getValues();

	for (int i = 0; i < tm.getTerrainCount(); i++)
	{
		u32 cycles;
		Terrain@ t = tm.getTerrain(i);
		const int type = t.getType();

		if (t.getSectorCount() == 0) continue;

		switch (type)
		{
			case terrain::plains: 			cycles = cfg.read_u32("plains_smooth_cycles"); break;
			case terrain::plains_flower: 	cycles = cfg.read_u32("plains_flower_smooth_cycles"); break;
			case terrain::mountains: 		cycles = cfg.read_u32("mountains_smooth_cycles"); break;
			case terrain::mountains_rocky:	cycles = cfg.read_u32("mountains_rocky_smooth_cycles"); break;
			case terrain::forest:			cycles = cfg.read_u32("forest_smooth_cycles"); break;
			case terrain::forest_pine:		cycles = cfg.read_u32("forest_pine_smooth_cycles"); break;
			default: 						cycles = cfg.read_u32("smooth_cycles");
		}

		//loop through terrain sector and apply the smooth cycles
		for (int j = 0; j < t.getSectorCount(); j++)
		{
			int[] sector = t.getSector(j);
			const int x1 = sector[0];
			const int x2 = sector[1];

			for (int x = x1; x < x2 - 1; x++)
			{
				const int y = (values[x] + values[x + 1]) / 2;
				values[x] = y;
			}
			//last column
			const int y = (values[x2 - 1] + values[x2 - 2]) / 2;
			values[x2 - 1] = y;
		}
	}
	tm.setValues(values);
}

bool isMountain(Terrain@ t)
{
	return t.getType() == terrain::mountains || t.getType() == terrain::mountains_rocky;
}

TerrainManager@ GetWaveTerrain(CMap@ map, const s32 map_width, const s32 baseline, ConfigFile@ cfg)
{
	const int default_type = cfg.read_s32("default_terrain");
	const int terrain_size = cfg.read_s32("terrain_size");

	//TERRAINS
	//Amplitudes and Period Factors
	
	int[] a = {1, 2};
	int[] a1 = {10, 25};
	int[] a2 = {1, 4};
	int[] p = {5, 8};
	int[] p1 = {4, 10};

	Terrain@[] terrains =
	{ 
		@Terrain (terrain::plains, a, p),
		@Terrain (terrain::plains_flower, a, p),
		@Terrain (terrain::mountains, a1, p1),
		@Terrain (terrain::mountains_rocky, a1, p1),
		@Terrain (terrain::forest, a2, p),
		@Terrain (terrain::forest_pine, a2, p)
	};

	TerrainManager tm(terrains);
	Terrain@ terrain;

	if (default_type >= 0) {
		@terrain = tm.getTerrainByType(default_type);
	}
	else {
		//get a random terrain
		const int index = ranged(tm.getTerrainCount());
		@terrain = tm.getTerrain(index);
	}

	int posx = 0;
	int lastx = 0;
	int size = 0;
	u8 phase = 0;
	int[] waveValues;

	while (posx < map_width)
	{

		const u32 amplitude = terrain.getAmplitude();
		const u32 period_factor = terrain.getPeriodFactor();
		const bool mountain = isMountain(@terrain);
		const u32 amp_incr = mountain ? terrain.getAmplitudeValue(1) : 0;

		const int[] wv = GenWaveValues(@map, map_width, period_factor, amplitude, phase);
		size += wv.length;

		for (int x = 0; x < wv.length; x++) 
		{
			if (posx == map_width) break;

			const int v = wv[x];
			const int y = v + baseline - amp_incr;

			++posx;

			//note: pushing back v creates accidental "noisy" sky islands
			waveValues.push_back(y);
		}

		//do last terrain sector and break
		if (posx == map_width) {
			const int[] sector = {lastx, posx};
			terrain.addSector(sector);
			break;
		}

		//todo: instead of getting a completely random terrain get a new one that hasn't been used (if possible)
		//gets a different terrain if we're not using default

		//if the current terrain is mountain, make sure we're on phase 1 before transition
		if (default_type < 0 && size >= terrain_size && (!mountain || (mountain && phase == 1)))
		{
			const int[] sector = {lastx, posx};
			terrain.addSector(sector);
			lastx = posx + 1;
			size = 0;
			Terrain@ lastTerrain = @terrain;
			while (lastTerrain.getType() == terrain.getType())
			{
				const int index = ranged(tm.getTerrainCount());
				@terrain = tm.getTerrain(index);
			}
		}

		//if the new terrain is a mountain
		//	then phase will equal 1
		const bool transition = size == 0;

		phase = (phase == 0 ? 1 : 0);

		if (transition) 
		{
			if (isMountain(@terrain)) {
				phase = 1;
			}
		}
	}

	tm.setValues(waveValues);
	return @tm;
}


int[] GenWaveValues(CMap@ map, const s32 map_width, const u32 period_factor, const u32 amplitude, const u8 phase)
{
	const f32 periodf = period_factor;
	const f32 period = 2.0f * Maths::Pi * period_factor;
	const f32 half_period = period / 2.0f;
	int startx;
	int endx;
	int[] waveValues;

	if (phase == 0) {
		startx = 0;
		endx = half_period;
	}
	else {
		startx = half_period;
		endx = period;
	}

	for (int x = startx; x < endx; x++)
	{
		const int y = Maths::Sin(x / periodf) * amplitude;
		waveValues.push_back(y);
	}

	return waveValues;
}

//FLORA
//TODO: add cfg support for grass type (lengths)
//		change grass spawn frequency based on elevation
void AddGrass(CMap@ map, const int[] values)
{
	const s32 width = values.length;

	for (int x = 0; x < width; x++)
	{
		const int y = values[x];
		Tile tile = GetTile(@map, width, x, y);

		if (map.isTileGround(tile.type)) {
			TileType grass = CMap::tile_grass + 1 + ranged(3);
			SetTile(@map, width, x, y - 1, grass);
		}
	}
}

//TODO: add cfg support for trees variables
//		take advantage of trees_min. consider adding a trees_dist variable
//		spawn trees with brownian noise so that they are evenly distributed
//		check the value v at each x so that we know if there's a cave or not
//		change spawn rate baseed on elevation
void SpawnTrees(CMap@ map, const int[] values)
{
	//spawn_freq = float that represents percentage. ex) 0.2f = 20% of the landscape is trees
	//spacing = number based on spawn_freq. spacing = map_width / `(map_width * spawn_freq)
	const f32 spawn_freq = 0.1f;
	const u32 spacing =  1 / spawn_freq;
	const f32 spawn_chance = 0.2f;

	const int width = values.length;

	for (int x = 0; x < values.length; x += spacing)
	{
		const int y = values[x];
		Tile tile = GetTile(@map, width, x, y);

		if (map.isTileGround(tile.type) && random() < spawn_chance) {
			SpawnTree(x, y - 1);
		}
	}
}

void SpawnTrees(TerrainManager@ tm)
{
	int[] values = tm.getValues();

	for (int i = 0; i < tm.getTerrainCount(); i++)
	{
		Terrain@ t = tm.getTerrain(i);

		BlobInfo@ tree = t.getBlobInfoByName("tree_bushy");
		BlobInfo@ tree_pine = t.getBlobInfoByName("tree_pine");

		if (tree !is null && tree_pine !is null)
		{
			//spawn one of the two
			ranged(2) == 0 ? SpawnSpacedBlobsInSectors(values, @t, @tree) : SpawnSpacedBlobsInSectors(values, @t, @tree_pine);
		}
		else if (tree !is null)
		{
			SpawnSpacedBlobsInSectors(values, @t, @tree);
		}
		else if (tree_pine !is null)
		{
			SpawnSpacedBlobsInSectors(values, @t, @tree_pine);
		}
	}
}

//spawns chanced & spaced blobs
void SpawnSpacedBlobsInSectors(int[] values, Terrain@ t, BlobInfo@ b)
{
	CMap@ map = getMap();
	for (int i = 0; i < t.getSectorCount(); i++)
	{
		int[] sector = t.getSector(i);
		int x1 = sector[0];
		int x2 = sector[1];

		for (int x = x1; x < x2; x += b.getSpacing())
		{
			const int y = values[x];
			Vec2f pos = Vec2f(x, y - 1) * 8.0f;
			Tile tile = GetTile(@map, map.tilemapwidth, x, y);

			if (isPlant(b.name)) 
			{
				if (map.isTileGround(tile.type)) {
					b.CreateChanced(pos);
				}
			}
			else if (map.isTileSolid(tile.type))
			{
				b.CreateChanced(pos);
			}
		}
	}
}

CBlob@ SpawnTree(f32 x, f32 y, const string name = "tree_bushy")
{
	Vec2f pos(x, y);
	CBlob@ tree = server_CreateBlobNoInit(name);

	if (tree !is null)
	{
		tree.Tag("startbig");
		tree.setPosition(pos);
		tree.Init();
	}
	return @tree;
}

bool isTree(const string name)
{
	return name == "tree_bushy" || name == "tree_pine";
}

bool isPlant(const string name)
{
	return (name == "flowers" || name == "bush" || isTree(name));
}

void InitBlobInfo(TerrainManager@ tm)
{
	int[] spacing = {2, 4};

	BlobInfo chicken("chicken", -1, 0.05f);
	BlobInfo bison("bison", -1, 0.01f);
	BlobInfo bush("bush", -1, 0.1f);
	BlobInfo flower("flowers", -1, 0.3f);
	BlobInfo tree("tree_bushy", -1, 0.05f, spacing);
	BlobInfo tree_pine("tree_pine", -1, 0.05f, spacing);
	BlobInfo tree_forest("tree_bushy", -1, 0.6f, spacing);
	BlobInfo tree_pine_forest("tree_pine", -1, 0.6f, spacing);

	{	//plains
		BlobInfo@[] info = {@chicken, @bison, @tree};
		tm.addBlobInfoToType(terrain::plains, info);
	}
	{	//plains flowers
		BlobInfo@[] info = {@chicken, @bison, @bush, @flower, @tree};
		tm.addBlobInfoToType(terrain::plains_flower, info);
	}
	{
		//mountains
		BlobInfo@[] info = {@tree_pine, @bush};
		tm.addBlobInfoToType(terrain::mountains, info);
	}
	{
		//forest
		BlobInfo@[] info = {@tree_forest, @bush};
		tm.addBlobInfoToType(terrain::forest, info);
	}
	{
		//pine forest
		BlobInfo@[] info = {@tree_pine_forest, @bush};
		tm.addBlobInfoToType(terrain::forest_pine, info);
	}
}

void SpawnChancedBlobs(CMap@ map, TerrainManager@ tm)
{
	const int[] values = tm.getValues();
	
	for (int x = 0; x < values.length; x++)
	{
		const int y = values[x];
		Vec2f pos = Vec2f(x, y - 0.5) * 8.0f;
		//tm.CreateRandomBlobChancedAtX(x, pos * 8.0f);

		Terrain@ t = tm.getTerrainAtX(x);
		const int count = t.getBlobInfoCount();
		BlobInfo@ info;

		if (count > 0)
		{
			const int index = ranged(count);
			@info = t.getBlobInfo(index);
		}

		if (info !is null && !isTree(info.name))
		{
			Tile tile = GetTile(@map, map.tilemapwidth, x, y);

			if (isPlant(info.name)) 
			{
				pos.y -= 1;
				if (map.isTileGround(tile.type)) {
					info.CreateChanced(pos);
				}
			}
			else if (map.isTileSolid(tile.type))
			{
				info.CreateChanced(pos);
			}
		}

	}
}
