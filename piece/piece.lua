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

-- White Pawn taking pattern: 9 or 7 and opposing colour piece present there
-- Black Pawn taking pattern: -9 or -7 and as above
function Piece:isValid(move, array)
	local valid = false
	local flag = nil

	local diff = utils.get_equivalent(self.pos[1], self.pos[2]) - utils.get_equivalent(move[1], move[2])
	local landing_square_or_piece = array[move[1]][move[2]]
	
	-- Pawn
	if self.piece == "p" then
		
		moves = { 
			capture_left=9, 
			capture_right=7,
			forward_one=8 
		}

		if self.colour == "b" then
			for k, v in pairs(moves) do
				moves[k] = -v
			end
		end
	
		-- Compare current pos with new desired pos for capture patterns
		-- If piece present in capture pattern square, then remove that piece -- IN MAIN?

		-- Capture check
		-- If there's a piece present of the opposite colour, then it's valid
		if landing_square_or_piece ~= nil then
			if diff == moves.capture_right or diff == moves.capture_left and landing_square_or_piece.colour ~= self.colour then
				valid = true
				flag = "capture"
			end
		end

		-- Regular move check
		if diff == moves.forward_one and landing_square_or_piece == nil then
			valid = true
		-- Movement patterns +16 White, -16 Black if it's the first move, otherwise +/- 8
		-- First move can be 2 squares forward or 1 square
		elseif self.hasMoved == false and diff == moves.forward_one * 2 then
			valid = true
		end	
	end

	-- En passant
	-- Diagonal capture behind a pawn directly to the left or right, that just moved 2 squares forward
	
	return valid, flag
end
