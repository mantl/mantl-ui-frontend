module HealthTest where

import Effects
import ElmTest.Assertion exposing (assertEqual)
import ElmTest.Test exposing (test, Test, suite)

import Health exposing (..)

-- fixtures
(initial, _) = init

passing : HealthCheck
passing = HealthCheck "node" "check-passing" "name" "passing" "notes" "output" "id" "service-name"

unknown : HealthCheck
unknown = HealthCheck "node" "check-unknown" "name" "unknown" "notes" "output" "id" "service-name"

warning : HealthCheck
warning = HealthCheck "node" "check-warning" "name" "warning" "notes" "output" "id" "service-name"

critical : HealthCheck
critical = HealthCheck "node" "check-critical" "name" "critical" "notes" "output" "id" "service-name"

-- tests
testSoloUnhealthy : HealthCheck -> Test
testSoloUnhealthy check =
  let
    checks = Just [ check ]
    (updated, _) = update (NewHealthChecks checks) initial
  in
    test ("healthy is false if checks are all " ++ check.status) (assertEqual updated.healthy (Just False))

testMixedUnhealthy : HealthCheck -> Test
testMixedUnhealthy check =
  let
    checks = Just [ passing, check ]
    (updated, _) = update (NewHealthChecks checks) initial
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
        [ suite "NewHealthChecks"
                ([ test "new health checks are set"
                        (let
                          checks = Just [ passing ]
                          (updated, _) = update (NewHealthChecks checks) initial
                        in
                          assertEqual updated.checks checks)
                 , test "healthy is false if all the checks are healthy"
                        (let
                          checks = Just [ passing ]
                          (updated, _) = update (NewHealthChecks checks) initial
                        in
                          assertEqual updated.healthy (Just True))
                 , test "a null value sets an error"
                        (let
                          checks = Nothing
                          (updated, _) = update (NewHealthChecks checks) initial
                        in
                          assertEqual updated.error (Just "Could not retrieve health checks"))
                 , test "a just value unsets an error"
                        (let
                          errored = { initial | error <- Just "test" }
                          (updated, _) = update (NewHealthChecks (Just [ passing ])) errored
                        in
                          assertEqual updated.error Nothing)
                 ] ++ unhealthyUpdateTests)
        , suite "LoadHealthChecks"
          [ test "new health checks are loaded"
                 (let
                   (_, fx) = update LoadHealthChecks initial
                 in
                   assertEqual fx loadHealth) ] ]

-- updateTests : Test
-- updateTests =
--   suite "update"
--         [ suite "NewServices"
--                 [ test "services are set"
--                        (let
--                          services   = Just [ Service "test" "/test" ]
--                          action     = NewServices services
--                        in
--                          assertEqual
--                            (update action Nothing)
--                            (services, Effects.none)) ]
--         , suite "LoadServices"
--                 [ test "services are blanked out and action is returned"
--                        (assertEqual
--                           (update LoadServices (Just []))
--                           ((Just []), loadServices))] ]

-- tests
tests : Test
tests =
  suite "health" [ updateTests ]
