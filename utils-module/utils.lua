-- Put functions in this file to use them in several other scripts.
-- To get access to the functions, you need to put:
-- require "my_directory.my_file"
-- in any script using the functions.

-- Set up a namespace
utils = utils or {}

function utils.test()
	print("Namespace success!!!!!!!!!!!!!!!!!")
end

-- Translate pixel coordinates to square x, y coordinates
-- e.g. 800, 400
window_width, window_height = window.get_size()
-- width = (window_width / 8) 	
height = window_height / 8
width = height
print(width, height, xoffset, yoffset)
x_offset = 1
print("WINDOW SIZE:::::::::::::", window_width, window_height)

function utils_px_to_xy(px)
	local x = math.floor(px[1] / width)
	local y = math.floor(px[2] / height)
	print(x, y)
	return vmath.vector({x, y})
end