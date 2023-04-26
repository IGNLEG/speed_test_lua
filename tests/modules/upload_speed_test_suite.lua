TestUpload = {}
        function TestUpload:setUp()
                self.old_print = print
                function print(...) end
        end
        function TestUpload:TestUploadSpeedReturnsValue()
                lu.assertIsNumber(speed.upload_speed("speedtest.bacloud.com:8080"))
        end
        function TestUpload:TestUploadSpeedErr()
                lu.assertErrorMsgContains("404", speed.upload_speed, "speedtest.bacloud.com")
                lu.assertErrorMsgEquals("Bad url.", speed.upload_speed)
                lu.assertErrorMsgContains("resolve host name", speed.upload_speed, "aa")
        end
        function TestUpload:tearDown()
                print = self.old_print
        end
return TestUpload