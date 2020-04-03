#include "CellularAutomata"
//TODO: add cfg support for chance variable with each ore
//		add "density" values for stone. i.e thickstone spawns in the middle of a stone chunk
//		increase ore chance variable the deaper it's spawned so that there will be more near the bottom of the map
//		calculate gradient steps based on map height ex) 4 gradient steps works well with a height of 100
void SpawnOres(CMap@ map, const s32 width, const s32 height,  const int[] values)
{
	u8 birthLimit = 5;
	u8 deathLimit = 3;
	f32 chanceTarget = 0.58f;
	u8 gradientSteps = 4;
	u8 steps = 3;

	const s32 height_step = height / gradientSteps;

	SpawnOre(@map, width, values, height_step, chanceTarget, gradientSteps, birthLimit, deathLimit, steps, CMap::tile_stone);

	chanceTarget = 0.36f;
	SpawnOre(@map, width, values, height_step, chanceTarget, gradientSteps, birthLimit, deathLimit, steps, CMap::tile_gold);
	
}

void SpawnOre(CMap@ map, const s32 width, const int[] values, const s32 height_step, const f32 chanceTarget, const u8 gradientSteps, const u8 birthLimit, const u8 deathLimit, const u8 steps, TileType type)
{
	for (int i = 1; i <= gradientSteps; i++)
	{
		const f32 chance = (chanceTarget / gradientSteps) * i;
		const s32 depth = height_step * i;

		const bool[][] cellmap = CellularAutomata(width, height_step, birthLimit, deathLimit, chance, steps, false);

		for (int x = 0; x < width; x++)
		{
			const int v = values[x];

			for (int y = 0; y < height_step; y++)
			{
				const int posy = y + (depth - height_step);

				if (posy >= v && cellmap[x][y]) {
					SetTile(@map, width, x, posy, type);
				}
			}
		}
	}
}