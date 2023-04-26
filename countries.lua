local countries_module = {}
countries_module.table = {}
local cjson = require "cjson"

countries_module.list = function(cc)
	local countries_json = io.open("countries.json", "r")
	local parsed = cjson.decode(countries_json:read("*all"))
	for k, v in ipairs(parsed) do
		if string.lower(cc) == string.lower(v["Code"]) or string.lower(cc) == string.lower(v["Name"]) then
			return v["Code"], v["Name"]
		end
	end
	
end
return countries_module
