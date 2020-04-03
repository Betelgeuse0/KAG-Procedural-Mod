#include "BuildFunctions.as"

class Room
{
	Room () {}
	int[][] nodes;

	void addNode(int[] n) {
		nodes.push_back(n);
	}

	int[] getNode(const int i) {
		return nodes[i];
	}

	int[][] getNodes() {
		return nodes;
	}

	int getArea() {
		return nodes.length;
	}

	int[][] getClosestNodes(Room@ room)
	{
		const int room_area = room.getArea();
		int[][] closestNodes = {{100000, 100000}, {100000, 100000}};
		f32 closestDist = 100000;

		for (int i = 0; i < nodes.length; i++) 
		{
			const int[] n1 = nodes[i];

			for (int j = 0; j < room_area; j++)
			{
				const int[] n2 = room.getNode(j);
				const f32 dist = GetNodeDistance(n1, n2);

				if (dist < closestDist) {
					closestNodes[0] = n1;
					closestNodes[1] = n2;
					closestDist = dist;
				}
			}
		}
		return closestNodes;
	}

	int[][] getClosestNodes(const int[] values)
	{
		int[][] closestNodes = {{100000, 100000}, {100000, 100000}};
		f32 closestDist = 100000;

		for (int i = 0; i < nodes.length; i++) 
		{
			const int[] n1 = nodes[i];

			for (int j = 0; j < values.length; j++)
			{
				const int[] n2 = {j, values[j]};
				const f32 dist = GetNodeDistance(n1, n2);

				if (dist < closestDist) {
					closestNodes[0] = n1;
					closestNodes[1] = n2;
					closestDist = dist;
				}
			}
		}
		return closestNodes;
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