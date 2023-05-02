#!/usr/bin/lua
local test = require "speed_test_module"
argparser = require "argparse"
cjson = require "cjson"
country_parse = require "countries"
socket = require "socket"
curl = require "cURL"

local dtraceback = debug.traceback
function debug.traceback(...) local err, _ = ... print(err)end

local parser = argparser("speed_test.lua", "Download and upload speed testing with given server script.")

parser:option("-d --download", "Measures download speed with your specified server. Must be a valid speedtest server address."):args(1)
parser:option("-u --upload", "Measures upload speed with your specified server. Must be a valid speedtest server address."):args(1)
parser:option("-s --servers", "Downloads servers list file in json format."):args(0)
parser:option("-b --best", "Finds the best server in specified country by ping."):args(1)
parser:option("-l --location", "Displays your servers' information, including your location"):args(0)
parser:option("-a --auto", "Performs all tests automatically."):args(0)


local args = parser:parse()

if(args.download) then download_speed_mbps = test.download_speed(args.download) if download_speed_mbps then print(cjson.encode({download_speed_mbps = download_speed_mbps})) end
elseif(args.upload) then upload_speed_mbps = test.upload_speed(args.upload) if upload_speed_mbps then print(cjson.encode({upload_speed_mbps = upload_speed_mbps})) end
elseif(args.servers) then test.download_server_list_json("servers_list_json")
elseif(args.best) then if test.download_server_list_json("servers_list_json") then best_server, ping = test.find_best_server(test.read_server_list_json(), args.best) print(cjson.encode({best_server = best_server, ping = ping})) end
elseif(args.location) then location = test.geo_location() if location then print(cjson.encode({location = location["country"]})) end
elseif(args.auto) then
	local location = test.geo_location()
	test.download_server_list_json("servers_list_json")
	if location then server, ping = test.find_best_server(test.read_server_list_json(), location["country"])	
		if server then dl_speed = test.download_speed(server) up_speed = test.upload_speed(server) end
		local results = { location = location["country"], best_server = server, ping_s = ping, download_speed_mbps = dl_speed, upload_speed_mbps = up_speed }
		print(cjson.encode(results))
	end
else print("speed_test.lua: try 'lua speed_test.lua -h' for more information.")
end

debug.traceback = dtraceback
