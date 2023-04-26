TestReadServerListJson = {}
        function TestReadServerListJson:setUp()
                self.fname = "./servers_list.json"
        end
        function TestReadServerListJson:TestServerListReadOpenFile_err()
                self.old_open = io.open
                function io.open(...) return false end
                lu.assertErrorMsgContains("while opening", speed.read_server_list_json)
                io.open = self.old_open
        end
        function TestReadServerListJson:TestServerListReadDecodeDataSuccess()
                lu.assertEvalToTrue(speed.read_server_list_json())
        end
return TestReadServerListJson