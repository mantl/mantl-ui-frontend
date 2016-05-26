module Test exposing (..)

import Graphics.Element exposing (Element)

import ElmTest.Test exposing (test, Test, suite)
import ElmTest.Runner.Element exposing (runDisplay)

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
        , VersionTest.tests ]

main : Element
main =
  runDisplay tests
