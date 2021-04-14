-- Constants
SQUARE_SIZE = 250

-- Set up a namespace
utils = utils or {}

-- Translate the coordinates to array coordinates as their origins are mismatched
utils.arr_coords = {8, 7, 6, 5, 4, 3, 2, 1}

-- Translate pixel coordinates to square x, y coordinates
-- e.g. 800, 400
window_width, window_height = window.get_size()
width = (window_width / 8) 	
height = window_height / 8
-- width = height
print(width, height, xoffset, yoffset)
print("WINDOW SIZE:::::::::::::", window_width, window_height)

function utils.px_to_xy(px)
	local x = math.floor(px[1] / width) + 1
	local y = utils.arr_coords[math.floor(px[2] / height) + 1]
	print(y, x)
	return vmath.vector({y, x})
end

-- Gives the 1D equivalent index of a 2D array index
-- E.g. (2, 1) --> 9; (2, 2) --> 10; ... (5, 7) --> 39
function utils.get_equivalent(x_index, y_index)
	return 8 * x_index - (8 - y_index)
end

-- print(utils.get_equivalent(2, 1), utils.get_equivalent(2, 2), utils.get_equivalent(5, 7))

-- Make a function to get the xy coordinates from the board coordinates (Reverse of utils.px_to_xy(px)) 
function utils.get_px_from(board_coord)
	return (board_coord - 0.5) * SQUARE_SIZE
end

-- print(utils.get_px_from(7))	