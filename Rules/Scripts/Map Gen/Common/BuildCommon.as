
void BuildRect(const int width, const int height, Vec2f pos, const int type, const int filltype = -1)
{
	//build from bottom left corner
	CMap@ map = getMap();
	const s32 m_width = map.tilemapwidth;

	if (filltype != -1)
	{
		for (int x = pos.x; x < (pos.x + width); x++)
		{
			for (int y = pos.y; y > (pos.y - height); y--)
			{
				if (x > pos.x && x < (pos.x + width - 1) && y < pos.y && y > (pos.y - height + 1)) {
					SetTile(@map, m_width, x, y, filltype);
				}
				else {
					SetTile(@map, m_width, x, y, type);
				}
			}
		}
	}
	else
	{
		//build horizontal tiles
		for (int x = pos.x; x < (pos.x + width); x++)
		{
			//bottom
			{
				const int y = pos.y;
				SetTile(@map, m_width, x, y, type);
			}
			//top
			{
				const int y = pos.y - height + 1;
				SetTile(@map, m_width, x, y, type);
			}
		}

		//build vertical tiles
		for (int y = pos.y - 1; y >= (pos.y - height + 1); y--)
		{
			//left
			{
				const int x = pos.x;
				SetTile(@map, m_width, x, y, type);
			}
			//right
			{
				const int x = pos.x + width - 1;
				SetTile(@map, m_width, x, y, type);
			}
		}
	}
	
}

void BuildPath(Vec2f p1, Vec2f p2, int width, int type)
{
	//calculate normal and perpendicular vectors
	Vec2f n = p1 - p2;
	n.Normalize();
	Vec2f perp = Vec2f(-n.y, n.x);

	Vec2f pos = p2;
	CMap@ map = getMap();
	const s32 m_width = map.tilemapwidth;
	//step through path 
	while ((pos - p1).Length() > 1.0f)
	{
		//const f32 offset = 40.0f;
		for (f32 i = 0; i < width; i += 0.5f)
		{
			const f32 x = pos.x + perp.x * i /*+ offset*/;
			const f32 y = pos.y + perp.y * i;
			SetTile(@map, m_width, x, y, type);
		}
		pos += (n / 2);
		//SetTile(@map, m_width, pos.x /*+ offset*/, pos.x, CMap::tile_castle);

		/*for (int i = 0; i < width; i++)
		{
			const int x = pos.x + perp.x * i;
			const int y = pos.y + perp.y * i;
			SetTile(@map, m_width, x, y, type);
		}*/
		//SetTile(@map, m_width, pos.x, pos.y, type);
	}
}