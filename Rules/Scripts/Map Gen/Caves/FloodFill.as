
Room@ FloodFill(bool[][] cellmap, const int posx, const int posy)
{
	int[] node = {posx, posy};
	cellmap[posx][posy] = true;

	Room room;
	room.addNode(node);
	int[][] q;
	q.push_back(node);

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

TileSection@ FloodFill(CMap@ map, bool[][] cellmap, const int posx, const int posy)
{
	//int[][] cellmap = GetCellmap(@map, map_width, map_height);

	int[] node = {posx, posy};
	cellmap[posx][posy] = false;

	TileSection section;
	section.addNode(node);
	int[][] q;
	q.push_back(node);

	while(!q.empty())
	{
		const int x = q[0][0];
		const int y = q[0][1];
		q.removeAt(0);

		const bool west = !((x - 1 < 0) || !cellmap[x - 1][y]);
		const bool east = !((x + 1 > cellmap.length - 1) || !cellmap[x + 1][y]);
		const bool north = !((y - 1 < 0) || !cellmap[x][y - 1]);
		const bool south = !((y + 1 > cellmap[0].length - 1) || !cellmap[x][y + 1]);

		if (west) {
			int[] n = {x - 1, y};
			q.push_back(n);
			section.addNode(n);
			cellmap[x - 1][y] = false;
		}

		if (east) {
			int[] n = {x + 1, y};
			q.push_back(n);
			section.addNode(n);
			cellmap[x + 1][y] = false;
		}

		if (north) {
			int[] n = {x, y - 1};
			q.push_back(n);
			section.addNode(n);
			cellmap[x][y - 1] = false;
		}

		if (south) {
			int[] n = {x, y + 1};
			q.push_back(n);
			section.addNode(n);
			cellmap[x][y + 1] = false;
		}
	}
	return @section;
}

void FloodFill(CMap@ map, bool[][] cellmap, const int posx, const int posy, TileType type)
{
	int[] node = {posx, posy};
	cellmap[posx][posy] = true;
	//NOTE: may need to get map width rather than using cellmap.length in case they are using a cellmap smaller than map dimensions
	SetTile(@map, cellmap.length, node[0], node[1], type);

	int[][] q;
	q.push_back(node);

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
			cellmap[x - 1][y] = true;
			SetTile(@map, cellmap.length, n[0], n[1], type);
		}

		if (east) {
			int[] n = {x + 1, y};
			q.push_back(n);
			cellmap[x + 1][y] = true;
			SetTile(@map, cellmap.length, n[0], n[1], type);
		}

		if (north) {
			int[] n = {x, y - 1};
			q.push_back(n);
			cellmap[x][y - 1] = true;
			SetTile(@map, cellmap.length, n[0], n[1], type);
		}

		if (south) {
			int[] n = {x, y + 1};
			q.push_back(n);
			cellmap[x][y + 1] = true;
			SetTile(@map, cellmap.length, n[0], n[1], type);
		}
	}
}


bool[][] GetCellmap(CMap@ map, const s32 map_width, const s32 map_height)
{
	bool[][] cellmap;
	cellmap.set_length(map_width);

	for (int x = 0; x < map_width; x++)
	{
		cellmap[x].set_length(map_height);
		for (int y = 0; y < map_height; y++)
		{
			if (isTileSolid(@map, map_width, x, y)) {
				cellmap[x][y] = true;
			}
			else {
				cellmap[x][y] = false;
			}
		}
	}
	return cellmap;
}