
int Sign(int n) 
{
	if (n == 0) {
		return 0;
	}
	else if (n > 0) {
		return 1;
	}
	else {
		return -1;
	}
}

//the dot product is used to create a scalar value that represents / reinforces the two vectors. ex) used to find the work done between a force and distance vector. 
f32 DotProduct(Vec2f a, Vec2f b)
{
	return a.x * b.x + a.y + b.y;
}

//linear interpolation: get the height / y value of a point between two points that connects to a slope
//a is int to left of t, b is int to right of t
//t should be value weight of x - a
f32 lerp(const f32 a, const f32 b, const f32 t)
{
	return a * (1.0f - t) + b * t;
}