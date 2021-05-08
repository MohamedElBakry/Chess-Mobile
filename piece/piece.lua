local utils = require "utils-module.utils"

-- This seems inefficient, so consider making more specific sub classes from Piece, e.g. Pawn, Knight, Queen ...

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
	self.prevPos = self.pos
	self.scale = 0.45
	if self.piece == "p" then
		self.scale = self.scale - 0.04
	end
	
	-- King specfic attribute
	self.isChecked = false

	return self
end


--[[ Piece Methods ]]
function Piece:move(pos, piece_array)
	self.prevPos = self.pos
	self.pos = pos
	self.hasMoved = true

	-- If a king moves, then he must've made a valid move that puts him out of check
	if self.piece == "k" then
		self.isChecked = false
	end

	-- Reflect positional changes in the piece_array
	piece_array[self.pos[1]][self.pos[2]] = self
	piece_array[self.prevPos[1]][self.prevPos[2]] = nil
	
end

-- Get a 'representation' of the position
function Piece:get_repr_pos()
	return "(" .. self.pos[1] .. ", " .. self.pos[2] .. ")"
end

function Piece:set_pos(pos)
	self.pos = pos
end

function Piece:isValid(move, array, caller)
	local valid = false
	local flag = nil
	
	-- A variable to passed to isvalid_king to stop an infinite recursive self callback
	local caller = caller or "external"
	
	-- Creating these functions every time the function is run may be costly
	local valid_hash = {
		["p"] = function(m, a, d, l) return self:__isvalid_pawn(m, a, d, l) end,
		["n"] = function(m, a, d, l) return self:__isvalid_knight(m, a, d, l) end,
		["r"] = function(m, a, d, l) return self:__isvalid_rook(m, a, d, l) end,
		["b"] = function(m, a, d, l) return self:__isvalid_bishop(m, a, d, l) end,
		["q"] = function(m, a, d, l) return self:__isvalid_queen(m, a, d, l) end,
		["k"] = function(m, a, d, l, c) return self:__isvalid_king(m, a, d, l, c) end
	}

	local diff = utils.get_equivalent(self.pos[1], self.pos[2]) - utils.get_equivalent(move[1], move[2])
	local landing_square_or_piece = array[move[1]][move[2]]

	-- Dynamically get the appropriate move validation function, and return the results


	-- If we're a king piece, then we need to pass the special 'caller' argument 
	if self.piece == "k" then
		valid, flag = valid_hash[self.piece](move, array, diff, landing_square_or_piece, caller)
		return valid, flag
	end

	valid, flag = valid_hash[self.piece](move, array, diff, landing_square_or_piece)
	-- valid = is_king_not_checkable(valid, move, self, array)
	
	return valid, flag
end

-- TODO: Pawn promotion: allowed to all piece except the king
function Piece:__isvalid_pawn(move, array, diff, landing_square_or_piece)
	local valid = false
	local flag = nil
	
	moves = { 
		capture_left=9, 
		capture_right=7,
		capture_left_diff={1, 1},
		capture_right_diff={1, -1},
		forward_one=8 
	}

	-- Negate (make negative, -n) the black pawn moves 
	if self.colour == "b" then
		for k, v in pairs(moves) do
			if type(v) ~= "table" then
				moves[k] = -v
			else
				moves[k][1] = -v[1]
			end
		end
	end

	-- Capture check
	-- Compare current pos with new desired pos for capture patterns
	if landing_square_or_piece ~= nil then
		local capture_diff = {self.pos[1] - move[1], self.pos[2] - move[2]}
		local is_capture_right_pattern = capture_diff[1] == moves.capture_right_diff[1] and capture_diff[2] == moves.capture_right_diff[2]
		local is_capture_left_pattern = capture_diff[1] == moves.capture_left_diff[1] and capture_diff[2] == moves.capture_left_diff[2]
		
		if (((diff == moves.capture_right and is_capture_right_pattern) or (diff == moves.capture_left and is_capture_left_pattern))
		or ((diff == moves.capture_right and is_capture_left_pattern) or (diff == moves.capture_left and is_capture_right_pattern)))
		and landing_square_or_piece.colour ~= self.colour then
			valid = true
			flag = "capture"
		end
		
	else
		-- En passant
		-- Diagonal capture behind a pawn directly to the left or right of us, which just moved 2 squares forward
		if diff == moves.capture_right or diff == moves.capture_left then
			
			-- Get the piece that is directly adjacent to this pawn, because if we're for example white then we want the square 'below' the square we clicked
			local piece
			-- Special case where we make this check near the beginning or end of the board
			if move[1] ~= 1 and self.colour == "w" then
				piece = array[move[1] + 1][move[2]]
			elseif move[1] ~= 8 and self.colour == "b" then
				piece = array[move[1] - 1][move[2]]
			end
			
			if piece ~= nil and piece.colour ~= self.colour and piece.piece == "p" then
				-- Check if it just moved 2 squares forward
				local piece_diff = math.abs(utils.get_equivalent(piece.prevPos[1], piece.prevPos[2]) - utils.get_equivalent(piece.pos[1], piece.pos[2]))
				if piece_diff == math.abs(moves.forward_one * 2) then
					valid = true
					flag = "en_passant"
				end
			end
		end
	end

	-- Regular move check
	-- First move can be 2 squares forward or 1 square
	if diff == moves.forward_one and landing_square_or_piece == nil then
		valid = true
		
	elseif self.hasMoved == false and diff == moves.forward_one * 2 and landing_square_or_piece == nil then
		if self.colour == "b" then
			valid = array[move[1] - 1][move[2]] == nil
		else
			valid = array[move[1] + 1][move[2]] == nil
		end
	end
	
	return valid, flag
end


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
					-- print(self.name, "PIECE IN BETWEEN:", piece.name)
					valid = false
					goto r_capture_check
				end
			end
		end

	-- Horizontal
	elseif equiv <= upper and equiv >= lower then
		valid = true
		-- Check the row for any pieces that stand between the rook and the desired end location
		for y = 1, 8 do
			if y > self.pos[2] and y < move[2] or y < self.pos[2] and y > move[2] then 
				local piece = array[move[1]][y]
				if piece ~= nil then
					-- print(self.name, "PIECE IN BETWEEN:", piece.name)
					valid = false
					goto r_capture_check
				end
			end
		end
		
	end

	::r_capture_check::
	valid, flag = self:__capture_check(valid, flag, landing_square_or_piece)
	return valid, flag
end


function Piece:__isvalid_bishop(move, array, diff, landing_square_or_piece)
	local valid, flag = false, nil
	local diff = math.abs(diff)
	local mod_9 = math.fmod(diff, 9)
	local mod_7 = math.fmod(diff, 7)

	-- Create a table of potentia valid moves based on our current position
	local potential_valid_moves = {}
	local x, y = self.pos[1], self.pos[2]
	while x < 8 and y < 8 do
		x = x + 1
		y = y + 1
		table.insert(potential_valid_moves, {x, y})
	end
	
	x, y = self.pos[1], self.pos[2]
	while x > 1 and y > 1 do
		x = x - 1
		y = y - 1
		table.insert(potential_valid_moves, {x, y})
	end	

	x, y = self.pos[1], self.pos[2]
	while x > 1 and y < 8 do
		x = x - 1
		y = y + 1
		table.insert(potential_valid_moves, {x, y})
	end

	x, y = self.pos[1], self.pos[2]
	while x < 8 and y > 1 do
		x = x + 1
		y = y - 1
		table.insert(potential_valid_moves, {x, y})
	end

	-- Look for the desired move in the potential_valid_moves, if we don't find it it's not valid
	for i, potential_move in ipairs(potential_valid_moves) do
		if potential_move[1] == move[1] and potential_move[2] == move[2] then
			valid = true
		end
	end
	
	if valid == false then
		return valid, flag
	end

	
	-- Look for any pieces that are in our path
	local x, y = 0, 0
	local x_max, y_max = 0, 0

	-- If X isn't the same, then this might be a valid move. 
	-- Because, otherwise that means the bishop is moving horizontally which is illegal
	-- This is necessary because the diff from (X, 8) to (X, 1) is 7, which triggers mod_7 == 0
	if self.pos[1] ~= move[1] then
		
		-- Diagonally, ensure no pieces are present between the current pos and the desired pos
		if mod_9 == 0 then
			-- valid = true
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
					-- print(piece.name, x, y)
					valid = false
					goto b_capture_check
				end
				x = x + 1
				y = y + 1
			end
			
		elseif mod_7 == 0 then
			-- valid = true
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
					-- print(piece.name, x, y)
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


function Piece:__isvalid_king(move, array, diff, landing_square_or_piece, called)
	local valid, flag = false, nil
	local diff = math.abs(diff)
	local caller = called
	
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
	if self.hasMoved == false and self.isChecked == false then
		local piece = array[move[1]][move[2]]
		if piece ~= nil and piece.piece == "r" and self.colour == piece.colour and piece.hasMoved == false then
			
			-- If we want to castle king's side
			if diff == 3 then
				-- If the spaces between the king and rook are empty, castle
				if array[self.pos[1]][self.pos[2] + 1] == nil and array[self.pos[1]][self.pos[2] + 2] == nil then
					
					-- Remove the pieces from the old positions
					-- array[self.pos[1]][self.pos[2]] = nil
					-- array[move[1]][move[2]] = nil
					
					-- Castle
					-- self:move({self.pos[1], self.pos[2] + 2}, array)
					-- piece:move({self.pos[1], self.pos[2] - 1}, array)
					
					valid, flag = true, "castle_kingside"
				end
					
				-- If we want to castle queen's side
			elseif diff == 4 then
				-- If the 3 spaces between the king and rook queen's side are empty, castle
				if array[self.pos[1]][self.pos[2] - 1] == nil and array[self.pos[1]][self.pos[2] - 2] == nil 
				and array[self.pos[1]][self.pos[2] - 3] == nil then
					
					-- Remove the pieces from the old positions
					-- array[self.pos[1]][self.pos[2]] = nil
					-- array[move[1]][move[2]] = nil
					
					-- Castle
					-- self:move({self.pos[1], self.pos[2] - 2}, array)
					-- piece:move({self.pos[1], self.pos[2] + 1}, array)
					valid, flag = true, "castle_queenside"
				end
			end 

			-- Update the array with the new piece positions
			-- array[self.pos[1]][self.pos[2]] = self
			-- array[piece.pos[1]][piece.pos[2]] = piece

			-- Update the king and rook based on the array 
-- 			local pos = vmath.vector3(utils.get_px_from(self.pos[2]), utils.get_px_from(utils.arr_coords[self.pos[1]]), 0)
-- 			go.set_position(pos, self.id)
-- 
-- 			local rook = piece
-- 			pos = vmath.vector3(utils.get_px_from(rook.pos[2]), utils.get_px_from(utils.arr_coords[rook.pos[1]]), 0)
-- 			go.set_position(pos, rook.id)
			
		end
	end

	
	-- Invalid moves: puts the king in check
	local piece_valid
	if caller == "external" then
		-- Put the king in that position to allow enemy pieces to calculate piece:isValid
		-- and remove him for the previous position temporarily
		local temp_piece

		if flag == "castle_kingside" or flag == "castle_queenside" then
			temp_piece = self:_pretend_castle(move, flag, array)
		else
			temp_piece = utils.deepcopy(array[move[1]][move[2]])  -- Copy the piece (or empty) we're about to move onto
			array[move[1]][move[2]] = self  -- Move to the new position
			array[self.pos[1]][self.pos[2]] = nil  -- Remove the previous position
		end

		local piece_valid, piece_flag 
		for x = 1, 8 do
			for y = 1, 8 do
				local piece = array[x][y]
				if piece ~= nil and piece ~= self.piece and piece.colour ~= self.colour then
					piece_valid, piece_flag = piece:isValid(move, array, "internal")
					
					-- Castling specific capture checks
					if flag == "castle_kingside" then
						piece_valid, piece_flag = piece:isValid({move[1], move[2] - 1}, array, "internal")
						
					elseif flag == "castle_queenside" then
						piece_valid, piece_flag = piece:isValid({move[1], move[2] + 2}, array, "internal")
					end
					
					if piece_valid and piece_flag == "capture" then

						-- Remove the king from that 'imaginary' position
						if flag == "castle_kingside" or flag == "castle_queenside" then
							self:_undo_pretend_castle(temp_piece, move, flag, array)
						else
							array[move[1]][move[2]] = temp_piece
							array[self.pos[1]][self.pos[2]] = self
						end
						
						return false, nil
					end
				end
			end
		end
		
		-- Remove the king from that 'imaginary' position in case we haven't returned from the function
		if flag == "castle_kingside" or flag == "castle_queenside" then
			self:_undo_pretend_castle(temp_piece, move, flag, array)
			return valid, flag
		else
			array[move[1]][move[2]] = temp_piece
			array[self.pos[1]][self.pos[2]] = self
		end

	end
	
	valid, flag = self:__capture_check(valid, flag, landing_square_or_piece)
	return valid, flag
end


function Piece:_pretend_castle(move, flag, array)
	local rook = utils.deepcopy(array[move[1]][move[2]])
	
	if flag == "castle_kingside" then
		
		-- 'Pretend' to castle
		array[move[1]][move[2] - 1] = self
		array[move[1]][move[2] - 2] = rook
		
		array[self.pos[1]][self.pos[2]] = nil
		array[move[1]][move[2]] = nil

	else
		-- 'Pretend' to castle queenside
		array[move[1]][move[2] + 2] = self
		array[move[1]][move[2] + 1] = rook
		
		array[self.pos[1]][self.pos[2]] = nil  -- Update the array with our new position
		array[move[1]][move[2]] = nil
	end

	return rook
end


function Piece:_undo_pretend_castle(rook, move, flag, array)
	
	if flag == "castle_kingside" then
		array[move[1]][move[2] - 1] = nil  -- Remove the king
		array[move[1]][move[2] - 2] = nil  -- Remove the rook
	elseif flag == "castle_queenside" then
		array[move[1]][move[2] + 2] = nil  -- Remove the king
		array[move[1]][move[2] + 1] = nil  -- Remove the rook
	end
	
	array[move[1]][move[2]] = rook
	array[self.pos[1]][self.pos[2]] = self
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


function Piece:get_valid_moves(array)
	local valid_moves = {}

	local valid, flag, move
	for x = 1, 8 do
		for y = 1, 8 do
			move = {x, y}
			valid, flag = self:isValid(move, array)
			
			if self.piece ~= "k" then
				valid = is_king_not_checkable(valid, move, self, array, flag)
			end
			
			if valid then
				table.insert(valid_moves, {x, y})
			end
		end
	end
	
	return valid_moves
end


-- Return: bool
-- Function: iterate over opposing pieces to see if they can 'capture' the king once we make our desired move -- put him in check too if so
function is_king_not_checkable(valid, move, moving_piece, array, flag)

	local king = get_king(moving_piece.colour, array)

	-- Make the move then check if the king can still be captured, then undo those changes regardless
	if valid == false then
		return false
	end

	local temp_captured = utils.deepcopy(array[move[1]][move[2]])
	array[move[1]][move[2]] = moving_piece
	array[moving_piece.pos[1]][moving_piece.pos[2]] = nil

	local adjacent_pawn_black, adjacent_pawn_white
	if flag == "en_passant" then
		adjacent_pawn_black = utils.deepcopy(array[move[1] - 1][move[2]])
		adjacent_pawn_white = utils.deepcopy(array[move[1] + 1][move[2]])
		if adjacent_pawn_black then
			array[move[1] - 1][move[2]] = nil
		elseif adjacent_pawn_white then
			array[move[1] + 1][move[2]] = nil
		end
	end

	local piece_valid
	for x = 1, 8 do
		for y = 1, 8 do
			local piece = array[x][y]
			-- Check if this enemy piece can capture this piece's king
			if piece ~= nil and piece.colour ~= moving_piece.colour then
				local piece_valid, piece_flag = piece:isValid(king.pos, array)
				if piece_valid and piece_flag == "capture" then
					king.isChecked = true
					array[move[1]][move[2]] = temp_captured
					array[moving_piece.pos[1]][moving_piece.pos[2]] = moving_piece
					-- En passant specific undo
					if flag == "en_passant" and adjacent_pawn_black ~= nil then
						array[move[1] - 1][move[2]] = adjacent_pawn_black
					elseif flag == "en_passant" and adjacent_pawn_white ~= nil then
						array[move[1] + 1][move[2]] = adjacent_pawn_white
					end
					
					return false
				end
			end
		end
	end

	array[move[1]][move[2]] = temp_captured
	array[moving_piece.pos[1]][moving_piece.pos[2]] = moving_piece
	if flag == "en_passant" and adjacent_pawn_black ~= nil then
		array[move[1] - 1][move[2]] = adjacent_pawn_black
	elseif flag == "en_passant" and adjacent_pawn_white ~= nil then
		array[move[1] + 1][move[2]] = adjacent_pawn_white
	end
	
	return valid

end


function get_king(colour, array)
	local king
	for x = 1, 8 do
		for y = 1, 8 do
			piece = array[x][y]
			if piece ~= nil and piece.name == "k" .. colour then
				return piece
			end
		end
	end
end