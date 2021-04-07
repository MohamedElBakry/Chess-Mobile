-- Put functions in this file to use them in several other scripts.
-- To get access to the functions, you need to put:
-- require "my_directory.my_file"
-- in any script using the functions.

-- Translate the coordinates to array coordinates as their origins are mismatched
local arr_coords = {8, 7, 6, 5, 4, 3, 2, 1}

-- Set up a namespace
utils = utils or {}

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
	local y = arr_coords[math.floor(px[2] / height) + 1]
	print(y, x)
	return vmath.vector({y, x})
end