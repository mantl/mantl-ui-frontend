module Test exposing (..)

import ElmTest exposing (test, Test, suite, runSuiteHtml)
import HealthTest
import RouteTest
import ServicesTest
import VersionTest


tests : Test
tests =
    suite "A Test Suite"
        [ HealthTest.tests
        , RouteTest.tests
        , ServicesTest.tests
        , VersionTest.tests
        ]


main : Program Never
main =
    runSuiteHtml tests
