TestReadServerListJson = {}
function TestReadServerListJson:setUp()
    self.old_print = print
    self.old_open = io.open
    self.old_cjson_decode = cjson.decode
    --function print(...) end

end
function TestReadServerListJson:TestServerListReadOpenFile_err()
    function io.open(...) return false end
    _Lu.assertErrorMsgContains("while opening", _Speed.read_server_list_json, "servers_list.json")
    io.open = self.old_open

end
function TestReadServerListJson:TestServerListReadFileReadErr()
    function io.open(...) return "bad value type" end
    _Lu.assertErrorMsgContains("while reading", _Speed.read_server_list_json, "servers_list.json")
    io.open = self.old_open

end
function TestReadServerListJson:TestServerListReadDecodeDataSuccess()
    local f = io.open("servers_list.json", "w")
    f:write("[{\"some\": \"data\"}]")
    f:close()
    _Lu.assertEvalToTrue(_Speed.read_server_list_json("servers_list.json"))
end
function TestReadServerListJson:TestServerListReadDecodeDataErr()
    local f = io.open("servers_list.json", "w")
    f:write("[{some: \"data\"}]")
    f:close()
    cjson.decode = function(...) return error("error", 0) end
    _Lu.assertErrorMsgContains("while parsing", _Speed.read_server_list_json, "servers_list.json")
end
function TestReadServerListJson:tearDown()
    print = self.old_print
    io.open = self.old_open
    cjson.decode = self.old_cjson_decode
    os.remove("servers_list.json")

end
return TestReadServerListJson
