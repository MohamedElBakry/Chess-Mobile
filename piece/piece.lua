-- Put functions in this file to use them in several other scripts.
-- To get access to the functions, you need to put:
-- require "my_directory.my_file"
-- in any script using the functions.

-- [[ Pawn Class --]]

-- Meta Class
Piece = {name="", pos={}, hasMoved=false}

-- Dervied Class
function Piece:new(o, name, pos, hasMoved)
	
	o = o or {}
	setmetatable({}, self)
	
	self.__index = self
	self.name = name
	self.pos = pos
	self.hasMoved = hasMoved
	
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

-- p = Piece:new(nil, "pw", {6, 3}, false)
-- p:set_pos({6, 5})
-- print(p:get_pos())
-- 
-- p:set_pos({7, 6})
-- print(p:get_pos())
-- p:move({7, 7})
-- print(p.name, p.hasMoved)

-- Example Usage
-- pawn = Piece:new(nil, "pw", {6, 1})


