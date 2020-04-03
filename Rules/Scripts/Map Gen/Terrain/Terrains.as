
enum terrain
{
	plains = 0,
	plains_flower,
	mountains,
	mountains_rocky,
	hills,	//not implemented
	forest,
	forest_pine
}

class Terrain
{
	private int type;
	private int[] amplitudeRange;
	private int[] periodRange;
	private int[][] sectors;		//the areas of this terrain
	private BlobInfo@[] blobInfo;	//blob life

	Terrain(const int t, const int[] a, const int[] p)
	{
		type = t;
		amplitudeRange = a;
		periodRange = p;
	}

	Terrain(const int t, const int[] a, const int[] p, const BlobInfo@[] b)
	{
		type = t;
		amplitudeRange = a;
		periodRange = p;
		blobInfo = b;
	}

	void addSector(const int[] sector)
	{
		if (sector.length != 2) {
			warn("INVALID SECTOR, RETURNING");
			return;
		}
		sectors.push_back(sector);
	}

	int[] getSector(const int i) const
	{
		if (i >= sectors.length) {
			warn("INVALID INDEX, RETURNING");
			int[] empty;
			return empty;
		}
		return sectors[i];
	}

	int getSectorCount() const
	{
		return sectors.length;
	}

	bool posInSector(const int x) const
	{
		for (int i = 0; i < sectors.length; i++)
		{
			const int x1 = sectors[i][0];
			const int x2 = sectors[i][1];

			if (x >= x1 && x <= x2) {
				return true;
			}
		}
		return false;
	}

	void placeTilesInSectors(int[] values, TerrainTileInfo@[] info, s32 map_width, int depth, bool tileAlways = true)
	{
		for (int j = 0; j < sectors.length; j++)
		{
			int[] sector = sectors[j];
			const int x1 = sector[0];
			const int x2 = sector[1];

			for (int x = x1; x < x2; x++)
			{
				//place tiles to a certain depth
				const int y = values[x];
				const int deep = y + depth;
				SetTilesUnderPoint(getMap(), map_width, deep, x, y, info, tileAlways);
			}
		}
	}

	int getAmplitude() const
	{
		return range(amplitudeRange[0], amplitudeRange[1]);
	}

	int getAmplitudeValue(const int i) const
	{
		return amplitudeRange[i];
	}

	int getPeriodFactor() const
	{
		return range(periodRange[0], periodRange[1]);
	}

	int getPeriodFactorValue(const int i) const
	{
		return periodRange[i];
	}

	int getBlobInfoCount() const
	{
		return blobInfo.length;
	}

	BlobInfo@ getBlobInfo(const int i) const
	{
		return blobInfo[i];
	}

	BlobInfo@ getBlobInfoByName(const string name) const
	{
		for (int i = 0; i < blobInfo.length; i++)
		{
			BlobInfo@ b = blobInfo[i];

			if (b.name == name) {
				return @b;
			}
		}
		return null;
	}

	void addBlobInfo(BlobInfo@ b)
	{
		blobInfo.push_back(@b);
	}

	void addBlobInfo(BlobInfo@[] b)
	{
		for (int i = 0; i < b.length; i++)
		{
			blobInfo.push_back(b[i]);
		}
	}

	void CreateBlob(const int i) const
	{
		blobInfo[i].Create();
	}

	void CreateBlobChanced(const int i) const
	{
		blobInfo[i].CreateChanced();
	}

	void CreateBlob(const int i, Vec2f p) const
	{
		blobInfo[i].Create(p);
	}

	void CreateBlobChanced(const int i, Vec2f p) const
	{
		blobInfo[i].CreateChanced(p);
	}

	void setType(const int t) {
		type = t;
	}

	int getType() const {
		return type;
	}
}

class TerrainManager
{
	private Terrain@[] terrains;
	private int[] values;		//cumulative values

	TerrainManager() {}

	TerrainManager(Terrain@[] t)
	{
		terrains = t;
	}

	int getTerrainCount() const
	{
		return terrains.length;
	}

	void addTerrain(Terrain@ t)
	{
		terrains.push_back(@t);
	}

	void setTerrains(Terrain@[] t)
	{
		terrains = t;
	}

	Terrain@ getTerrain(const int i) const
	{
		return @terrains[i];
	}

	Terrain@ getTerrainByType(const int type) const
	{
		for (int i = 0; i < terrains.length; i++)
		{
			Terrain@ t = terrains[i];

			if (type == t.getType()) {
				return @t;
			}
		}
		return null;
	}

	Terrain@ getTerrainAtX(const int x)
	{
		for (int i = 0; i < terrains.length; i++)
		{
			Terrain@ t = terrains[i];
			if (t.posInSector(x)) {
				return @t;
			}
		}
		return null;
	}

	void setValues(const int[] v)
	{
		values = v;
	}

	int[] getValues() const
	{
		return values;
	}

	void addBlobInfoToType(const int type, BlobInfo@[] info)
	{
		Terrain@ t = getTerrainByType(type);

		if (t !is null) {
			t.addBlobInfo(info);
		}
	}

	void addBlobInfoToType(const int type, BlobInfo@ info)
	{
		Terrain@ t = getTerrainByType(type);

		if (t !is null) {
			t.addBlobInfo(info);
		}
	}

	void CreateRandomBlobChancedToType(const int type, Vec2f pos)
	{
		Terrain@ t = getTerrainByType(type);
		const int index = ranged(t.getBlobInfoCount());
		t.CreateBlobChanced(index, pos);
	}

	void CreateRandomBlobChancedAtX(const int x, Vec2f pos)
	{
		Terrain@ t = getTerrainAtX(x);
		const int count = t.getBlobInfoCount();

		if (count > 0)
		{
			const int index = ranged(t.getBlobInfoCount());
			t.CreateBlobChanced(index, pos);
		}
	}
}

class TerrainTileInfo
{
	int type;
	f32 chance;

	TerrainTileInfo(const int t, const f32 c)
	{
		type = t;
		chance = c;
	}
}