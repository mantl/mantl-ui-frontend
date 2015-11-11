module ServicesTest where

import Effects
import ElmTest.Assertion exposing (assertEqual)
import ElmTest.Test exposing (test, Test, suite)

import Services exposing (..)

updateTests : Test
updateTests =
  suite "update"
        [ suite "NewServices"
                [ test "services are set"
                       (let
                         services   = Just [ Service "test" "/test" ]
                         action     = NewServices services
                       in
                         assertEqual
                           (update action Nothing)
                           (services, Effects.none)) ]
        , suite "LoadServices"
                [ test "services are blanked out and action is returned"
                       (assertEqual
                          (update LoadServices (Just []))
                          ((Just []), loadServices))] ]

-- tests
tests : Test
tests =
  suite "services" [ updateTests ]
