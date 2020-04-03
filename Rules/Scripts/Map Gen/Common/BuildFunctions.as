#include "BuildCommon.as"
//todo: spawn ores here so they're biome specific.
//		change setTilesUnderPoint function or add a function so that it sets the biome-specific tiles
void BuildTerrains(CMap@ map, const s32 map_width, const s32 map_height, TerrainManager@ tm)
{
	const int[] values = tm.getValues();

	for (int x = 0; x < values.length; x++)
	{
		const int y = values[x];
		SetTilesUnderPoint(@map, map_width, map_height, x, y, CMap::tile_ground);
	}

	/*tile pseudocode
		loop through terrains
		get terrain type
		place terrain type tiles down only a cirtain depth. 

		if (type == rocky mountain)
			place more rocks
	*/

	const int depth = 20; //20 tiles deep
	//todo: place various tiles - not just stone
	for (int i = 0; i < tm.getTerrainCount(); i++)
	{
		Terrain@ t = tm.getTerrain(i);

		if (t.getType() == terrain::mountains_rocky)
		{
			//get sectors
			//loop through x to get values
			//continue placing rocks a certain depth from values
			TerrainTileInfo@[] info = {
				@TerrainTileInfo(CMap::tile_stone, 0.6f),
				@TerrainTileInfo(CMap::tile_stone_d1, 0.8f),
				@TerrainTileInfo(CMap::tile_thickstone_d1, 0.3f)
			};

			t.placeTilesInSectors(values, info, map_width, depth, false);
		}
	}

}

void BuildCaves(CMap@ map, const s32 map_width, const s32 map_height, const bool[][] cellmap, const int[] values, const int depthPercent)
{
	//place empty tiles
	for (int x = 0; x < map_width; x++)
	{
		const int v = values[x];
		const int depth = v + (depthPercent * 0.01f * v);

		for (int y = depth; y < map_height; y++)
		{
			const bool alive = cellmap[x][y];

			if (!alive) {
				SetTile(@map, map_width, x, y, CMap::tile_ground_back);
			}
		}
	}
}

void SetTile(CMap@ map, const s32 width, const int x, const int y, TileType type)
{
	const u32 offset = x + y * width;
	map.SetTile(offset, type);
}

Tile GetTile(CMap@ map, const s32 width, const int x, const int y) 
{
	const u32 offset = x + y * width;
	Tile tile = map.getTile(offset);
	return tile;
}

void SetTilesUnderPoint(CMap@ map, const s32 width, const s32 height, const int x, const int y, TileType type)
{
	//NOTE: this does not create tiles underneath certain points (good for underworld?)
	/*for (int i = 0; i < y; i++)
	{
		const u32 offset = x + (y + i) * width;
		map.SetTile(offset, type);
	}*/

	for (int i = y; i < height; i++)
	{
		const u32 offset = x + i * width;
		map.SetTile(offset, type);
	}
}

void SetTilesUnderPoint(CMap@ map, s32 width, s32 height, int x, int y, TerrainTileInfo@[] infos, bool tileAlways = true)
{
	for (int i = y; i < height; i++)
	{
		int type = -1;

		const int index = ranged(infos.length);
		TerrainTileInfo@ info = infos[index];

		if (random() < info.chance) {
			type = info.type;
		}
		else if (tileAlways) 
		{
			while (true)
			{
				const int index = ranged(infos.length);
				TerrainTileInfo@ info = infos[index];

				if (random() < info.chance) {
					type = info.type;
					break;
				}
			}
		}

		if (type >= 0) 
		{
			const u32 offset = x + i * width;
			map.SetTile(offset, type);
		}
	}
}

//generates more of a rounded-edged square
//todo: implement edge checking
void GenCircle(CMap@ map, const s32 width, const int x, const int y, const f32 radius, TileType type)
{
	for (int i = (x - radius); i <= (x + radius); i++)
	{
		for (int j = (y - radius); j <= (y + radius); j++)
		{
			const f32 dist = Maths::Sqrt(Maths::Pow(i - x, 2) + Maths::Pow(j - y, 2));

			//printFloat("dist: ", dist);
			if (dist <= radius) {
				SetTile(@map, width, i, j, type);
			}
		}
	}
}

bool isTileSolid(CMap@ map, const s32 width, const int x, const int y)
{
	const u32 offset = x + y * width;
	Tile tile = map.getTile(offset);
	return map.isTileSolid(tile);
}