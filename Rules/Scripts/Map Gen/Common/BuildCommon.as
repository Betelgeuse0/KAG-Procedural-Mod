
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
	//calculate normal
	Vec2f n = p1 - p2;

	//if the vector angle is greater than 90 degrees and less than 270 degrees then
	//reverse the vector direction so we're building on the right side

	const f32 angle = n.getAngleDegrees();
	Vec2f pos1 = p2;
	Vec2f pos2 = p1;

	if (angle < 90.0f || angle > 270.0f) {
		n = p2 - p1;
		pos1 = p1;
		pos2 = p2;
	}
	n.Normalize();

	//calculate perpendicular vector
	Vec2f perp = Vec2f(-n.y, n.x);
	CMap@ map = getMap();
	const s32 m_width = map.tilemapwidth;
	//step through path 
	while ((pos1 - pos2).Length() > 1.0f)
	{
		for (f32 i = 0; i < width; i += 0.5f)
		{
			const f32 x = pos1.x + perp.x * i;
			const f32 y = pos1.y + perp.y * i;
			SetTile(@map, m_width, x, y, type);
		}
		pos1 += (n / 2);
	}
}