//the information needed to build structures

//get an entire build

#include "BasePNGLoader.as"

/*Section@ getBuild(const int type, Vec2f dimensions, Vec2f tilepos)
{
	Vec2f pos = tilepos * 8.0f;
	const int sky = CMap::tile_empty;

	if (type == structure::castle_tower)
	{
		if (Vec2f(4.0f, 4.0f) == dimensions)
		{
			const int tc = CMap::tile_castle;
			const int tcb = CMap::tile_castle_back;

			int[][] tiles = 
			{
				{tc, tc, tc, tc},
				{tc, tcb, sky, tc},
				{tc, tcb, tcb, tc},
				{tc, tc, tc, tc},
			};

			BlobInfo@[] info = 
			{
				BlobInfo("princess", 0, pos + Vec2f(16.0f, 16.0f)),
				BlobInfo("mat_gold", -1, pos + Vec2f(16.0f, 16.0f), 50)
			};

			return @Section(tiles, info, tilepos);
		}
	}
	return null;
}

//todo: get a segment of a build, put segments in sectionManager to create a new build

Section@ getSection(const int type, const Vec2f dimensions, const Vec2f pos, const bool doors, const bool roof)
{
	return null;
}

//ONLY WORKS FOR HORIZONTAL PNG's
int[][] getTileInfoFromPNG(const string filename, const u32 frame, Vec2f dimensions)
{
	//PNGLoader loader();
	CFileImage image(filename);
	Vec2f pos = Vec2f(frame * dimensions.x, 0);
	image.setPixelPosition(pos);

	for (int x = pos.x; x < (pos.x + dimensions.x); x++)
	{
		for (int y = pos.y; y < (pos.y + dimensions.y); y++)
		{
			Vec2f pixelpos(x, y);
			image.setPixelPosition(pixelpos);
			const SColor pixel = image.readPixel();

			/*const int offset = image.getPixelOffset();

			if (pixel.color != map_colors::sky)
			{
				loader.handlePixel(pixel, offset);
			}*/
/*		}
	}

	int[][] temp;
	return temp;
}*/


//NOTE: the createfrompng function only works for horizontal png's 

class KingdomsPNGLoader : PNGLoader
{

	KingdomsPNGLoader()
	{
		super();
		@map = getMap();
	}

	void CreateFromPNG(const string filename, const u32 frame, Vec2f dimensions, Vec2f pos)
	{
		CFileImage image(filename);
		Vec2f framepos = Vec2f(frame * dimensions.x, 0);
		image.setPixelPosition(framepos);

		const int pos_y = pos.y;

		for (int x = framepos.x; x < (framepos.x + dimensions.x); x++)
		{
			for (int y = framepos.y; y < (framepos.y + dimensions.y); y++)
			{
				Vec2f pixelpos(x, y);
				image.setPixelPosition(pixelpos);
				SColor pixel = image.readPixel();
				//const int offset = image.getPixelOffset();

				const int offset = pos.x + pos.y * getMap().tilemapwidth;

				if (pixel.color != map_colors::sky)
				{
					PNGLoader::handlePixel(pixel, offset);
				}
				++pos.y;
			}
			pos.y = pos_y;
			++pos.x;
		}
	}
};