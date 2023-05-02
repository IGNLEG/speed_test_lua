TestFindBestServer = {}
local MyEasy = {}

function TestFindBestServer:setUp()
    self.old_country_parse_list = country_parse.list
    self.old_print = print
    self.old_easy = curl.easy
    local old_easy = curl.easy
    self.old_cjson_decode = cjson.decode

    country_parse.list = function(...) return "some cc", "some country name" end
    cjson.decode = function() return {lmao = "ayyy"} end

    function MyEasy:perform() return nil end -- any return value here, except for errors
    function MyEasy:getinfo(...) return 0 end -- return any number here
    function MyEasy:close() return old_easy():close() end
    MyEasy.__index = curl.Easy
    curl.easy = function(...) return MyEasy end

    function print(...) end
end

function TestFindBestServer:TestBestServerReturnsValue()
    _Lu.assertEvalToTrue(_Speed.find_best_server({
        {host = "some server", country = "some cc"}
    }, "some cc"))
end
function TestFindBestServer:TestBestServerFilteringErrNoListing()
    _Lu.assertErrorMsgContains("find servers", _Speed.find_best_server,
                               {{host = "some server", country = "bad cc"}},
                               "some cc")
end
function TestFindBestServer:TestBestServerFilteringErrBadCountry()
    country_parse.list = function(...) return nil, nil end
    _Lu.assertErrorMsgContains("not a valid country code",
                               _Speed.find_best_server,
                               {{host = "some server", country = "some cc"}},
                               "bad cc")
end
function TestFindBestServer:TestBestServerFilteringErrBadServerList()
    _Lu.assertErrorMsgContains("bad argument", _Speed.find_best_server, "dada",
                               "bad cc")
end
function TestFindBestServer:TestBestServerNoServerFound()
    function MyEasy:getinfo(...) return 10000000000 end -- return any number here
    _Lu.assertErrorMsgContains("Couldn't find best server",
                               _Speed.find_best_server,
                               {{host = "some server", country = "some cc"}},
                               "some cc")
end

function TestFindBestServer:tearDown()
    country_parse.list = self.old_country_parse_list
    cjson.decode = self.old_cjson_decode
    curl.easy = self.old_easy
    print = self.old_print
end

return TestFindBestServer
