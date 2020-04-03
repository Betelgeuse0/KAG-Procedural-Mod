#include "FloodFill.as"

void GenPerlinMap(CMap@ map, const s32 map_width, const s32 map_height, const f32 threshold)
{
	NoiseManager::init(map_width, map_height);

	for (int x = 0; x < map_width; x++)
	{
		for (int y = 0; y < map_height; y++)
		{
			const f32 noise = NoiseManager::noise(x, y);
			//printInt("noise: ", noise);

			if (noise < threshold) {
				SetTile(@map, map_width, x, y, CMap::tile_empty);
			}
			else {
				SetTile(@map, map_width, x, y, CMap::tile_ground);
			}
		}
	}
}

//TODO: add a spawn chance variable in cfg
void GenPerlinWormsOnTerrain(CMap@ map, const s32 map_width, const s32 map_height, const int[] values, const u8 worm_radius, const f32 spawn_chance, TileType type)
{
	const u32 incr = 50;
	const u32 depthPercent = 20;
	//const f32 spawn_chance = 1.0f;

	for (int x = 0; x < map_width; x += incr)
	{
		const int v = values[x];
		const u32 depth = v + (depthPercent * 0.01f * v);
		//was y = depth or y = v
		for (int y = depth; y < map_height; y += incr)
		{
			if (y > v && x < map_width && y < map_height && random() < spawn_chance) {
				GenPerlinWorm(@map, map_width, map_height, values, x, y, worm_radius, type);
			}
		}
	}

	//clean up weird chunks - this could use optimization
	const u32 threshold = 25;
	TileSection@[] sections;
	bool[][] cellmap = GetCellmap(@map, map_width, map_height);

	for (int x = 0; x < map_width; x++)
	{
		const int v = values[x];
		for (int y = v; y < map_height; y++)
		{
			if (cellmap[x][y]) 
			{
				TileSection@ section = FloodFill(@map, cellmap, x, y);
				const u32 area = section.getArea();

				if (area < threshold) {
					section.fill(@map, map_width, type);
				}

				for (int i = 0; i < area; i++) //update cellmap values so we don't loop through the same sectionf
				{
					const int[] node = section.getNode(i);
					cellmap[node[0]][node[1]] = false;
				}
			}
		}
	}
}

void GenPerlinWorm(CMap@ map, const s32 map_width, const s32 map_height, const int[] values, f32 x, f32 y, const u8 worm_radius, TileType type)
{
	//NoiseManager::init(map_width, map_height);

	//get start position
	//get first point, calculate angle to second point with perlin noise, use interpolation to the second point. 
	//use (perlin?) curve function if necessary

	//starting position
	//f32 x = range(0, map_width - 1);
	//f32 y = range(0, map_height - 1);

	const u32 angle_steps = 5; // the amount it moves on each angle
	const u32 worm_steps = 50; //the number of times it calculates a new angle
	//const u32 draw_steps = 1; //the amount of angle steps to take before drawing the circle - currently not in use. could be good for optimization

	//might be able to use linear interpolation here

	for (int j = 0; j < worm_steps; j++)
	{
		//testing - random value. looks like ore pockets?
		//const f32 theta = random() * 2 * Maths::Pi;

		//border check necessary for noise and non-overlapping
		//maybe instead of breaking, iterate anyway and only generate the circle if it's within the border?
		if ((x + worm_radius) >= map_width || (x - worm_radius) < 0 || (y + worm_radius) >= map_height || (y - worm_radius) < 0) {
			break;
		}

		const f32 theta = NoiseManager::noise(x, y) * 2 * Maths::Pi;
		//gens wider caves - good for ore generation
		//const f32 theta = random() * 2 * Maths::Pi;

		for (int i = 0; i < angle_steps; i++)
		{
			const int v = values[x];

			if (((x + worm_radius) >= map_width || (x - worm_radius) < 0 || (y + worm_radius) >= map_height || (y - worm_radius) < 0) 
				|| (y < v))
			{
				break;
			}
			GenCircle(@map, map_width, x, y, worm_radius, type);

			x += Maths::Cos(theta);
			y += Maths::Sin(theta);
		}
	}

}

//TODO: add angle steps and worm steps input
//		add gradient of ores rather than depth and perhaps use perlin worms for ore chunks (for gold)
void GenPerlinOres(CMap@ map, const s32 map_width, const s32 map_height, const int[] values, const u32 baseline)
{
	//GenPerlinWormsOnTerrain(@map, map_width, map_height, values, baseline, 1, 1.0f, CMap::tile_gold);

	const f32 stone_chance = 0.3f;
	const f32 thickstone_chance = 0.1f;
	const f32 gold_chance = 0.05f;

	const int thickstone_depth = baseline + (baseline / 2);
	const int gold_depth = baseline + (baseline / 4) * 3;

	for (int x = 0; x < map_width; x++)
	{
		const int v = values[x];
		for (int y = v; y < map_height; y++)
		{
			const f32 n = NoiseManager::noise(x, y);

			if (n < gold_chance && y > gold_depth) {
				SetTile(@map, map_width, x, y, CMap::tile_gold);
			}
			else if (n < thickstone_chance && y > thickstone_depth) {
				SetTile(@map, map_width, x, y, CMap::tile_thickstone);
			}
			else if (n < stone_chance) {
				SetTile(@map, map_width, x, y, CMap::tile_stone);
			}
			
		}
	}
}

void GenPerlinCaves(CMap@ map, const s32 map_width, const s32 map_height, const int[] values)
{
	GenPerlinWormsOnTerrain(@map, map_width, map_height, values, 2, 1.0f, CMap::tile_ground_back);
}