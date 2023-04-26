TestFindBestServer = {}
        function TestFindBestServer:setUp()
                speed.download_server_list_json()
                self.servers = speed.read_server_list_json()
                self.old_print = print
                function print(...) end
        end
        function TestFindBestServer:TestBestServeReturnsValue()
                lu.assertEvalToTrue(speed.find_best_server(self.servers, "LT"))
        end
        function TestFindBestServer:TestBestServerInvalidCountryErr()
                lu.assertErrorMsgContains("is not a valid", speed.find_best_server, self.servers, "ffs")
        end
        function TestFindBestServer:tearDown()
                print = self.old_print
        end    
        function TestFindBestServer:TestBestServerNoServerFound()
                lu.assertErrorMsgContains("Could not find servers", speed.find_best_server, self.servers, "MS")
        end 
return TestFindBestServer