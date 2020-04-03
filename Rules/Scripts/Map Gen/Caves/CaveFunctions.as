//cave gen
#include "mathFunctions.as"
#include "SpawnOres.as"

//TODO: update cellmap after you create pathways so ores can't spawn in the pathways
bool[][] GetCellmapOnTerrain(CMap@ map, const s32 map_width, const s32 map_height, const int[] values, const u8 depthPercent)
{
	bool[][] cellmap;
	cellmap.set_length(map_width);

	const f32 emptyChance = 0.5f;
	const u8 steps = 5;
	const u8 birthLimit = 4; 
	const u8 deathLimit = 3; 

	//build based off cellmap
	for (int x = 0; x < map_width; x++)
	{
		const int v = values[x];
		cellmap[x].set_length(map_height);

		for (int y = 0; y < map_height; y++)
		{
			if (y < v) {
				cellmap[x][y] = false;
			}
			else {
				cellmap[x][y] = true;
			}
		}
	}

	//create random empty tiles
	for (int x = 0; x < map_width; x++)
	{
		const int v = values[x];
		const int depth = v + (depthPercent * 0.01f * v);

		for (int y = depth; y < map_height; y++)
		{
			const bool alive = cellmap[x][y];

			/*if (alive && random.NextRanged(101) * 0.01f < emptyChance) {
				cellmap[x][y] = false;
			}*/
			if (alive && random() < emptyChance) {
				cellmap[x][y] = false;
			}
		}
	}

	//create caves with cellular automata
	for (int i = 0; i < steps; i++) {
		cellmap = PerformSimulationStep(cellmap, birthLimit, deathLimit, values, depthPercent);
	}

	Room@[] caves = GetCaves(values, cellmap, depthPercent);

	//temporary radius
	const f32 caveDist = 4.0f;
	const f32 surfaceDist = 8.0f;
	CreatePathways(@map, map_width, values, surfaceDist, caves, caveDist);

	return cellmap;
}

//TODO: cfg options for tunnel width, area threshold, radius, and fill
//		make it so once caves are connected it replaces the two room objects with a new room object with updated area / values. 
//		this will make it easier to tell if a cave is too big or not
void CreatePathways(CMap@ map, const s32 map_width, const int[] values, const f32 surfaceDist, Room@[] caves, const f32 caveDist)
{
	//temporary areaThresholds & tunnelWidth
	const int areaThreshold_min = 30;	//caves with area below this number will not connect
	const int areaThreshold_max = 1000; //caves with area over this number will not connect
	const int tunnelRadius = 1; //note widths will not always be exact

	for (int i = 0; i < caves.length; i++)
	{
		Room@ cave = caves[i];
		const int area = cave.getArea();

		if (area < areaThreshold_min) {
			//cave.fill(@map, map_width, CMap::tile_ground);
			continue;
		}

		if (area < areaThreshold_max) 
		{
			for (int j = i + 1; j < caves.length; j++)
			{
				Room@ c = caves[j];
				const int a = c.getArea();

				if (a >= areaThreshold_max || a < areaThreshold_min) {
					continue;
				}

				const int[][] nodes = cave.getClosestNodes(c);
				const int[] n1 = nodes[0];
				const int[] n2 = nodes[1];
				const f32 dist = GetNodeDistance(n1, n2);

				if (dist < caveDist) {
					CreatePathway(@map, map_width, n1, n2, tunnelRadius);
				}
			}
		}

		//for i in values: get closest nodes to cave and connect if they are within surface radius
		const int[][] nodes = cave.getClosestNodes(values);
		const int[] n1 = nodes[0];
		const int[] n2 = nodes[1];
		const f32 dist = GetNodeDistance(n1, n2);

		if (dist < surfaceDist) {
			CreatePathway(@map, map_width, n1, n2, tunnelRadius, true);
		}
	}
}

/*
	3 ways to do this:
		* minus position vectors and get angle of new vector. increment on sin and cos of that angle 
		* calculate angle between two points using trig. increment on sin and cos of that angle
		* calculate derivative (slope) and increment on slope. 
	NOTE: you might be able to calculate distance between two points by incrementing on a slope
*/

//TODO: make it so tunnelWidth is used
void CreatePathway(CMap@ map, const s32 map_width, const int[] n1, const int[] n2, const int tunnelRadius, const bool surfacePath = false)
{
	//calculate slope and increment on that slope
	const int x1 = n1[0];
	const int y1 = n1[1];
	const int x2 = n2[0];
	const int y2 = n2[1];

	f32 slope_x = x2 - x1; 
	f32 slope_y = y2 - y1;
	f32 absSlope_x = Maths::Abs(slope_x);
	f32 absSlope_y = Maths::Abs(slope_y);

	//TODO: check for negatives
	if (absSlope_x > 1 || absSlope_y > 1)
	{
		if (absSlope_x > absSlope_y) {
			slope_y /= absSlope_x; 
			slope_x = Sign(slope_x);
		}
		else {
			slope_x /= absSlope_y;
			slope_y = Sign(slope_y);
		}
	}

	//get perpendicular line (reciprocal)
	//const f32 perp_x = -slope_y;
	//const f32 perp_y = slope_x;
	//f32 posx = x1;
	//f32 posy = y1;

	//carve method
	//f32 posx = x1 + slope_x;
	//f32 posy = y1 + slope_y;
	f32 posx = x1;
	f32 posy = y1;
	const int dist = GetNodeDistance(n1, n2);

	for (int i = 0; i < dist + 1; i++)
	{
		//carve around pos tile
		for (int x = -tunnelRadius; x < tunnelRadius + 1; x++)
		{
			for (int y = -tunnelRadius; y < tunnelRadius + 1; y++)
			{
				const int stepx = posx + x;
				const int stepy = posy + y;
				
				if (i < dist || !surfacePath) {
					SetTile(@map, map_width, stepx, stepy, CMap::tile_ground_back);
				}
				else {
					SetTile(@map, map_width, stepx, stepy, CMap::tile_empty);
				}
			}
		}
		posx += slope_x;
		posy += slope_y;
	}

	/*while (!((Maths::Ceil(posx) == x2 && Maths::Ceil(posy) == y2) || (Maths::Floor(posx) == x2 && Maths::Floor(posy) == y2)))
	{
		//carve around pos tile
		for (int x = -tunnelRadius; x < tunnelRadius + 1; x++)
		{
			for (int y = -tunnelRadius; y < tunnelRadius + 1; y++)
			{
				const int stepx = posx + x;
				const int stepy = posy + y;
				
				SetTile(@map, map_width, stepx, stepy, CMap::tile_empty);
			}
		}
		posx += slope_x;
		posy += slope_y;
		



		//perpendicular line method
		/*posx += slope_x * 0.5f;
		posy += slope_y * 0.5f;
		//do half the step to solve the 45 degree angle problem
		SetTile(@map, map_width, posx, posy, CMap::tile_castle);
		const u32 len = (tunnelWidth / 2) + 1;
		for (int i = 1; i < len; i++)
		{
			const int stepx = perp_x * i;
			const int stepy = perp_y * i;
			SetTile(@map, map_width, posx + stepx, posy + stepy, CMap::tile_empty);
			SetTile(@map, map_width, posx - stepx, posy - stepy, CMap::tile_empty);
		}*/
	//}
}



f32 GetNodeDistance(int[] node1, int[] node2) 
{
	int x1 = node1[0];
	int y1 = node1[1];
	int x2 = node2[0];
	int y2 = node2[1];

	return Maths::Sqrt(Maths::Pow((x2 - x1), 2) + Maths::Pow((y2 - y1), 2));
}

Room@[] GetCaves(const int[] values, bool[][] cellmap, const u8 depthPercent)
{
	//search cellmap
	//if we have a "false" cell, use floodfill to get room. 
	//set next search x value to the cell of the right of the room. 

	Room@[] caves;
	for (int x = 0; x < cellmap.length; x++)
	{
		const int v = values[x];
		const int depth = v + (depthPercent * 0.01f * v);

		for (int y = depth; y < cellmap[0].length; y++)
		{
			//testing
			const bool empty = !cellmap[x][y];

			if (empty) 
			{
				Room@ cave = GetRoom(x, y, cellmap);
				caves.push_back(cave);

				for (int i = 0; i < cave.getArea(); i++) //update cellmap values so we don't loop through the same cave
				{
					const int[] node = cave.getNode(i);
					cellmap[node[0]][node[1]] = true;
				}
			}
		}
	}

	return caves;
}

//uses floodfill
Room GetRoom(const int posx, const int posy, bool[][] cellmap)
{
	int[] node = {posx, posy};
	cellmap[posx][posy] = true;

	Room room;
	room.addNode(node);
	int[][] q;
	q.push_back(node);


	//testing
	//room.addNode(q[0]);
	//return room;

	while(!q.empty())
	{
		const int x = q[0][0];
		const int y = q[0][1];
		q.removeAt(0);

		const bool west = !((x - 1 < 0) || cellmap[x - 1][y]);
		const bool east = !((x + 1 > cellmap.length - 1) || cellmap[x + 1][y]);
		const bool north = !((y - 1 < 0) || cellmap[x][y - 1]);
		const bool south = !((y + 1 > cellmap[0].length - 1) || cellmap[x][y + 1]);

		if (west) {
			int[] n = {x - 1, y};
			q.push_back(n);
			room.addNode(n);
			cellmap[x - 1][y] = true;
		}

		if (east) {
			int[] n = {x + 1, y};
			q.push_back(n);
			room.addNode(n);
			cellmap[x + 1][y] = true;
		}

		if (north) {
			int[] n = {x, y - 1};
			q.push_back(n);
			room.addNode(n);
			cellmap[x][y - 1] = true;
		}

		if (south) {
			int[] n = {x, y + 1};
			q.push_back(n);
			room.addNode(n);
			cellmap[x][y + 1] = true;
		}
	}
	return room;
} 

//cave world
void GenCaveWorld(CMap@ map, const s32 map_width, const s32 map_height)
{
	bool[][] cellmap;
	cellmap.set_length(map_width);
	const f32 aliveChance = 0.5f;
	const u8 steps = 7;
	const u8 birthLimit = 4; 
	const u8 deathLimit = 3; 

	/*Random@ random = Random();
	uint seed = getGameTime();
	random.Reset(seed);*/

	for (int x = 0; x < map_width; x++)
	{
		cellmap[x].set_length(map_height);
		for (int y = 0; y < map_height; y++)
		{
			/*if (random.NextRanged(101) * 0.01f < aliveChance) {
				cellmap[x][y] = true;
			}*/
			if (random() < aliveChance) {
				cellmap[x][y] = true;
			}
			else {
				cellmap[x][y] = false;
			}
		}
	}

	for (int i = 0; i < steps; i++) {
		cellmap = PerformSimulationStep(cellmap, birthLimit, deathLimit);
	}
	
	for (int x = 0; x < map_width; x++)
	{
		for (int y = 0; y < map_height; y++)
		{
			const bool alive = cellmap[x][y];

			if (alive) {
				SetTile(@map, map_width, x, y, CMap::tile_ground);
			}
			else {
				SetTile(@map, map_width, x, y, CMap::tile_empty);
			}
		}
	}
}

u8 CountAliveNeighbors(bool[][] cellmap, const int x, const int y)
{
	int alive = 0;
	for (int i = -1; i < 2; i++)
	{
		for (int j = -1; j < 2; j++)
		{
			const int n_x = x + i;
			const int n_y = y + j;

			//don't count this cell
			if (i == 0 && j == 0) {
				continue;
			}

			if ((n_x < 0 || n_y < 0 || n_x > (cellmap.length - 1) || n_y > (cellmap[0].length - 1)) ||
				(cellmap[n_x][n_y]))
			{
				++alive;
			}
		}
	}
	return alive;
}

bool[][] PerformSimulationStep(const bool[][] oldMap, const u8 birthLimit, const u8 deathLimit, int[] values, const u8 depthPercent)
{
	bool[][] newMap = oldMap;
	//newMap.set_length(oldMap.length);
	const int height = oldMap[0].length;

	for (int x = 0; x < oldMap.length; x++)
	{
		//newMap[x].set_length(height);
		const int v = values[x];
		const int depth = v + (depthPercent * 0.01f * v);

		for (int y = depth; y < height; y++)
		{
			const bool alive = oldMap[x][y];
			const u8 n_alive = CountAliveNeighbors(oldMap, x, y);

			if (alive)
			{
				if (n_alive > deathLimit) {
					newMap[x][y] = true;
				}
				else {
					newMap[x][y] = false;
				}
			}
			else 
			{
				if (n_alive > birthLimit) {
					newMap[x][y] = true;
				}
				else {
					newMap[x][y] = false;
				}
			}
		}
	}
	return newMap;
}

//used for cave world
bool[][] PerformSimulationStep(const bool[][] oldMap, const u8 birthLimit, const u8 deathLimit)
{
	bool[][] newMap;
	newMap.set_length(oldMap.length);
	const int height = oldMap[0].length;

	for (int x = 0; x < oldMap.length; x++)
	{
		newMap[x].set_length(height);
		for (int y = 0; y < height; y++)
		{
			const bool alive = oldMap[x][y];
			const u8 n_alive = CountAliveNeighbors(oldMap, x, y);

			if (alive)
			{
				if (n_alive > deathLimit) {
					newMap[x][y] = true;
				}
				else {
					newMap[x][y] = false;
				}
			}
			else 
			{
				if (n_alive > birthLimit) {
					newMap[x][y] = true;
				}
				else {
					newMap[x][y] = false;
				}
			}
		}
	}
	return newMap;
}