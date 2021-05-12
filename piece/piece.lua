local utils = utils or require "utils-module.utils"

-- [[ Piece Class --]]

-- Meta Class
Piece = {id="", name="", pos={}, hasMoved=false}

local valid_hash = {
	["p"] = function(p, m, a, d, l) return p:__isvalid_pawn(m, a, d, l) end,
	["n"] = function(p, m, a, d, l) return p:__isvalid_knight(m, a, d, l) end,
	["r"] = function(p, m, a, d, l) return p:__isvalid_rook(m, a, d, l) end,
	["b"] = function(p, m, a, d, l) return p:__isvalid_bishop(m, a, d, l) end,
	["q"] = function(p, m, a, d, l) return p:__isvalid_queen(m, a, d, l) end,
	["k"] = function(p, m, a, d, l, c) return p:__isvalid_king(m, a, d, l, c) end
}

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
	self.prevHasMoved = hasMoved
	self.lastCaptured = nil
	self.prevLastCaptured = self.lastCaptured

	if self.piece == "p" then
		self.scale = self.scale - 0.04
	end

	-- King specfic attribute
	self.isChecked = false

	return self
end


--[[ Piece Methods ]]
function Piece:move(move, flag, piece_array, last_moved, hide_centre)
	self.prevPos = self.pos
	self.pos = move

	self.prevHasMoved = self.hasMoved
	self.hasMoved = true

	-- If a king moves, then he must've made a valid move that puts him out of check
	if self.piece == "k" then
		self.isChecked = false
	end

	if flag == "en_passant" then

		-- local adjacent_pawn = piece_array[move[1] - 1][move[2]] or piece_array[move[1] + 1][move[2]]  -- Double check this to ensure the wrong pawn is not being targetted
		-- Special case where we make this check near the beginning or end of the board
		local adjacent_pawn
		if move[1] ~= 1 and self.colour == "w" then
			adjacent_pawn = piece_array[move[1] + 1][move[2]]
		elseif move[1] ~= 8 and self.colour == "b" then
			adjacent_pawn = piece_array[move[1] - 1][move[2]]
		end

		if adjacent_pawn ~= nil and adjacent_pawn.id == last_moved[adjacent_pawn.colour]["last_moved_piece_id"] then
			self.lastCaptured = utils.deepcopy(adjacent_pawn)
			msg.post(adjacent_pawn.id, "disable")
			piece_array[adjacent_pawn.pos[1]][adjacent_pawn.pos[2]] = nil
		end

	elseif flag == "capture" then
		self.lastCaptured = utils.deepcopy(piece_array[move[1]][move[2]])
		local captured_go_id = piece_array[move[1]][move[2]].id
		msg.post(captured_go_id, "disable")

	elseif flag == "castle_kingside" then
		local rook = utils.deepcopy(piece_array[move[1]][move[2]])
		self.pos = {move[1], move[2] - 1}
		rook:move({self.pos[1], self.pos[2] - 1}, nil, piece_array, nil, hide_centre)
		-- rook:centre()

	elseif flag == "castle_queenside" then
		local rook = utils.deepcopy(piece_array[move[1]][move[2]])
		self.pos = {move[1], move[2] + 2}
		rook:move({self.pos[1], self.pos[2] + 1 }, nil, piece_array, nil, hide_centre)
		-- rook:centre()
	end

	piece_array[self.prevPos[1]][self.prevPos[2]] = nil  -- Clean up 
	piece_array[self.pos[1]][self.pos[2]] = self
	if not hide_centre then self:centre() end

end


function Piece:undo_last_move(flag, piece_array, hide_centre)

	-- Move out of the way first, so that 'we' don't become overwritten by any of the following operations
	local prev = self.prevHasMoved
	self:move(self.prevPos, nil, piece_array, nil, hide_centre)
	self.hasMoved = prev
	
	if flag == "en_passant" or flag == "capture" then
		local decaptured = self.lastCaptured
		msg.post(decaptured.id, "enable")
		
		-- decaptured:move(decaptured.pos, nil, piece_array, nil)
		piece_array[decaptured.pos[1]][decaptured.pos[2]] = utils.deepcopy(decaptured)
		decaptured:centre()
		
	elseif flag == "castle_kingside" then
		local rook = utils.deepcopy(piece_array[self.pos[1]][self.pos[2] - 1])

		rook:move(rook.prevPos, nil, piece_array, nil, hide_centre)
		rook.hasMoved = false

	elseif flag == "castle_queenside" then
		local rook = utils.deepcopy(piece_array[self.pos[1]][self.pos[2] + 1])
		
		rook:move(rook.prevPos, nil, piece_array, nil, hide_centre)
		rook.hasMoved = false
	end

	return
end


function Piece:_pretend_castle(move, flag, array)
	local rook = utils.deepcopy(array[move[1]][move[2]])

	if flag == "castle_kingside" then
		self:move({move[1], move[2] - 1}, nil, piece_array, nil)
		rook:move({self.pos[1], self.pos[2] - 1}, nil, piece_array, nil)
		
	elseif flag == "castle_queenside" then
		-- 'Pretend' to castle queenside
		self:move({move[1], move[2] + 2}, nil, array, nil)
		rook:move({self.pos[1], self.pos[2] + 1}, nil, array, nil)
	end

	return rook
end


function Piece:_undo_pretend_castle(rook, flag, array)

	if flag == "castle_kingside" or flag == "castle_queenside" then
		rook:move(rook.prevPos, nil, array, nil)
		rook.hasMoved = false
	end

	self:move(self.prevPos, nil, array, nil)
	self.hasMoved = false

end


function Piece:centre()
	local pos = vmath.vector3(utils.get_px_from(self.pos[2]), utils.get_px_from(utils.arr_coords[self.pos[1]]), 0)
	go.set_position(pos, self.id)
	go.set_scale(self.scale, self.id)
end

function Piece:isValid(move, array, caller)
	local valid = false
	local flag = nil
	
	if move[1] == self.pos[1] and move[2] == self.pos[2] then return valid, flag end
	
	-- A variable to passed to isvalid_king to stop an infinite recursive self callback
	local caller = caller or "external"

	local diff = utils.get_equivalent(self.pos[1], self.pos[2]) - utils.get_equivalent(move[1], move[2])
	local landing_square_or_piece = array[move[1]][move[2]]

	-- Dynamically get the appropriate move validation function, and return the results

	-- If we're a king piece, then we need to pass the special 'caller' argument 
	if self.piece == "k" then
		valid, flag = valid_hash[self.piece](self, move, array, diff, landing_square_or_piece, caller)
		return valid, flag
	end

	valid, flag = valid_hash[self.piece](self, move, array, diff, landing_square_or_piece)
	-- valid = is_king_not_checkable(valid, move, self, array)

	return valid, flag
end

-- TODO: Pawn promotion: allowed to all pieces except the king
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

	-- Regular move check
	-- First move can be 2 squares or 1 square forward
	if diff == moves.forward_one and landing_square_or_piece == nil then
		valid = true
		-- return valid, flag

	elseif self.hasMoved == false and diff == moves.forward_one * 2 and landing_square_or_piece == nil then
		if self.colour == "b" then
			valid = array[move[1] - 1][move[2]] == nil
		else
			valid = array[move[1] + 1][move[2]] == nil
		end
		
		-- return valid, flag
	-- end

	-- Capture check
	-- if landing_square_or_piece ~= nil then
	elseif landing_square_or_piece ~= nil then
		local capture_diff = {self.pos[1] - move[1], self.pos[2] - move[2]}
		local is_capture_right_pattern = capture_diff[1] == moves.capture_right_diff[1] and capture_diff[2] == moves.capture_right_diff[2]
		local is_capture_left_pattern = capture_diff[1] == moves.capture_left_diff[1] and capture_diff[2] == moves.capture_left_diff[2]

		if (((diff == moves.capture_right and is_capture_right_pattern) or (diff == moves.capture_left and is_capture_left_pattern))
		or ((diff == moves.capture_right and is_capture_left_pattern) or (diff == moves.capture_left and is_capture_right_pattern)))
		and landing_square_or_piece.colour ~= self.colour then
			valid = true
			flag = "capture"
			-- return valid, flag
		end

	-- else
	elseif landing_square_or_piece == nil then
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
					return valid, flag
				end
			end
		end
	end

	return valid, flag
end


function Piece:__isvalid_knight(move, array, diff, landing_square_or_piece)
	local valid = false
	local flag = nil

	local dir_diff = diff
	
	-- The 'polarity' i.e. positive or negative doesn't matter here
	local diff = math.abs(diff)
	
	local ourx, oury = self.pos[1], self.pos[2]
	local movex, movey = move[1], move[2]
	local diffx, diffy = ourx - movex, oury - movey

	-- Additional direction restraints
	
	local noEaEa = dir_diff == 10 and (diffx == 1 and diffy == 2)
	local soWeWe = dir_diff == -10 and (diffx == -1 and diffy == -2)

	local noNoWe = dir_diff == 15 and (diffx == 2 and diffy == -1)
	local soSoEa = dir_diff == -15 and (diffx == -2 and diffy == 1)

	local noWeWe = dir_diff == 6 and (diffx == 1 and diffy == -2)
	local soEaEa = dir_diff == -6 and (diffx == -1 and diffy == 2)

	local noNoEa = dir_diff == 17 and (diffx == 2 and diffy == 1)
	local soSoWe = dir_diff == -17 and (diffx == -2 and diffy == -1)

	if (noEaEa or soWeWe) or (noNoWe or soSoEa) or (noWeWe or soEaEa) or (noNoEa or soSoWe) then
	-- if diff == 17 or diff == 15 or (noEaEa or soWeWe) or diff == 6 then
		valid = true
		valid, flag = self:__capture_check(valid, flag, landing_square_or_piece)
	end

	return valid, flag
end


function Piece:__isvalid_rook(move, array, diff, landing_square_or_piece)
	local valid = false
	local flag = nil

	-- TODO: rook validation
	local diff = math.abs(diff)
	local mod = math.fmod(diff, 8)  -- Calculate to see if a move is a multiple of 8
	local upper = self.pos[1] * 8
	local lower = upper - 7
	local equiv = utils.get_equivalent(move[1], move[2])

	local dir_diff = diff
	local ourx, oury = self.pos[1], self.pos[2]
	local movex, movey = move[1], move[2]

	local noSo = dir_diff % 8 == 0 and ((ourx > movex or ourx < movex) and oury == movey)
	local eaWe = dir_diff % 1 == 0 and (ourx == movex and (oury > movey or oury < movey))

	if noSo then
		valid = true
		
		if ourx < movex then
			local tempx = ourx
			ourx = movex
			movex = tempx
		end
		
		-- Find pieces in the way of our start and end pos by decrementing to the end
		while true do
			
			ourx = ourx - 1
			if ourx <= movex then break end
			if array[ourx][oury] ~= nil then valid = false break end
		end
	elseif eaWe then
		valid = true

		if oury < movey then
			local tempy = oury
			oury = movey
			movey = tempy
		end
		
		while true do
			oury = oury - 1
			if oury <= movey then break end
			if array[ourx][oury] ~= nil then valid = false break end
		end
	end
	
-- 	-- Vertical
-- 	if mod == 0 then
-- 		valid = true
-- 		-- If no pieces are between the current pos and the desired move pos, its valid
-- 		-- self.pos --> desired move pos
-- 		for x = 1, 8 do
-- 			if x > self.pos[1] and x < move[1] or x < self.pos[1] and x > move[1] then 
-- 				local piece = array[x][move[2]]
-- 				if piece ~= nil then
-- 					-- print(self.name, "PIECE IN BETWEEN:", piece.name)
-- 					valid = false
-- 					goto r_capture_check
-- 				end
-- 			end
-- 		end
-- 
-- 		-- Horizontal
-- 	elseif equiv <= upper and equiv >= lower then
-- 		valid = true
-- 		-- Check the row for any pieces that stand between the rook and the desired end location
-- 		for y = 1, 8 do
-- 			if y > self.pos[2] and y < move[2] or y < self.pos[2] and y > move[2] then 
-- 				local piece = array[move[1]][y]
-- 				if piece ~= nil then
-- 					-- print(self.name, "PIECE IN BETWEEN:", piece.name)
-- 					valid = false
-- 					goto r_capture_check
-- 				end
-- 			end
-- 		end
-- 
-- 	end

	::r_capture_check::
	valid, flag = self:__capture_check(valid, flag, landing_square_or_piece)
	return valid, flag
end


function Piece:__isvalid_bishop(move, array, diff, landing_square_or_piece)
	local valid, flag = false, nil
	local dir_diff = diff
	local diff = math.abs(diff)
	local mod_9 = math.fmod(diff, 9)
	local mod_7 = math.fmod(diff, 7)
	
	local ourx, oury = self.pos[1], self.pos[2]
	local movex, movey = move[1], move[2]
	local diffx, diffy = ourx - movex, oury - movey

	-- +7: 5,4 --> 4,5 3,6, opposite applies for -7
	-- +9: 5,6 --> 3,4, opposite for -9
	local noEa = dir_diff % 7 == 0 and (diffx > 0 and diffy < 0)
	local soWe = dir_diff % 7 == 0 and (diffx < 0 and diffy > 0)

	local noWe = dir_diff % 9 == 0 and (diffx > 0 and diffy > 0)
	local soEa = dir_diff % 9 == 0 and (diffx < 0 and diffy < 0)

	-- Look for pieces that are between our start and end point
	if noEa or soWe then
		-- If ourx is less than movex, swap them to validate the while if condition
		if ourx < movex then
			local tempx, tempy = ourx, oury
			ourx, oury = movex, movey
			movex, movey = tempx, tempy
		end
		
		-- while ourx > movex and oury < movey do
		valid = true
		while true do
			ourx = ourx - 1
			oury = oury + 1
			if ourx <= movex and oury >= movey then break end
			if array[ourx][oury] ~= nil then valid = false break end
		end
		
	elseif noWe or soEa then

		if ourx < movex then
			local tempx, tempy = ourx, oury
			ourx, oury = movex, movey
			movex, movey = tempx, tempy
		end
		
		valid = true
		while true do
			ourx = ourx - 1
			oury = oury - 1
			if ourx <= movex and oury <= movey then break end
			if array[ourx][oury] ~= nil then valid = false break end
		end
	end

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
	local dir_diff = diff
	local diff = math.abs(diff)
	local caller = called

	local ourx, oury = self.pos[1], self.pos[2]
	local movex, movey = move[1], move[2]
	local diffx, diffy = ourx - movex, oury - movey

	local north = dir_diff == 8 and (diffx == 1 and diffy == 0)
	local south = dir_diff == -8 and (diffx == -1 and diffy == 0)

	local east = dir_diff == -1 and (diffx == 0 and diffy == -1)
	local west = dir_diff == 1 and (diffx == 0 and diffy == 1)
	
	local noEa = dir_diff == 7 and (diffx == 1 and diffy == -1)
	local soWe = dir_diff == -7 and (diffx == -1 and diffy == 1)
	
	local noWe = dir_diff == 9 and (diffx == 1 and diffy == 1)
	local soEa = dir_diff == -9 and (diffx == -1 and diffy == -1)

	if north or south or west or east or noEa or soWe or noWe or soEa then
		valid = true
	-- end

	-- Castling
	-- If the king and the selected rook hasn't moved, and there are no pieces in between, then castle
	-- 4 = Left, 3 = Right
	elseif self.hasMoved == false and self.isChecked == false then
	-- if self.hasMoved == false and self.isChecked == false then
		local piece = array[move[1]][move[2]]
		if piece ~= nil and piece.piece == "r" and self.colour == piece.colour and piece.hasMoved == false then

			-- If we want to castle king's side
			if diff == 3 then
				-- If the spaces between the king and rook are empty, castle
				if array[self.pos[1]][self.pos[2] + 1] == nil and array[self.pos[1]][self.pos[2] + 2] == nil then
					valid, flag = true, "castle_kingside"
				end

				-- If we want to castle queen's side
			elseif diff == 4 then
				-- If the 3 spaces between the king and rook queen's side are empty, castle
				if array[self.pos[1]][self.pos[2] - 1] == nil and array[self.pos[1]][self.pos[2] - 2] == nil 
				and array[self.pos[1]][self.pos[2] - 3] == nil then
					valid, flag = true, "castle_queenside"
				end
			end 
		end
	end


	-- Invalid moves: puts the king in check
	local piece_valid
	if caller == "external" and valid then
		-- Put the king in that position to allow enemy pieces to calculate piece:isValid
		-- and remove him for the previous position temporarily
		local temp_piece_or_rook

		if flag == "castle_kingside" or flag == "castle_queenside" then
			temp_piece_or_rook = self:_pretend_castle(move, flag, array)
		else
			temp_piece_or_rook = utils.deepcopy(array[move[1]][move[2]])  -- Copy the piece (or empty) we're about to move onto
			array[move[1]][move[2]] = self  -- Move to the new position
			array[self.pos[1]][self.pos[2]] = nil  -- Remove the previous position
			-- self:move(move, nil, array, nil)
		end

		-- Can any of the enemy pieces capture/check us in the new position/move? valid = false if so
		local piece_valid, piece_flag 
		for x = 1, 8 do
			for y = 1, 8 do
				local piece = array[x][y]
				if piece ~= nil and piece ~= self and piece.colour ~= self.colour then
					piece_valid, piece_flag = piece:isValid(move, array, "internal")

					-- Castling specific capture checks
					if flag == "castle_kingside" then
						-- piece_valid, piece_flag = piece:isValid({move[1], move[2] - 1}, array, "internal")
						piece_valid, piece_flag = piece:isValid(self.pos, array, "internal")

					elseif flag == "castle_queenside" then
						-- piece_valid, piece_flag = piece:isValid({move[1], move[2] + 2}, array, "internal")
						piece_valid, piece_flag = piece:isValid(self.pos, array, "internal")
						
					end

					if piece_valid and piece_flag == "capture" then

						-- Remove the king from that 'imaginary' position
						if flag == "castle_kingside" or flag == "castle_queenside" then
							self:_undo_pretend_castle(temp_piece_or_rook, flag, array)
						else
							array[move[1]][move[2]] = temp_piece_or_rook
							array[self.pos[1]][self.pos[2]] = self
						end

						return false, nil
					end
				end
			end
		end

		-- Remove the king from that 'imaginary' position in case we haven't returned from the function
		if flag == "castle_kingside" or flag == "castle_queenside" then
			self:_undo_pretend_castle(temp_piece_or_rook, flag, array)
			return valid, flag
		else
			array[move[1]][move[2]] = temp_piece_or_rook
			array[self.pos[1]][self.pos[2]] = self
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


function Piece:get_valid_moves(array)
	local valid_moves = {}

	local valid, flag, move
	for x = 1, 8 do
		for y = 1, 8 do
			move = {x, y}
			valid, flag = self:isValid(move, array)

			if self.piece ~= "k" and valid then
				valid = is_king_not_checkable(valid, move, self, array, flag)
			end

			if valid then
				table.insert(valid_moves, {move, flag})
			end
		end
	end
	
	return valid_moves
end


-- Return: bool
-- Function: iterate over opposing pieces to see if they can 'capture' the king once we make our desired move -- put him in check too if so
function is_king_not_checkable(valid, move, moving_piece, array, flag)

	-- TODO: move this outside the function so that it isn't called for every move unnecessarily
	local king = get_king(moving_piece.colour, array)

	if valid == false then
		return false
	end

	-- Make the move then check if the king can still be captured, then undo those changes regardless
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
	local piece
	for x = 1, 8 do
		for y = 1, 8 do
			piece = array[x][y]
			if piece ~= nil and piece.name == "k" .. colour then
				return piece
			end
		end
	end
end
