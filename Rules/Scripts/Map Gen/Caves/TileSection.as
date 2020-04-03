
//similar to room class but used for solid tiles
class TileSection
{
	TileSection(){}

	int[][] nodes;

	void addNode(int[] n) {
		nodes.push_back(n);
	}

	int[] getNode(const int i) {
		return nodes[i];
	}

	u32 getArea() {
		return nodes.length;
	}

	void fill(CMap@ map, const s32 map_width, TileType type)
	{
		for (int i = 0; i < nodes.length; i++) {
			const int[] node = nodes[i];
			const int x = node[0];
			const int y = node[1];

			SetTile(@map, map_width, x, y, type);
		}
	}
}