#!/usr/bin/env lua

package.path = package.path .. ";../?.lua"
argparser = require "argparse"
cjson = require "cjson"
country_parse = require "countries"
socket = require "socket"
curl = require "cURL"

_Lu = require "luaunit"
_Speed = require "speed_test_module"

-- loadfile("../countries_json")

TestFindBestServer = require("modules.find_best_server_test_suite")
TestDownload = require("modules.download_speed_test_suite")
TestFindGeoLocation = require("modules.find_geo_location_test_suite")
TestDownloadServerListJson = require("modules.server_list_download_test_suite")
TestReadServerListJson = require("modules.server_list_read_test_suite")
TestUpload = require("modules.upload_speed_test_suite")

os.exit(_Lu.LuaUnit.run())
