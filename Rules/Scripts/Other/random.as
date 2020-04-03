
/*f32 random() {
	return XORRandom(101) * 0.01f;
}

u32 range(const u32 x, const u32 y) {
	return x + XORRandom((y - x) + 1);
}

/*f32 random() {
	Random@ r = Random();
}*/

//manages a Random object to make it easier to keep the seed consistent

namespace RandomManager
{
	Random@ r = Random();

	void setSeed(uint seed) {
		r.Reset(seed);
	}

	uint getSeed() {
		return r.getSeed();
	}

	//inclusive positive range
	u32 range(const u32 a, const u32 b) {
		return a + r.NextRanged((b - a) + 1);
	}

	u32 ranged(const u32 n) {
		return r.NextRanged(n);
	}
	
	f32 random() {
		return r.NextRanged(101) * 0.01f;
	}
}

//accessor functions
void setSeed(uint seed) {
	RandomManager::setSeed(seed);
}

uint getSeed() {
	return RandomManager::getSeed();
}

u32 range(const u32 a, const u32 b) {
	return RandomManager::range(a, b);
}

u32 ranged(const u32 n) {
	return RandomManager::ranged(n);
}

f32 random() {
	return RandomManager::random();
}