module HealthTest where

import Dict exposing (Dict)
import ElmTest.Assertion exposing (assertEqual)
import ElmTest.Test exposing (test, Test, suite)

import Health exposing (..)

-- fixtures
(initial, _) = init

passing : Check
passing = Check "node" "check-passing" "name" "passing" "notes" "output" "id" "passing-service"

unknown : Check
unknown = Check "node" "check-unknown" "name" "unknown" "notes" "output" "id" "failing-service"

warning : Check
warning = Check "node" "check-warning" "name" "warning" "notes" "output" "id" "failing-service"

critical : Check
critical = Check "node" "check-critical" "name" "critical" "notes" "output" "id" "failing-service"

-- tests
testSoloUnhealthy : Check -> Test
testSoloUnhealthy check =
  let
    checks = Just [ check ]
    (updated, _) = update (NewChecks checks) initial
  in
    test ("healthy is false if checks are all " ++ check.status) (assertEqual updated.healthy (Just False))

testMixedUnhealthy : Check -> Test
testMixedUnhealthy check =
  let
    checks = Just [ passing, check ]
    (updated, _) = update (NewChecks checks) initial
  in
    test ("healthy is false if checks are all " ++ check.status) (assertEqual updated.healthy (Just False))

unhealthyUpdateTests : List Test
unhealthyUpdateTests =
  let
    conditions = [ unknown, warning, critical ]
  in
    (List.map testSoloUnhealthy conditions) ++ (List.map testMixedUnhealthy conditions)

updateTests : Test
updateTests =
  suite "update"
        [ suite "NewChecks"
                ([ test "new health checks are set"
                        (let
                          checks = Just [ passing ]
                          (updated, _) = update (NewChecks checks) initial
                        in
                          assertEqual updated.checks checks)
                 , test "healthy is false if all the checks are healthy"
                        (let
                          checks = Just [ passing ]
                          (updated, _) = update (NewChecks checks) initial
                        in
                          assertEqual updated.healthy (Just True))
                 , test "a null value sets an error"
                        (let
                          checks = Nothing
                          (updated, _) = update (NewChecks checks) initial
                        in
                          assertEqual updated.error (Just "Could not retrieve health checks"))
                 , test "a just value unsets an error"
                        (let
                          errored = { initial | error <- Just "test" }
                          (updated, _) = update (NewChecks (Just [ passing ])) errored
                        in
                          assertEqual updated.error Nothing)
                 ] ++ unhealthyUpdateTests)
        , suite "LoadChecks"
          [ test "new health checks are loaded"
                 (let
                   (_, fx) = update LoadChecks initial
                 in
                   assertEqual fx loadHealth) ] ]

addCheckTests : Test
addCheckTests =
  suite "addCheck"
        [ test "nothing"
               (assertEqual
                  (addCheck passing Nothing)
                  (Just [ passing ]))
        , test "something"
               (assertEqual
                  (addCheck passing (Just [ passing ]))
                  ( Just [ passing, passing ]))
        , test "updates dict"
               (assertEqual
                (Dict.singleton "a" [ passing ] |> Dict.update "a" (addCheck passing))
                (Dict.singleton "a" [ passing, passing ])) ]

updateCheckDictTest : Test
updateCheckDictTest =
  test "updateCheckDict"
       (assertEqual
          (updateCheckDict .serviceName passing Dict.empty)
          (Dict.singleton (.serviceName passing) [ passing ]))

groupByTests : Test
groupByTests =
  suite "groupBy"
        [ test "no health checks"
               (assertEqual
                  (groupBy .serviceName [ ])
                  Dict.empty)
        , test "a single health check"
               (assertEqual
                  (groupBy .serviceName [ passing ])
                  (Dict.singleton (.serviceName passing) [ passing ]))
        , test "two same health checks"
               (assertEqual
                  (groupBy .serviceName [ passing, passing ])
                  (Dict.singleton (.serviceName passing) [ passing, passing ]))
        , test "two different health checks"
               (assertEqual
                  (groupBy .serviceName [ passing, warning ])
                  (Dict.empty
                    |> Dict.insert (.serviceName passing) [ passing ]
                    |> Dict.insert (.serviceName warning) [ warning ]))]

-- tests
tests : Test
tests =
  suite "health" [ updateTests
                 , addCheckTests
                 , updateCheckDictTest
                 , groupByTests ]
