#include "StructureTypes.as"
#include "BlobInfo.as"
#include "Section.as"
#include "KingdomsPNGLoader.as"
#include "vectorFunctions.as"

void buildTower(int[] values, const int type)
{
	Vec2f tilepos(50.0f, values[100] - 1);
	/*Section@ build = getBuild(type, Vec2f(4.0f, 4.0f), tilepos);

	if (build !is null) {
		build.Create();
	}*/
	//CreateFromPNG("towerRoofed.png", 0, Vec2f(14.0f, 18.0f), tilepos * 8.0f);

	KingdomsPNGLoader loader();
	loader.CreateFromPNG("towerRoofed.png", 0, Vec2f(14.0f, 18.0f), tilepos);

	/*structure placement ideas
		
		place structures only between a specific height / depth
		place structures only in specific biomes (biomes need implementation)
		fill in gaps under structures to look more natural
		place sky structures for certain builds
	*/
}

namespace CastleRoom
{
	enum roomtypes
	{
		plain = 0,
		solid,
		throne,
		hall,
		grand_hall,
		roof,
		library,
		kitchen,
		bedroom,
		treasury,
		beer,
		painting,
		garden, 
		archer_station,
		secret
	};

	enum entrancetypes
	{
		entrance_none = 0,
		entrance_left,
		entrance_right
	};
}

class CastleRoom
{
	private int type;
	private int width;
	private int height;
	private Vec2f pos;
	private bool connected = false;
	private CastleRoom@[] connections;

	CastleRoom() {}

	CastleRoom(const int w, const int h, const int t, const Vec2f p) 
	{
		type = t;
		width = w;
		height = h;
		pos = p;
	}

	void Create() 
	{
		if (type == CastleRoom::plain) {
			BuildRect(width, height, pos, CMap::tile_castle, CMap::tile_castle_back);
		}
	}

	Vec2f getCenter()
	{
		return pos + Vec2f(width / 2.0f, -height / 2.0f);
	}

	void AddConnection(CastleRoom@ r) {

		if (!isConnectedTo(@r)) {
			connections.push_back(@r);
		}
	}

	int getConnectionCount() {
		return connections.length;
	}

	CastleRoom@ getConnection(const int i) {
		return connections[i];
	}

	bool isConnectedTo(CastleRoom@ r) 
	{
		for (int i = 0; i < connections.length; i++) 
		{
			if (@connections[i] is @r) {
				return true;
			}
		}

		return false;
	}

	bool isConnectable(CastleRoom@ room, bool use_connected = true)
	{
		//this is dumb, change it
		if (use_connected && connected) {
			return false;
		}

		if (isConnectedTo(@room) || room.isConnectedTo(@this)) {
			return false;
		}

		//check distance
		const f32 max_dist = 200.0f;
		const f32 dist = getDistanceTo(@room);
		//("dist: " + dist);
		if (dist > max_dist) return false;

		//calculate center positions and check if there's sky blocks between
		CMap@ map = getMap();
		Vec2f center = getCenter();
		Vec2f r_center = room.getCenter();
		const int m_width = map.tilemapwidth;

		Vec2f n = (center - r_center);
		n.Normalize();
		Vec2f step = center;

		while ((step - r_center).Length() > 1.0f)
		{
			//check if we encountered a different room or outside tile
			step -= n;
			Tile tile = map.getTileFromTileSpace(step);

			if (tile.type == CMap::tile_empty || 
				(!posInMe(step) && !room.posInMe(step) && tile.type == CMap::tile_castle_back)) 
			{
				return false;
			}
		}
		return true;
	}

	//todo: consider returning distance to closest tiles instead
	f32 getDistanceTo(CastleRoom@ room)
	{	
		return (getCenter() - room.getCenter()).Length();
	}

	CastleRoom@ getClosestConnectableRoom(const CastleRoom@[]@ rooms)
	{
		CastleRoom@ closest;
		//compare with all other rooms and connect if it's the closest room
		for (int j = 0; j < rooms.length; j++)
		{
			CastleRoom@ r = rooms[j];
			const f32 dist = getDistanceTo(@r);

			if (this !is r &&
				((closest is null && isConnectable(@r, false)) ||
			     (closest !is null && dist < getDistanceTo(@closest) && isConnectable(@r, false))))
			{
				@closest = @r;
			}
		}

		return closest;
	}

	bool isConnected()
	{
		return connected; 
	}

	bool posInMe(Vec2f p)
	{
		//convert to int and compare
		int x = p.x;
		int y = p.y;

		return x <= (pos.x + width) && x >= pos.x && y <= pos.y && y >= (pos.y - height);
	}

	void Connect(CastleRoom@ room)
	{
		connected = true;
		AddConnection(@room);
		room.AddConnection(@this);
		Vec2f[] closestTiles = getClosestTilePositions(@room);
		BuildPath(closestTiles[0], closestTiles[1], 3, CMap::tile_castle_back);
	}

	void ConnectCenters(CastleRoom@ room, const int tile_back = CMap::tile_castle_back)
	{
		if (isConnectedTo(@room)) {
			return;
		}

		connected = true;
		AddConnection(@room);
		room.AddConnection(@this);
		
		BuildPath(getCenter(), room.getCenter(), 3, tile_back);
	}

	bool isColliding(CastleRoom@ room)
	{
		Vec2f p = room.getPosition();

		return (pos.x + width) >= p.x 
				&& pos.x <= (p.x + room.getWidth())
				&& pos.y >= (p.y - room.getHeight())
				&& (pos.y - height) <= p.y; 
	}

	Vec2f[] getClosestTilePositions(CastleRoom@ room)
	{

		//get the closest side and calculate the closest position

		Vec2f center = getCenter();
		Vec2f c = room.getCenter();
		Vec2f p = room.getPosition();

		//get comparable corner
		Vec2f corner;

		if (center.x < c.x) {
			corner.x =  p.x;
		}
		else {
			corner.x = p.x + room.getWidth();
		}

		if (pos.y < p.y) {
			corner.y = p.y - room.getHeight();
		}
		else {
			corner.y = p.y;
		}
 		
 		//get side
 		string side;
		
		if (corner.x < c.x) 
		{
			//left top
			if (corner.y < c.x) {
				Vec2f tileProp1 = Vec2f(corner.x, corner.y + 1);
				Vec2f tileProp2 = Vec2f(corner.x + 1, corner.y);

				if (getDistance(tileProp1, center) < getDistance(tileProp2, center)) {
					side = "left";
				}
				else {
					side = "top";
				}
			}
			//left bottom
			else {
				Vec2f tileProp1 = Vec2f(corner.x, corner.y - 1);
				Vec2f tileProp2 = Vec2f(corner.x + 1, corner.y);

				if (getDistance(tileProp1, center) < getDistance(tileProp2, center)) {
					side = "left";
				}
				else {
					side = "bottom";
				}
			}
		}
		else
		{
			//right top
			if (corner.y < c.x) {
				Vec2f tileProp1 = Vec2f(corner.x, corner.y + 1);
				Vec2f tileProp2 = Vec2f(corner.x - 1, corner.y);

				if (getDistance(tileProp1, center) < getDistance(tileProp2, center)) {
					side = "right";
				}
				else {
					side = "top";
				}
			}
			//right bottom
			else {
				Vec2f tileProp1 = Vec2f(corner.x, corner.y - 1);
				Vec2f tileProp2 = Vec2f(corner.x - 1, corner.y);

				if (getDistance(tileProp1, center) < getDistance(tileProp2, center)) {
					side = "right";
				}
				else {
					side = "bottom";
				}
			}
		}

		//get closest tile from sides
		Vec2f[] closestTiles;

		if (side == "top") {
			closestTiles = getClosestSideTiles(@room, "top", pos.y, p.y - room.getHeight()); //v = y value, rv = room y value
		}
		else if (side == "bottom") {
			closestTiles = getClosestSideTiles(@room, "bottom", pos.y - height, p.y);
		}
		else if (side == "left") {
			closestTiles = getClosestSideTiles(@room, "left", pos.x + width, p.x); //v = x value, rv = room x value
		}
		else if (side == "right") {
			closestTiles = getClosestSideTiles(@room, "right", pos.x, p.x + room.getWidth());
		}

		return closestTiles;
	}

	Vec2f[] getClosestSideTiles(CastleRoom@ room, const string side, const int v, const int rv)
	{
		Vec2f p = room.getPosition();
		Vec2f[] closestPositions;
		closestPositions.set_length(2);
		f32 closest_dist = 1000.0f;

		Vec2f[] closestQueue;

		if (side == "top" || side == "bottom")
		{
			for (int x = pos.x; x < (pos.x + width); x++)
			{
				//const int y = pos.y;
				const int y = v;
				Vec2f tile_pos1(x, y);

				for (int rx = p.x; rx < (p.x + room.getWidth()); rx++)
				{
					//const int ry = p.y - room.getHeight();
					const int ry = rv;
					Vec2f tile_pos2(rx, ry);
					const f32 dist = getDistance(tile_pos1, tile_pos2);

					if (dist < closest_dist) {
						closest_dist = dist;
						closestPositions[0] = tile_pos1;
						closestPositions[1] = tile_pos2;
					}
				}
			}
		}
		else 
		{
			for (int y = pos.y; y > (pos.y - height); y--)
			{
				//const int y = pos.y;
				const int x = v;
				Vec2f tile_pos1(x, y);

				for (int ry = p.y; ry > (p.y - room.getHeight()); ry--)
				{
					//const int ry = p.y - room.getHeight();
					const int rx = rv;
					Vec2f tile_pos2(rx, ry);
					const f32 dist = getDistance(tile_pos1, tile_pos2);

					if (dist < closest_dist) {
						closest_dist = dist;
						closestPositions[0] = tile_pos1;
						closestPositions[1] = tile_pos2;
					}
				}
			}
		}
		return closestPositions;
	}

	int getType() const {return type;}
	int getWidth() const {return width;}
	int getHeight() const {return height;}
	Vec2f getPosition() const {return pos;}
}

bool canPlaceRoomInRect(CastleRoom@ room, CastleRoom@[] rooms, Vec2f pos1, const int width, const int height)
{
	Vec2f p1 = room.getPosition();
	Vec2f p2 = p1 + Vec2f(room.getWidth(), -room.getHeight());
	Vec2f pos2 = pos1 + Vec2f(width, -height);

	if (p1.x <= pos1.x || p2.x >= pos2.x || p1.y >= pos1.y || p2.y <= pos2.y) {
		return false;
	}

	for (int i = 0; i < rooms.length; i++)
	{
		CastleRoom@ r = rooms[i];
		if (room.isColliding(@r)) return false;
	}
	return true;
}


void BuildStructures(TerrainManager@ tm)
{
	//get common structures
	/*const string[] goldy = 
	{

	};*/

	//build kingdoms in the right terrains and record positions
	//build bandit camps / enemy structures and record positions
	//build other stuctures


	//get plains & forest terrains by type, place kingdoms
	//get mountain & forest terrains by type, place enemy structures
	//loop through values and place other structures



	//castle gen code
	CMap@ map = getMap();
	Vec2f pos(50.0f, 80.0f);
	int width = range(80, 100);
	int height = 2;
	const int castle = CMap::tile_castle;
	const int castle_back = CMap::tile_castle_back;
	//build base of castle
	BuildRect(width, height, pos, castle, castle);

	//build rooms based off types - make sure there is one room for throne
	
	bool throneroom = false;
	const int level_count = range(3, 5);

	//height and width of rectangles determined by these variables
	const int room_max_width = 20;
	const int room_min_width = 10;
	const int room_max_height = 20;
	const int room_min_height = 10;
	const int rooms_max_horizontal = 6;
	const int rooms_max_vertical = 6;
	const int rooms_min_horizontal = 3;
	const int rooms_min_vertical = 3;

	//max room width + the spacing between each room * the factor + end column
	const int max_width = (room_max_width + 1) * rooms_max_horizontal + 1; 
	const int max_height = (room_max_height + 1) * rooms_max_vertical + 1;
	const int min_width = (10 + 1) * rooms_min_horizontal + 1;
	const int min_height = (10 + 1) * rooms_min_vertical + 1;
	CastleRoom@[] rooms;

	//build first rect, and build to the sides of it
	int r_width = range(min_width, max_width);
	int r_height = range(min_height, max_height);
	int x = pos.x + ranged(width) - (r_width / 2);	//subtracting r_width since built from corner
	int y = pos.y - height;
	Vec2f r_pos(x, y);
	int entrance = CastleRoom::entrance_none;


	BuildRect(r_width, r_height, r_pos, castle, castle);
	BuildRoomsInRect(@rooms, r_pos, r_width, r_height, room_max_width, room_max_height, room_min_width, room_min_height);

	if ((r_pos.x + r_width) >= (pos.x + width)) {
		BuildEntrance(@rooms, r_pos, r_width, r_height, CastleRoom::entrance_right);
	}

	if (r_pos.x <= pos.x) {
		BuildEntrance(@rooms, r_pos, r_width, r_height, CastleRoom::entrance_left);
	}

	//build rooms to left and right sides
	int left = x;
	int right = x + r_width;
	

	while (left > pos.x)
	{
		r_width = range(min_width, max_width);
		r_height = range(min_height, max_height);
		x = left - r_width;
		Vec2f r_pos(x, y);

		BuildRect(r_width, r_height, r_pos, castle, castle);

		left = x;
		if (left <= pos.x) {
			entrance = CastleRoom::entrance_left;
		}

		BuildRoomsInRect(@rooms, r_pos, r_width, r_height, room_max_width, room_max_height, room_min_width, room_min_height, entrance);
		
		//build rooms in a tower formation
		/*int pos_y = y;
		for (int i = 0; i < (level_count - 1); i++)
		{
			//try it without this break condition
			if (r_width <= min_width) break;

			pos_y -= r_height;
			const int prev_width = r_width;
			r_width = range(min_width, r_width);
			r_height = range(min_height, max_height); //try this where max_height is r_height

			x = range(x, x + prev_width - r_width);
			r_pos = Vec2f(x, pos_y);
			BuildRect(r_width, r_height, r_pos, castle);
		}*/

	}

	entrance = CastleRoom::entrance_none;

	while (right < (pos.x + width))
	{
		r_width = range(min_width, max_width);
		r_height = range(min_height, max_height);
		x = right;
		Vec2f r_pos(x, y);

		BuildRect(r_width, r_height, r_pos, castle, castle);
		
		right = x + r_width;
		if (right >= (pos.x + width)) {
			entrance = CastleRoom::entrance_right;
		}
		
		BuildRoomsInRect(@rooms, r_pos, r_width, r_height, room_max_width, room_max_height, room_min_width, room_min_height, entrance);
	}

	ConnectClosestRooms(@rooms);
}

//todo: add cfg vars
void BuildRoomsInRect(CastleRoom@[]@ rooms, Vec2f pos, int width, int height, int max_width, int max_height, int min_width, int min_height, int entrance = 0)
{
	//todo: make it easier to change max width and height vars. 
	//      consider using "steps" between x positions rather than random placement

	const int columns = width / (max_width + 1); //max horizontal rooms
	const int rows = height / (max_height + 1);

	for (int i = 0; i < rows; i++)
	{
		//calculate room width and height, place it somewhere on first row
		int y = pos.y + i * -max_height - 1;

		for (int j = 0; j < columns; j++)
		{
			const int r_width = range(min_width, max_width);
			const int r_height = range(min_height, max_height);
			int x = pos.x + 1 + ranged(width - r_width - 1);
			Vec2f p(x, y);
			CastleRoom room(r_width, r_height, CastleRoom::plain, p);

			if (canPlaceRoomInRect(@room, rooms, pos, width, height))
			{
				room.Create();
				rooms.push_back(@room);
			}
		}
	}

	BuildEntrance(@rooms, pos, width, height, entrance);
}

void BuildEntrance(CastleRoom@[]@ rooms, Vec2f pos, int width, int height, int entrance = 0)
{
	//connect the closest room to the entrance
	if (entrance == CastleRoom::entrance_none) return;

	Vec2f entrancePos;

	if (entrance  == CastleRoom::entrance_left) {
		entrancePos = Vec2f(pos.x - 1, pos.y - 2);
	}
	else if (entrance == CastleRoom::entrance_right) {
		entrancePos = Vec2f(pos.x + width, pos.y - 2);
	}

	CastleRoom@ room;

	for (int i = 0; i < rooms.length; i++) 
	{
		CastleRoom@ r = rooms[i];
		const f32 r_dist = getDistance(r.getCenter(), entrancePos);

		if (room is null || r_dist < getDistance(room.getCenter(), entrancePos))
		{
			@room = r;
		}
	}

	Vec2f connectPoint;
	Vec2f p = room.getPosition();

	if (entrance  == CastleRoom::entrance_left) {
		connectPoint = Vec2f(p.x + 5, p.y);
	}
	else if (entrance == CastleRoom::entrance_right) {
		connectPoint = Vec2f(p.x + room.getWidth() - 5, p.y);
	}

	BuildPath(connectPoint, entrancePos, 3, CMap::tile_castle_back);
}

void ConnectClosestRooms(const CastleRoom@[]@ rooms)
{
	if (rooms.empty()) {
		return;
	}

	for (int i = 0; i < rooms.length; i++)
	{
		CastleRoom@ room = rooms[i];
		CastleRoom@ closest = room.getClosestConnectableRoom(@rooms);

		if (closest !is null) {
			room.ConnectCenters(@closest);
		}
	}

	CastleRoom@[] roomsTracker; //list of the rooms found & resolved so far
	//find the rooms that aren't in the connection and solve their connection

	for (int i = 0; i < rooms.length; i++)
	{
		//if in rooms continue, else find the connected rooms.
		CastleRoom@ r1 = rooms[i];
		bool inConnection = false;

		for (int j = 0; j < roomsTracker.length; j++) 
		{
			CastleRoom@ r2 = @roomsTracker[j];

			if (r1 is r2) {
				inConnection = true;
			}
		}

		if (!inConnection) 
		{
			CastleRoom@[] roomsConnected;
			FindConnectedRooms(@r1, roomsConnected);

			//connect closest rooms between connections
			f32 dist = 100000.0f;
			CastleRoom@ closest;
			CastleRoom@ room;

			for (int j = 0; j < roomsConnected.length; j++)
			{
				CastleRoom@ r = roomsConnected[j];
				CastleRoom@ r_closest = r.getClosestConnectableRoom(@roomsTracker);

				if (r_closest !is null && r.getDistanceTo(@r_closest) < dist) 
				{
					@room = @r;
					@closest = @r_closest;
					dist = r.getDistanceTo(@r_closest);
				}
			}

			if (closest !is null) {
				room.ConnectCenters(@closest);
			}

			//pushback new section to roomsTracker
			for (int j = 0; j < roomsConnected.length; j++) {
				roomsTracker.push_back(@roomsConnected[j]);
			}
		}
	}

}

//recursive function
void FindConnectedRooms(CastleRoom@ startRoom, CastleRoom@[]@ connectedRooms)
{
	//add to the list of connected rooms
	connectedRooms.push_back(@startRoom);

	//check if neighbors are in list
	for (int i = 0; i < startRoom.getConnectionCount(); i++)
	{
		CastleRoom@ r1 = startRoom.getConnection(i);
		bool inList = false;

		for (int j = 0; j < connectedRooms.length; j++)
		{
			CastleRoom@ r2 = connectedRooms[j];

			if (r2 is r1) {
				inList = true;
			}
		}

		if (!inList) {
			FindConnectedRooms(@r1, @connectedRooms);
		}
	}
}
