module Test where

import Graphics.Element exposing (Element)

import ElmTest.Test exposing (test, Test, suite)
import ElmTest.Assertion exposing (assert, assertEqual)
import ElmTest.Runner.Element exposing (runDisplay)

import RouteTest

tests : Test
tests =
  suite "A Test Suite"
        [ RouteTest.tests ]

main : Element
main =
  runDisplay tests
