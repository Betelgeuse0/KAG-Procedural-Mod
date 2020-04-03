//#include "random.as"
#include "mathFunctions.as"


//NOTE: this is unfinished. It does not use the FADE (ease curve) or HASH algorithm.
class PerlinNoise 
{
	Vec2f[][] unitVectors;

	PerlinNoise() {}
	//map width and map height
	PerlinNoise(const int w, const int h) 
	{
		setUnitVectors(w, h);
	}

	void setUnitVectors(const int w, const int h) 
	{
		unitVectors.set_length(w + 1);

		for (int x = 0; x <= w; x++)
		{
			unitVectors[x].set_length(h + 1);

			for (int y = 0; y <= h; y++)
			{
				//create unit vector on left side of tile
				Vec2f v = RandomUnitVec2f();
				unitVectors[x][y] = v;
			}
		}
	}

	f32 noise(const f32 x, const f32 y) 
	{
		//get the four gradient vectors on corners
		Vec2f a = unitVectors[x][y];
		Vec2f b = unitVectors[x + 1][y];
		Vec2f c = unitVectors[x][y + 1];
		Vec2f d = unitVectors[x + 1][y + 1];

		//grid points
		Vec2f ag(x, y);
		Vec2f bg(x + 1, y);
		Vec2f cg(x, y + 1);
		Vec2f dg(x + 1, y + 1);

		//pixel pos
		//Vec2f pos = Vec2f(0.5f, 0.5f);
		//Vec2f pos = Vec2f(1.0f, 1.0f);

		//calculate difference vectors
		/*Vec2f e = pos - a;
		Vec2f f = pos - b;
		Vec2f g = pos - c;
		Vec2f h = pos - d;*/

		//distance vectors
		Vec2f pos(x, y);
		Vec2f e = pos - ag;
		Vec2f f = pos - bg;
		Vec2f g = pos - cg;
		Vec2f h = pos - dg;

		const f32 a_dot = DotProduct(a, e);
		const f32 b_dot = DotProduct(b, f);
		const f32 c_dot = DotProduct(c, g);
		const f32 d_dot = DotProduct(d, h);

		//average
		/*const f32 ab_avr = (a_dot + b_dot) / 2.0f;
		const f32 cd_avr = (c_dot + d_dot) / 2.0f;
		const f32 weighted_avr = (ab_avr + cd_avr) / 2.0f;*/

		//calculate weights - 0 unless x and y are floats between an integer.
		const f32 wx = x - int(x);
		const f32 wy = y - int(y);

		//calculate interpolations between dot products
		const f32 ix0 = lerp(a_dot, b_dot, wx);
		
		const f32 ix1 = lerp(c_dot, d_dot, wx);
		const f32 value = lerp(ix0, ix1, wy);

		return Maths::Abs(value);
	}
}

//TODO: figure out which vectors we're supposed to calculate in a range
Vec2f RandomUnitVec2f()
{
	//might want to try normal cos and theta (for speed tests)
	const f32 theta = 2 * Maths::Pi * random();
	const f32 x = Maths::Cos(theta);
	const f32 y = Maths::Sin(theta);
	//const f32 x = Maths::FastCos(theta);
	//const f32 y = Maths::FastSin(theta);

	return Vec2f(x, y);
}

namespace NoiseManager
{
	PerlinNoise n();

	void init(const s32 w, const s32 h) {
		n.setUnitVectors(w, h);
	}

	f32 noise(const int x, const int y) {
		return n.noise(x, y);
	}
}


/*f32 PerlinNoise()
{
	//pixel pos
	Vec2f pos = Vec2f(0.5f, 0.5f);

	//calculate 4 random gradient vectors 
	Vec2f a = RandomUnitVec2f();
	Vec2f b = RandomUnitVec2f();
	Vec2f c = RandomUnitVec2f();
	Vec2f d = RandomUnitVec2f();

	//calculate difference vectors
	Vec2f e = pos - a;
	Vec2f f = pos - b;
	Vec2f g = pos - c;
	Vec2f h = pos - d;

	const f32 a_dot = DotProduct(a, e);
	const f32 b_dot = DotProduct(b, f);
	const f32 c_dot = DotProduct(c, g);
	const f32 d_dot = DotProduct(d, h);

	//might want to try normal average
	const f32 ab_avr = (a_dot + b_dot) / 2.0f;
	const f32 cd_avr = (c_dot + d_dot) / 2.0f;
	const f32 weighted_avr = (ab_avr + cd_avr) / 2.0f;

	printFloat("weighted_avr: ", weighted_avr * 100.0f);
	return weighted_avr;

}*/