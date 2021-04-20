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
	
	-- TODO: add scale - different for pawn
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
	
	-- Creating these functions may be costly
	local valid_hash = {
		["p"] = function(m, a, d, l) return self:__isvalid_pawn(m, a, d, l) end,
		["n"] = function(m, a, d, l) return self:__isvalid_knight(m, a, d, l) end,
		["r"] = function(m, a, d, l) return self:__isvalid_rook(m, a, d, l) end,
		["b"] = function(m, a, d, l) return self:__isvalid_bishop(m, a, d, l) end
	}

	-- 
	local diff = utils.get_equivalent(self.pos[1], self.pos[2]) - utils.get_equivalent(move[1], move[2])
	local landing_square_or_piece = array[move[1]][move[2]]

	-- Dynamically get the appropriate move validation function, and returnt the results
	return valid_hash[self.piece](move, array, diff, landing_square_or_piece)
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
-- Knight: -17, -15, -10, -6, 6, 10, 15, 17
function Piece:__isvalid_knight(move, array, diff, landing_square_or_piece)
	local valid = false
	local flag = nil
	
	-- The 'polarity' i.e. positive or negative doesn't matter here
	diff = math.abs(diff)

	if diff == 17 or diff == 15 or diff == 10 or diff == 6 then
		valid = true
		valid, flag = self:__capture_check(valid, flag, landing_square_or_piece)
	end

	return valid, flag
end

-- Diff is 8 or 1
function Piece:__isvalid_rook(move, array, diff, landing_square_or_piece)
	local valid = false
	local flag = nil

	local diff = math.abs(diff)
	local mod = math.fmod(diff, 8)  -- Calculate to see if a move is a multiple of 8
	local upper = self.pos[1] * 8
	local lower = upper - 7
	local equiv = utils.get_equivalent(move[1], move[2])

	-- Vertical
	if mod == 0 then
		valid = true
		-- If no pieces are between the current pos and the desired move pos, its valid
		-- self.pos --> desired move pos
		for x = 1, 8 do
			if x > self.pos[1] and x < move[1] or x < self.pos[1] and x > move[1] then 
				local piece = array[x][move[2]]
				if piece ~= nil then
					print("PIECE IN BETWEEN:", piece.name)
					valid = false
					break
				end
			end
		end
		
	elseif equiv <= upper and equiv >= lower then
		valid = true
		-- Check the row for any pieces that stand between the rook and the desired end location
		for y = 1, 8 do
			if y > self.pos[2] and y < move[2] or y < self.pos[2] and y > move[2] then 
				local piece = array[move[1]][y]
				if piece ~= nil then
					print("PIECE IN BETWEEN:", piece.name)
					valid = false
					break
				end
			end
		end
		
	end

	-- 
	valid, flag = self:__capture_check(valid, flag, landing_square_or_piece)
	return valid, flag
end


-- Piece agnostic capture check
function Piece:__capture_check(valid, flag, landing_square_or_piece)
	if landing_square_or_piece ~= nil then
		if landing_square_or_piece.colour ~= self.colour then
			flag = "capture"
		else
			valid = false
			flag = nil
		end
	end
	
	return valid, flag	
end


-- Knight = Piece:new("", "nw", {1, 1}, false)
-- 
-- function Knight:new(id, name, pos, hasMoved)
-- 
-- 	-- o = o or {}
-- 	setmetatable({}, Knight)
-- 
-- 	-- self.__index = self
-- 	self.id = id
-- 	self.name = name
-- 	self.piece = string.sub(name, 1, 1)
-- 	self.colour = string.sub(name, 2, 2)
-- 	self.pos = pos
-- 	self.hasMoved = hasMoved
-- 	self.prevPos = {}
-- 	-- TODO: add scale - different for pawn
-- 	-- self.valid_moves = {}
-- 
-- 	return self
-- end

-- function Knight:isValid(move, array, diff, landing_square_or_piece)
-- 	local valid = false
-- 	local flag = nil
-- 
-- 	local diff = utils.get_equivalent(self.pos[1], self.pos[2]) - utils.get_equivalent(move[1], move[2])
-- 	local landing_square_or_piece = array[move[1]][move[2]] 
-- 
-- 	-- The 'polarity' i.e. positive or negative doesn't matter here
-- 	diff = math.abs(diff)
-- 
-- 	if diff == 17 or diff == 15 or diff == 10 or diff == 6 then
-- 		valid = true
-- 		if landing_square_or_piece ~= nil then
-- 			if landing_square_or_piece.colour ~= self.colour then
-- 				flag = "capture"
-- 			else
-- 				valid = false
-- 				flag = nil
-- 			end
-- 		end
-- 	end
-- 
-- 	return valid, flag
-- end
-- 
-- knight = Knight:new("", "nw", {8, 3}, false)
-- pprint("Knight piece:", knight)




















