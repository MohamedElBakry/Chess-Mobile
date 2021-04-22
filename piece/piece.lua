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
		["b"] = function(m, a, d, l) return self:__isvalid_bishop(m, a, d, l) end,
		["q"] = function(m, a, d, l) return self:__isvalid_queen(m, a, d, l) end,
		["k"] = function(m, a, d, l) return self:__isvalid_king(m, a, d, l) end
	}

	-- 
	local diff = utils.get_equivalent(self.pos[1], self.pos[2]) - utils.get_equivalent(move[1], move[2])
	local landing_square_or_piece = array[move[1]][move[2]]

	-- Dynamically get the appropriate move validation function, and return the results
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

	valid, flag = self:__capture_check(valid, flag, landing_square_or_piece)
	return valid, flag
end


-- Diff mod 9 or 7 == 0 is valid
function Piece:__isvalid_bishop(move, array, diff, landing_square_or_piece)
	local valid, flag = false, nil
	local diff = math.abs(diff)
	local mod_9 = math.fmod(diff, 9)
	local mod_7 = math.fmod(diff, 7)

	local x, y = 0, 0
	local x_max, y_max = 0, 0

	-- If X isn't the same, then this might be a valid move. 
	-- Because, otherwise that means the bishop is moving horizontally which is illegal
	-- This is necessary because the diff from (X, 8) to (X, 1) is 7, which triggers mod_7 == 0
	if self.pos[1] ~= move[1] then
		
		-- Diagonally, ensure no pieces are present between the current pos and the desired pos
		if mod_9 == 0 then
			valid = true
			if self.pos[1] < move[1] then
				
				x, y = self.pos[1] + 1, self.pos[2] + 1
				x_max, y_max = move[1], move[2]
				
			else
				x, y = move[1] + 1, move[2] + 1
				x_max, y_max = self.pos[1], self.pos[2]
				
			end
			
			while x < x_max and y < y_max do
				local piece = array[x][y]
				if piece ~= nil then
					print(piece.name, x, y)
					valid = false
					goto b_capture_check
				end
				x = x + 1
				y = y + 1
			end
			
		elseif mod_7 == 0 then
			valid = true
			if self.pos[1] < move[1] then

				x, y = self.pos[1] + 1, self.pos[2] - 1
				x_max, y_max = move[1], move[2]

			else
				x, y = move[1] + 1, move[2] - 1
				-- x_max, y_max = self.pos[1] - 1, self.pos[2] + 1
				x_max, y_max = self.pos[1], self.pos[2]

			end

			while x < x_max and y < y_max or y > y_max do
				local piece = array[x][y]
				if piece ~= nil then
					print(piece.name, x, y)
					valid = false
					goto b_capture_check
				end
				x = x + 1
				y = y - 1
			end
		end
	end
	
	-- print(self.pos[1], self.pos[2], move[1], move[2])
	
	::b_capture_check::
	valid, flag = self:__capture_check(valid, flag, landing_square_or_piece)
	return valid, flag

end

function Piece:__isvalid_queen(move, array, diff, landing_square_or_piece)
	local flag = nil
	-- The queen moves like a bishop or rook. So if either check is true, then the move is valid 
	local valid = self:__isvalid_rook(move, array, diff, landing_square_or_piece) 
	or self:__isvalid_bishop(move, array, diff, landing_square_or_piece)
	
	valid, flag = self:__capture_check(valid, flag, landing_square_or_piece)
	return valid, flag
end

-- 1, 7, 9, 8
function Piece:__isvalid_king(move, array, diff, landing_square_or_piece)
	local valid, flag = false, nil
	local diff = math.abs(diff)
	
	if diff == 1 or diff == 7 or diff == 8 or diff == 9 then
		valid = true
		-- Ensure the king cannot jump from the 8th to the 1st column
		if diff == 7 and self.pos[1] == move[1] then 
			valid = false
		end
	end

	-- Castling
	-- If the king and the selected rook hasn't moved, and there are no pieces in between, then castle
	-- Castle: king moves 2 places towards the rook and the rook is closer to the centre
	-- 4 = Left, 3 = Right
	if self.hasMoved == false then
		local piece = array[move[1]][move[2]]
		if piece ~= nil and piece.piece == "r" and piece.hasMoved == false then
			
			-- If we want to castle king's side
			if diff == 3 then
				-- If the spaces between the king and rook are empty, castle
				if array[self.pos[1]][self.pos[2] + 1] == nil and array[self.pos[1]][self.pos[2] + 2] == nil then
					-- Remove the pieces from the old positions
					array[self.pos[1]][self.pos[2]] = nil
					array[move[1]][move[2]] = nil
					
					-- Castle
					self:move({self.pos[1], self.pos[2] + 2})
					piece:move({self.pos[1], self.pos[2] - 1})
					valid, flag = true, "castle"
				end
					
				-- If we want to castle queen's side
			elseif diff == 4 then
				-- If the 3 spaces between the king and rook queen's side are empty, castle
				if array[self.pos[1]][self.pos[2] - 1] == nil and array[self.pos[1]][self.pos[2] - 2] == nil 
					and array[self.pos[1]][self.pos[2] - 3] == nil then
					-- Remove the pieces from the old positions
					array[self.pos[1]][self.pos[2]] = nil
					array[move[1]][move[2]] = nil
					
					-- Castle
					self:move({self.pos[1], self.pos[2] - 2})
					piece:move({self.pos[1], self.pos[2] + 1})
					valid, flag = true, "castle"
				end
			end 

			-- Update the array with the new piece positions
			array[self.pos[1]][self.pos[2]] = self
			array[piece.pos[1]][piece.pos[2]] = piece

			-- Update the king and rook based on the array 
			local pos = vmath.vector3(utils.get_px_from(self.pos[2]), utils.get_px_from(utils.arr_coords[self.pos[1]]), 0)
			go.set_position(pos, self.id)

			local rook = piece
			pos = vmath.vector3(utils.get_px_from(rook.pos[2]), utils.get_px_from(utils.arr_coords[rook.pos[1]]), 0)
			go.set_position(pos, rook.id)
			
		end
	end
	
	
	
	
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
