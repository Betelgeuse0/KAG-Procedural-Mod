
class Section
{
	private int[][] tiles; 			 	 //the tile types
	private BlobInfo@[] blobsInfo;  	 //the blobs information
	private BlobInfo@[][] blobsGridInfo; //alternate blob creation
	private Vec2f tilepos; 					 //bottom left corner

	Section(int[][] t, BlobInfo@[] b_info, Vec2f p)
	{
		tiles = t;
		blobsInfo = b_info;
		tilepos = p;
	}

	void Create()
	{
		CMap@ map = getMap();
		const int width = tiles.length;

		//columns, rows
		for (int c = 0; c < tiles.length; c++)
		{
			//const int y = 8 * (tiles.length - 1 - c);
			const int y = tilepos.y - (tiles.length - 1 - c);
			
			for (int r = 0; r < tiles[c].length; r++)
			{
				const int x = tilepos.x + r;
				SetTile(@map, map.tilemapwidth, x, y, tiles[c][r]);
			}
		}

		for (int i = 0; i < blobsInfo.length; i++)
		{
			BlobInfo@ info = blobsInfo[i];
			if (info !is null) {
				info.Create();
			}
		}
	}
}

class SectionManager
{

	private Section@[] sections;

	SectionManager() {}
	
	SectionManager(Section@[] s)
	{
		sections = s;
	}

	void Create()
	{
		for (int i = 0; i < sections.length; i++)
		{
			sections[i].Create();
		}
	}

	void AddSection(Section@ s)
	{
		sections.push_back(@s);
	}

	void AddSections(Section@[] s)
	{
		for (int i = 0; i < s.length; i++)
		{
			sections.push_back(@s[i]);
		}
	}
}

