//TODO make a function that performs only on predefined coordinates
bool[][] CellularAutomata(const s32 width, const s32 height, const u8 birthLimit, const u8 deathLimit, const f32 chance, const u8 steps, const bool sidesAlive = true)
{
	bool[][] cellmap;
	cellmap.set_length(width);

	for (int x = 0; x < width; x++)
	{
		cellmap[x].set_length(height);
		for (int y = 0; y < height; y++)
		{
			if (random() < chance) {
				cellmap[x][y] = true;
			}
			else {
				cellmap[x][y] = false;
			}
		}
	}

	for (int i = 0; i < steps; i++) {
		cellmap = PerformSimulationStep(width, height, cellmap, birthLimit, deathLimit, sidesAlive);
	}

	return cellmap;
}

bool[][] PerformSimulationStep(const s32 width, const s32 height, const bool[][] oldMap, const u8 birthLimit, const u8 deathLimit, const bool sidesAlive)
{
	bool[][] newMap = oldMap;

	for (int x = 0; x < width; x++)
	{
		for (int y = 0; y < height; y++)
		{
			const bool alive = oldMap[x][y];
			const u8 n_alive = CountAliveNeighbors(width, height, oldMap, x, y, sidesAlive);

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

u8 CountAliveNeighbors(const s32 width, const s32 height, bool[][] cellmap, const int x, const int y, const bool sidesAlive)
{
	u8 alive = 0;
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

			const bool onSide = (n_x < 0 || n_y < 0 || n_x > (width - 1) || n_y > (height - 1));

			if (onSide) {
				if (sidesAlive) {
					++alive;
				}
			}
			else if (cellmap[n_x][n_y]) {
				++alive;
			}
		}
	}
	return alive;
}



/*
class Cell 
{
	//bool[][] n_alive = {{false, false, false}, {false, false, false}, {false, false, false}}; 
	bool alive = false;
	u8 n_alive = 0;


	Cell(const bool a) {
		alive = a;
	}

	void setNeighbor(const bool a) {
		if (a) {
			++n_alive;
		}
	}

	bool isAlive() {
		return alive;
	}

	void setAlive(const bool a) {
		alive = a;
	}
}
*/