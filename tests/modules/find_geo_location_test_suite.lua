TestFindGeoLocation = {}
        function TestFindGeoLocation:TestFindGeoLocationReturnsTable()
                lu.assertIsTable(speed.geo_location())
        end
        function TestFindGeoLocation:TestFindGeoLocationReturnsCountry()
                lu.assertIsString(speed.geo_location()["country"])
        end
return TestFindBestServer