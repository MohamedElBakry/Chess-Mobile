require "utils-module.utils"

-- This seems inefficient, so consider making more specific sub classes from Piece, e.g. Pawn, Knight, Queen ...
-- Pawn = Piece:new()
-- Pawn:isValid(move, array) ... 'specific validation'
-- Knight = Piece:new()
-- Knight:isValid(move, array) ... 'specific validation'


-- [[ Piece Class --]]

-- Meta Class
Piece = {id="", name="", pos={}, hasMoved=false}

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
	-- self.valid_moves = {}

	return self
end

function Piece:move(pos)
	self.prevPos = self.pos
	self.pos = pos
	self.hasMoved = true
end

-- Get a 'representation' of the position
function Piece:get_repr_pos()
	return "(" .. self.pos[1] .. ", " .. self.pos[2] .. ")"
end

function Piece:set_pos(pos)
	self.pos = pos
end

function Piece:isValid(move, array)
	local valid = false
	local flag = nil

	local diff = utils.get_equivalent(self.pos[1], self.pos[2]) - utils.get_equivalent(move[1], move[2])
	local landing_square_or_piece = array[move[1]][move[2]]

	-- TODO table system instead of 'if' chain so, valid, flag = __isvalid[self.piece](args)
	-- Pawn
	if self.piece == "p" then
		valid, flag = self:__isvalid_pawn(move, array, diff, landing_square_or_piece)
		
	elseif self.piece == "n" then
		valid, flag = self:__isvalid_knight(move, array, diff, landing_square_or_piece)
	end
	-- Knight
	-- Etc.
	
	return valid, flag
end

function Piece:__isvalid_pawn(move, array, diff, landing_square_or_piece)
	local valid = false
	local flag = nil
	
	moves = { 
		capture_left=9, 
		capture_right=7,
		forward_one=8 
	}

	-- Negate the black pawn moves 
	if self.colour == "b" then
		for k, v in pairs(moves) do
			moves[k] = -v
		end
	end
	
	-- Capture check
	-- White Pawn taking pattern: 9 or 7 and opposing colour piece present there
	-- Black Pawn taking pattern: -9 or -7 and as above
	-- Compare current pos with new desired pos for capture patterns
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
	-- En passant
	-- Diagonal capture behind a pawn directly to the left or right, that just moved 2 squares forward
	
	return valid, flag
end

-- Knight Move Valid Checking
-- Knight: -15, -6, 10, 17, 15, 6, -10, -17
-- -17, -15, -10, -6, 6, 10, 15, 17
function Piece:__isvalid_knight(move, array, diff, landing_square_or_piece)
	local valid = false
	local flag = nil
	
	-- The 'polarity' i.e. positive or negative doesn't matter here
	diff = math.abs(diff)

	if diff == 17 or diff == 15 or diff == 10 or diff == 6 then
		valid = true
		if landing_square_or_piece ~= nil then
			if landing_square_or_piece.colour ~= self.colour then
				flag = "capture"
			else
				valid = false
				flag = nil
			end
		end
	end

	return valid, flag
end



















