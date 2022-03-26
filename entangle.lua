-- title: Elden Martins
-- author: Scrum Monkeys
-- desc:   The adventures and puzzles of a young Joe Martins
-- script: lua


--------------- CONSTANTS ----------------
btiles = {
		empty = 0,
  map_player = 34,
  goal = 33, 
  wall = 32,
  rock_min = 1,
  rock_max = 15
}

ftiles = {
	player = 256,
	pick = 258
}

screenw = 240
screenh = 136

----------------- MAIN --------------------

t=0
cur_lvl = 1

-- pick is a stack
lvls = {
	{ent = 1, pick = {5, 5, 5}}
}

p = {
	ent = 0,
	pick = {},
 x = 0,
 y = 0,
	dirx = 0,
 diry = 0,
 look = 0, -- up < down < left < right
 entang = false,
 curr_entang = nil
}

entangs = {}

function TIC()
				
				if (t == 0) then
					load_level(cur_lvl)
				end
				
				input();
				update();
				render();
    
    t=t+1
end

function input()
	p.diry = 0
 p.dirx = 0
 p.entang = false
 p.break_block = false
	
	if btnp(4) then p.entang = true end
	if btnp(5) then p.break_block = true end

	if btnp(0) then
		p.diry = -1
		p.look = 0 
		return --up
	end
	if btnp(1) then
		p.diry = 1 
		p.look = 1
		return --down
	end
	if btnp(2) then
		p.dirx = -1
		p.look = 2
		return --left
	end
	if btnp(3) then
		p.dirx = 1
		p.look = 3
		return --right
	end
	
end

------------------ UPDATE --------------

function update()

	newx = p.x + p.dirx
	newy = p.y + p.diry
	
	if newx ~= p.x or newy ~= p.y then
		
		tile = mget(newx, newy)
		
		if (
			handleGoalTile(tile, newx, newy)
			or handleEmptyTile(tile, newx, newy)
		) then end
		
	else 
			local lookTile = getLookTile()
			
			tile = mget(lookTile[1], lookTile[2])
			
		if (handleEntang(tile, lookTile[1], lookTile[2])
			or handleRockTile(tile, lookTile[1], lookTile[2])
		)
			 then end 
	end

end

function handleRockTile(tile, newx, newy)
	if not p.break_block then return false end
	
	if tile >= btiles.rock_min and tile <= btiles.rock_max then

			if #p.pick > 0 then
				local cur_pick = p.pick[#p.pick]
				
				if cur_pick >= tile then
					p.pick[#p.pick] = nil
					mset(newx, newy, btiles.empty)
					
					if p.curr_entang ~= nil and isTablesEqual(p.curr_entang, {newx, newy}) then
						p.curr_entang = nil
					end
					
					local broke = false
					
					for i = 1, #entangs do
						for j = 1, #(entangs[i]) do
							if isTablesEqual(entangs[i][j], {newx, newy}) then
								-- remove all tiles in the entanglement that contains this tile
								for k = 1, #entangs[i] do
									mset(entangs[i][k][1], entangs[i][k][2], btiles.empty)			
								end
								
								table.remove(entangs, i)
								
								broke = true
								break	
							end
						end
						if broke then break end
					end
					
				end
			end
			
			return true
		end
		
		return false
end

function handleGoalTile()
	if tile == btiles.goal then
		p.x = newx
		p.y = newy
		
		mset(newx, newy, btiles.empty)
		
		-- do win
		
		return true
	end
			
	return false
end

function handleEmptyTile()

	if tile == btiles.empty then
		p.x = newx
		p.y = newy
		
		return true
	end
			
	return false
end


function handleEntang(tile, x, y)
  if not (p.entang == true and p.ent > 0) then return false end
		if tile >= btiles.rock_min and tile <= btiles.rock_max then
			if p.curr_entang == nil then
				p.curr_entang = {x,y}
			else 
				if	not isTablesEqual(p.curr_entang, {x,y}) then
					if not isInEntang({x,y}) then
						entangs[#entangs + 1] = {p.curr_entang,{x,y}}
						p.curr_entang = nil
						p.ent = p.ent - 1
					end
				end
			end
		end
end

function isInEntang(tileCoords)
	for i = 1, #entangs do
		for j = 1, #entangs[i] do
			if isTablesEqual(entangs[i][j], tileCoords) then
				return true
			end
		end
	end
	return false
end

function getLookTile()
	if p.look == 0 then return {p.x, p.y - 1} end
	if p.look == 1 then return {p.x, p.y + 1} end
	if p.look == 2 then return {p.x - 1, p.y} end
	if p.look == 3 then return {p.x + 1, p.y} end
end

--------------- RENDERING ---------------------
 
function render()

 map(0, 0, 30, 17)
 spr(ftiles.player, p.x * 8, p.y * 8, 0)

	drawEntangs()
	hud()

end

function drawEntangs()
	if p.curr_entang ~= nil then
		rectb(p.curr_entang[1] * 8, p.curr_entang[2] * 8, 8, 8, 1)
	end
	
	for i = 1, #entangs do
		rectb(entangs[i][1][1] * 8, entangs[i][1][2] * 8, 8, 8, (i + 1)%15)
		rectb(entangs[i][2][1] * 8, entangs[i][2][2] * 8, 8, 8, (i + 1)%15)
	end
end
 
function hud()

	rect(0, 0, screenw, 8, 6)
	print("Level " .. tostring(cur_lvl), 2, 2)

	spr(ftiles.pick, 80, 0, 0)
	local	pick_values = "[ "
	for k, v in pairs(p.pick) do
		pick_values = pick_values .. tostring(v) .. " "
		if k == 1 then
			pick_values = pick_values .. "] "
		end
	end
	print(pick_values, 90, 2)
	
	-- TODO: replace text with icon
	reversePrint("Entanglements: " .. p.ent, 0, 2)
	
end


----------- LEVELS ----------------

function load_level(lvl)
	-- Load lvl properties
	local lvl_data = lvls[lvl]
	p.ent = lvl_data.ent
	p.pick = table.copy(lvl_data.pick)


	-- Copy map
	local mapx = 30 * (lvl % 8)
	local mapy = 17 * (lvl // 8)
	
	for i = mapx, mapx + 30 do
		for j = mapy, mapy + 17 do
			tile = mget(i, j)
			worldx = i % 30
			worldy = j % 17
			mset(worldx, worldy, tile)
			
			if tile == btiles.map_player then
				p.x = worldx
				p.y = worldy
				
				mset(worldx, worldy, btiles.empty)
			end
		end
	end

end










---------------- UTILS ---------------
function table.copy(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end


-- !!!Does not work with nested lists!!!
function isTablesEqual(list1, list2)
	if #list1 ~= #list2 then return false end
	
	for i = 1, #list1 do
		if list1[i] ~= list2[i] then
			return false
		end	
	end
	
	return true
end

function reversePrint(text, x, y, color, fixed, scale, smallfont) 
 color = color or 15
 fixed = fixed or false
 scale = scale or 1
 smallfont = smallfont or false
 local width = print(text, 0, -30, color, fixed, scale, smallfont)
 print(text, (240 - width - x), y, color, fixed, scale, smallfont)
end
-- <TILES>
-- 001:eeeeeeeeeffffffeefffdffeeffddffeefffdffeefffdffeefffdffeeeeeeeee
-- 002:eeeeeeeeeffffffeefdddffeeffffdfeeffddffeefdffffeefddddfeeeeeeeee
-- 003:eeeeeeeeeffffffeefddddfeeffffdfeefddddfeeffffdfeefddddfeeeeeeeee
-- 004:eeeeeeeeeffffffeefffdffeeffddffeefdfdffeefddddfeefffdffeeeeeeeee
-- 005:eeeeeeeeeffffffeefddddfeefdffffeefddddfeeffffdfeefddddfeeeeeeeee
-- 006:eeeeeeeeeffffffeefddddfeefdffffeefddddfeefdffdfeefddddfeeeeeeeee
-- 007:eeeeeeeeeffffffeefddddfeeffffdfeefffdffeeffdfffeeffdfffeeeeeeeee
-- 008:eeeeeeeeeffffffeefddddfeefdffdfeefddddfeefdffdfeefddddfeeeeeeeee
-- 009:eeeeeeeeeffffffeefddddfeefdffdfeefddddfeeffffdfeefddddfeeeeeeeee
-- 010:eeeeeeeeeffffffeefddddfeefdffdfeefddddfeefdffdfeefdffdfeeeeeeeee
-- 011:eeeeeeeeeffffffeefdddffeefdffdfeefdddffeefdffdfeefdddffeeeeeeeee
-- 012:eeeeeeeeeffffffeefddddfeefdffffeefdffffeefdffffeefddddfeeeeeeeee
-- 013:eeeeeeeeeffffffeefdddffeefdffdfeefdffdfeefdffdfeefdddffeeeeeeeee
-- 014:eeeeeeeeeffffffeefddddfeefdffffeefdddffeefdffffeefddddfeeeeeeeee
-- 015:eeeeeeeeeffffffeefddddfeefdffffeefdddffeefdffffeefdffffeeeeeeeee
-- 032:1111111111000011101001011001100110011001101001011100001111111111
-- 033:00000000ccccccccc000000cccccccccc000000cccccccccc000000ccccccccc
-- 034:0002200000222200002bb2000022220000222200002222000020020000200200
-- </TILES>

-- <SPRITES>
-- 000:0002200000222200002bb2000022220000222200002222000020020000220220
-- 001:0002200000222200002bb2000022220000222200002222000020020002202200
-- 002:0000000000088800000008800000308000030080003000000000000000000000
-- </SPRITES>

-- <MAP>
-- 005:000000000000000000000000000000000000000000000000000000000000000000000000000000000000020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:000000000000000000000000000000000000000000000000000000000000000000000000000000000002021202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:000000000000000000000000000000000000000000000000000000000000000000000000000000000002405070020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:000000000000000000000000000000000000000000000000000000000000000000000000000000000002206080020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:000000000000000000000000000000000000000000000000000000000000000000000000000000000002002200020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:000000000000000000000000000000000000000000000000000000000000000000000000000000000002020202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

