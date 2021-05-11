local utils = utils or require "utils-module.utils"
local piece = piece or require "piece.piece"

--[[
AI Module
Responsible for replying with moves
-- ]]

-- Meta Class
-- Ai = {}
-- 
-- -- Derived Class
-- function Ai:new()
-- 
-- 	-- Initialise 'class'
-- 	setmetatable({}, Ai)
-- 
-- 	-- Attributes
-- 	self.pawn_value = 100
-- 	self.knight_value = 350
-- 	self.bishop_value = 350
-- 	self.rook_value = 525
-- 	self.queen_value = 1000
-- 	
-- 	return self
-- 	
-- end

ai = ai or {}

PAWN_VALUE = 100
KNIGHT_VALUE = 350
BISHOP_VALUE = 350
ROOK_VALUE = 525
QUEEN_VALUE = 1000
-- KING_VALUE = 10000

_turn_counter = 0

function evaluate(piece_array)
	local evaluation
	
	local white = _count_material("w", piece_array)
	local black = _count_material("b", piece_array)

	-- Higher is better
	evaluation = black - white
	
	return evaluation
end

-- ai.evaluate = evaluate

function _count_material(colour, piece_array)
	local material = 0
	local pieces_count = {p=0, n=0, b=0, r=0, q=0, k=0}
	
	local piece
	for x = 1, 8 do
		for y = 1, 8 do
			piece = piece_array[x][y]
			if piece ~= nil and piece.colour == colour then
				pieces_count[piece.piece] = pieces_count[piece.piece] + 1
			end
		end
	end

	-- Count the material
	material = material + pieces_count["p"] * PAWN_VALUE
	material = material + pieces_count["n"] * KNIGHT_VALUE
	material = material + pieces_count["b"] * BISHOP_VALUE
	material = material + pieces_count["q"] * QUEEN_VALUE
	
	return material
end


-- NegaMax search
function search(depth, piece_array)
	if depth == 0 then return evaluate(piece_array) end
	local max = -math.huge
	local score

	local moves = generate_moves(piece_array)
	local move_from
	local move_to
	local temp_landing_square
	
	for i, move in ipairs(moves) do
		move_from = move[1]
		move_to = move[2]
		
		-- Make move
		temp_landing_square = utils.deepcopy(piece_array[move_to[1]][move_to[2]])
		piece_array[move_to[1]][move_to[2]] = utils.deepcopy(piece_array[move_from[1]][move_from[2]]) -- Go to the square
		piece_array[move_from[1]][move_from[2]] = nil  -- Remove the previous copy
		
		-- Eval
		score = -search(depth - 1, piece_array)
		print(score)
		
		-- Unmake
		piece_array[move_from[1]][move_from[2]] = utils.deepcopy(piece_array[move_to[1]][move_to[2]])  -- Move the original moving piece back
		piece_array[move_to[1]][move_to[2]] = temp_landing_square

		if score > max then
			max = score
		end
	end

	print("TURN COUNTER:", _turn_counter)
	return max
end

function move_gen_test(depth, piece_array, last_moved)
	if depth == 0 then
		return 1 
	end

	local moves = generate_moves(piece_array)
	local num_positions = 0
	local move_from, move_to, flag
	local temp_landing_square
	
	for i, move_data in ipairs(moves) do
		move_from = move_data[1]
		move_to = move_data[2]
		flag = move_data[3]

		local piece = piece_array[move_from[1]][move_from[2]]
		
		-- Make move
		piece:move(move_to, flag, piece_array, last_moved)
		-- temp_landing_square = utils.deepcopy(piece_array[move_to[1]][move_to[2]])
		-- piece_array[move_to[1]][move_to[2]] = utils.deepcopy(piece_array[move_from[1]][move_from[2]]) -- Go to the square
		-- piece_array[move_from[1]][move_from[2]] = nil  -- Remove the previous copy

		-- Eval
		num_positions = num_positions + move_gen_test(depth - 1, piece_array)

		-- Unmake
		piece:undo_last_move(flag, piece_array)
		-- piece_array[move_from[1]][move_from[2]] = utils.deepcopy(piece_array[move_to[1]][move_to[2]])  -- Move the original moving piece back
		-- piece_array[move_to[1]][move_to[2]] = temp_landing_square
	end

	return num_positions
end

function _co(depth, piece_array, last_moved)
	if depth == 0 then
		return 1 
	end

	local moves = generate_moves(piece_array)
	local num_positions = 0
	local captures = 0
	local castles = 0
	local move_from, move_to, flag

	for _, move_data in ipairs(moves) do
		move_from = move_data[1]
		move_to = move_data[2]
		flag = move_data[3]

		local piece = utils.deepcopy(piece_array[move_from[1]][move_from[2]])

		-- Make move
		piece:move(move_to, flag, piece_array, last_moved)

		if flag == "capture" then
			print("CAPTURE")
			captures = captures + 1
		elseif flag == "castle_kingside" or flag == "castle_queenside" then
			castles = castles + 1
		end

		-- Eval
		coroutine.yield(num_positions)
		num_positions = num_positions + _co(depth - 1, piece_array)
		-- coroutine.yield(num_positions)

		-- Unmake
		piece:undo_last_move(flag, piece_array)
	end

	-- coroutine.yield(num_positions)
	print("CAPTURES:", captures, "CASTLES:", castles)
	return num_positions
end

ai.co = coroutine.create(_co)

ai.move_gen_test = move_gen_test

ai.search = search

-- Return: array of moves
-- Generate valid moves for each side (white and black) alternatingly
function generate_moves(piece_array)
	local moves = {}
	local current_colour = "w"

	-- get the current team's colour
	if _turn_counter % 2 == 1 then
		current_colour = "b"
	end
	_turn_counter = _turn_counter + 1

	-- Generate the moves for that colour
	local piece
	for x = 1, 8 do
		for y = 1, 8 do
			piece = piece_array[x][y]
			if piece ~= nil and piece.colour == current_colour then
				-- for every valid move of this piece, add it to the moves table
				for _, move_and_flag in ipairs(piece:get_valid_moves(piece_array)) do
					table.insert(moves, { {x, y}, move_and_flag[1], move_and_flag[2] })
				end
			end
		end
	end
		
	print("MOVES GENERATED")
	return moves
end


return ai
