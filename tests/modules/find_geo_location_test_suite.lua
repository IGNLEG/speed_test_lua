TestFindGeoLocation = {}
local MyEasy = {}
function TestFindGeoLocation:setUp()
    self.old_easy = curl.easy
    local old_easy = curl.easy

    self.old_cjson_decode = cjson.decode
    cjson.decode = function() return {lmao = "ayyy"} end

    function MyEasy:perform() return nil end -- any return value here, except for errors if you dont want to throw one
    function MyEasy:getinfo(...) return 0 end -- return any number here
    function MyEasy:close() return old_easy():close() end
    MyEasy.__index = curl.Easy
    curl.easy = function(...) return MyEasy end
end

function TestFindGeoLocation:TestFindGeoLocationReturnsTable()
    _Lu.assertIsTable(_Speed.geo_location())
end
function TestFindGeoLocation:TestFindGeoLocationReturnsCountry()
    cjson.decode = function() return {country = "some country"} end
    _Lu.assertIsString(_Speed.geo_location()["country"])
end
function TestFindGeoLocation:TestFindGeoLocationCurlErr()
    function MyEasy:perform() return error("some easy error", 0) end
    _Lu.assertErrorMsgContains("some easy error", _Speed.geo_location)
end
function TestFindGeoLocation:TestFindGeoLocationCjsonErr()
    cjson.decode = function (...) return error("some cjson error") end
    _Lu.assertErrorMsgContains("some cjson error", _Speed.geo_location)

 end
function TestFindGeoLocation:tearDown()
    curl.easy = self.old_easy
    cjson.decode = self.old_cjson_decode
end

return TestFindGeoLocation
