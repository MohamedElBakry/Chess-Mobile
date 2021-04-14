require "utils-module.utils"

-- [[ Pawn Class --]]

-- Meta Class
Piece = {id="", name="", pos={}, hasMoved=false}

-- ADD ID of GO
-- Dervied Class
function Piece:new(id, name, pos, hasMoved)
	
	-- o = o or {}
	setmetatable({}, Piece)
	
	-- self.__index = self
	self.id = id
	self.name = name
	self.piece = string.sub(name, 1, 1)
	self.colour = string.sub(name, 2, 2)
	self.pos = pos
	self.hasMoved = hasMoved
	self.prevPos = {}
	
	return self
end

function Piece:move(pos)
	self.pos = pos
	self.hasMoved = true
end

function Piece:get_pos()
	return "(" .. self.pos[1] .. ", " .. self.pos[2] .. ")"
end

function Piece:set_pos(pos)
	self.pos = pos
end

-- TODO this
-- White Pawn taking pattern: 9 or 7 and opposing colour piece present there
-- Black Pawn taking pattern: -9 or -7 and as above
function Piece:isValid(move, array)
	local valid = false
	
	-- Pawn
	-- If White
	
	if self.piece == "p" then
		if self.colour == "w" then
			
			-- Compare current pos with new desired pos for capture patterns
			-- If piece present in capture pattern square, then remove that piece -- IN MAIN?
			local diff = utils.get_equivalent(self.pos[1], self.pos[2]) - utils.get_equivalent(move[1], move[2])
			local landing_square_or_piece = array[move[1]][move[2]]

			-- Capture check
			if landing_square_or_piece ~= nil then
				if diff == 9 or diff == 7 and landing_square_or_piece.colour ~= self.colour then
					valid = true
				end
			end

			-- Regular move check
			-- 1 square forward
			if diff == 8 and landing_square_or_piece == nil then
				valid = true
			-- Movement patterns +16 White, -16 Black if it's the first move, otherwise +/- 8
			-- First move can be 2 squares forward or 1 square
			elseif self.hasMoved == false and diff == 16 then
				valid = true
			end
			
		end
	end
	-- If Black
	
	return valid
end

-- p = Piece:new(nil, "hash bla bla", "pw", {6, 3}, false)
-- pprint(p.pos)
-- pprint(p["pos"])
-- print(p:get_pos())
-- 
-- p:set_pos({6, 5})
-- pprint(p.pos, p["pos"], p:get_pos())


-- print(p:get_pos())
-- 
-- p:set_pos({7, 6})
-- print(p:get_pos())
-- p:move({7, 7})
-- print(p.name, p.hasMoved)

-- Example Usage
-- pawn = Piece:new(nil, "pw", {6, 1})


