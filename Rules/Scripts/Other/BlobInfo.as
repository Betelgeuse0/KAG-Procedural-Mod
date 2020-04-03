//todo: might want to make a TerrainBlobInfo class that inherits from this one
//		it would include f32 chance, int spacing, etc
class BlobInfo
{
	string name;
	Vec2f pos;
	uint team;
	uint16 quantity;
	f32 chance;			//for terrain placement
	int[] spacing;		//for terrain placement
	
	BlobInfo(string n, uint t, Vec2f p, uint16 q = 1)
	{
		name = n;
		pos = p;
		team = t;
		quantity = q;
	}

	BlobInfo(string n, uint t, uint16 q = 1)
	{
		name = n;
		team = t;
		quantity = q;
	}

	BlobInfo(string n, uint t, Vec2f p, f32 c, uint16 q = 1)
	{
		name = n;
		pos = p;
		team = t;
		chance = c;
		quantity = q;
	}

	BlobInfo(string n, uint t, f32 c, uint16 q = 1)
	{
		name = n;
		team = t;
		chance = c;
		quantity = q;
	}

	BlobInfo(string n, uint t, f32 c, int[] s, uint16 q = 1)
	{
		name = n;
		team = t;
		chance = c;
		quantity = q;
		spacing = s;
	}

	void setQuantity(uint16 q) {
		quantity = q;
	}

	int getSpacing() const
	{
		return range(spacing[0], spacing[1]);
	}

	CBlob@ Create()
	{
		if (isTree(name))
		{
			return SpawnTree(pos.x, pos.y, name);
		}

		CBlob@ blob = server_CreateBlob(name, team, pos);

		if (quantity > 1) {
			blob.server_SetQuantity(quantity);
		}
		return @blob;
	}

	CBlob@ Create(Vec2f p)
	{
		if (isTree(name))
		{
			return SpawnTree(p.x, p.y, name);
		}

		CBlob@ blob = server_CreateBlob(name, team, p);

		if (quantity > 1) {
			blob.server_SetQuantity(quantity);
		}
		return @blob;
	}

	CBlob@ CreateChanced()
	{
		CBlob@ blob;

		if (random() < chance) {
			@blob = Create();
		}
		return @blob;
	}

	CBlob@ CreateChanced(Vec2f p)
	{
		CBlob@ blob;

		if (random() < chance) {
			@blob = Create(p);
		}
		return @blob;
	}
}