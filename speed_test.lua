#!/usr/bin/lua
local test = require "speed_test_module"
local argparser = require "argparse"
local cjson = require "cjson"


local parser = argparser("speed_test.lua", "Download and upload speed testing with given server script.")

parser:option("-d --download", "Measures download speed with your specified server. Must be a valid speedtest server address."):args(1)
parser:option("-u --upload", "Measures upload speed with your specified server. Must be a valid speedtest server address."):args(1)
parser:option("-s --servers", "Downloads servers list file in json format."):args(0)
parser:option("-b --best", "Finds the best server in specified country by ping."):args(1)
parser:option("-l --location", "Displays your servers' information, including your location"):args(0)
parser:option("-a --auto", "Performs all tests automatically."):args(0)


local args = parser:parse()

if(args.download) then print(cjson.encode({download_speed_mbps = test.download_speed(args.download)}))
elseif(args.upload) then print(cjson.encode({upload_speed_mbps = test.upload_speed(args.upload)}))
elseif(args.servers) then test.download_server_list_json()
elseif(args.best) then test.download_server_list_json() best_server, ping = test.find_best_server(test.read_server_list_json(), args.best) print(cjson.encode({best_server = best_server, ping = ping})) 
elseif(args.location) then print(cjson.encode({location = test.geo_location()["country"]}))
elseif(args.auto) then
	local location = test.geo_location()["country"]
	test.download_server_list_json()

	if location then server, ping = test.find_best_server(test.read_server_list_json(), location) end
	
	if server then dl_speed = test.download_speed(server) up_speed = test.upload_speed(server) end
	local results = { location = location, best_server = server, ping = ping, download_speed = dl_speed, upload_speed = up_speed }
	print(cjson.encode(results))
end