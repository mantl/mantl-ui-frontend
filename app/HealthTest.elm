module HealthTest exposing (..)

import Dict exposing (Dict)
import ElmTest exposing (test, Test, suite, assert, assertEqual)
import Health exposing (..)


-- fixtures


( initial, _ ) =
    init
passing : Check
passing =
    Check "node" "check-passing" "name" Passing "notes" "output" "id" "passing-service"


unknown : Check
unknown =
    Check "node" "check-unknown" "name" Unknown "notes" "output" "id" "failing-service"


warning : Check
warning =
    Check "node" "check-warning" "name" Warning "notes" "output" "id" "failing-service"


critical : Check
critical =
    Check "node" "check-critical" "name" Critical "notes" "output" "id" "failing-service"


other : Check
other =
    Check "node" "check-other" "name" (Other "other") "notes" "output" "id" "failing-service"



-- tests


testSoloUnhealthy : Check -> Test
testSoloUnhealthy check =
    let
        checks =
            [ check ]

        ( updated, _ ) =
            update (NewChecks (Just checks)) initial
    in
        test ("health is worst of single " ++ (toString check.status)) (assertEqual updated.status check.status)


testMixedUnhealthy : Check -> Test
testMixedUnhealthy check =
    let
        checks =
            Just [ passing, check ]

        ( updated, _ ) =
            update (NewChecks checks) initial
    in
        test ("health is worst of mixed " ++ (toString check.status)) (assertEqual updated.status check.status)


unhealthyUpdateTests : List Test
unhealthyUpdateTests =
    let
        conditions =
            [ unknown, warning, critical ]
    in
        (List.map testSoloUnhealthy conditions) ++ (List.map testMixedUnhealthy conditions)


updateTests : Test
updateTests =
    suite "update"
        [ suite "NewChecks"
            ([ test "new health checks are set"
                (let
                    checks =
                        [ passing ]

                    ( updated, _ ) =
                        update (NewChecks (Just checks)) initial
                 in
                    assertEqual updated.checks checks
                )
             , test "healthy is false if all the checks are healthy"
                (let
                    checks =
                        [ passing ]

                    ( updated, _ ) =
                        update (NewChecks (Just checks)) initial
                 in
                    assertEqual updated.status passing.status
                )
             , test "a null value sets an error"
                (let
                    checks =
                        Nothing

                    ( updated, _ ) =
                        update (NewChecks checks) initial
                 in
                    assertEqual updated.error (Just "Could not retrieve health checks")
                )
             , test "a just value unsets an error"
                (let
                    errored =
                        { initial | error = Just "test" }

                    ( updated, _ ) =
                        update (NewChecks (Just [ passing ])) errored
                 in
                    assertEqual updated.error Nothing
                )
             ]
                ++ unhealthyUpdateTests
            )
        , suite "LoadChecks"
            [ test "new health checks are loaded"
                (let
                    ( _, fx ) =
                        update LoadChecks initial
                 in
                    assertEqual fx loadHealth
                )
            ]
        ]


addCheckTests : Test
addCheckTests =
    suite "addCheck"
        [ test "nothing"
            (assertEqual (addCheck passing Nothing)
                (Just [ passing ])
            )
        , test "something"
            (assertEqual (addCheck passing (Just [ passing ]))
                (Just [ passing, passing ])
            )
        , test "updates dict"
            (assertEqual (Dict.singleton "a" [ passing ] |> Dict.update "a" (addCheck passing))
                (Dict.singleton "a" [ passing, passing ])
            )
        ]


updateCheckDictTest : Test
updateCheckDictTest =
    test "updateCheckDict"
        (assertEqual (updateCheckDict .serviceName passing Dict.empty)
            (Dict.singleton (.serviceName passing) [ passing ])
        )


groupByTests : Test
groupByTests =
    suite "groupBy"
        [ test "no health checks"
            (assertEqual (groupBy .serviceName [])
                Dict.empty
            )
        , test "a single health check"
            (assertEqual (groupBy .serviceName [ passing ])
                (Dict.singleton (.serviceName passing) [ passing ])
            )
        , test "two same health checks"
            (assertEqual (groupBy .serviceName [ passing, passing ])
                (Dict.singleton (.serviceName passing) [ passing, passing ])
            )
        , test "two different health checks"
            (assertEqual (groupBy .serviceName [ passing, warning ])
                (Dict.empty
                    |> Dict.insert (.serviceName passing) [ passing ]
                    |> Dict.insert (.serviceName warning) [ warning ]
                )
            )
        ]


displayGroupingTest : Test
displayGroupingTest =
    suite "displayGrouping"
        [ test "is equivalent to `groupby .serviceName`"
            (assertEqual (groupBy .serviceName [ passing ])
                (displayGrouping [ passing ])
            )
        , test "sets consul name if key is blank"
            (let
                consul =
                    Check "node" "id" "name" Passing "notes" "output" "id" ""
             in
                assertEqual (displayGrouping [ consul ])
                    (Dict.fromList [ ( "consul", [ consul ] ) ])
            )
        ]


isFocusedTests : Test
isFocusedTests =
    suite "isFocused"
        [ test "focused"
            (assert (isFocused passing.name (Just passing.name)))
        , test "unfocused"
            (assert (not (isFocused passing.name (Just "not"))))
        , test "nothing"
            (assert (not (isFocused passing.name Nothing)))
        ]


trumps : Check -> Check -> Test
trumps trump other =
    test ((toString trump) ++ " trumps " ++ (toString other))
        (assertEqual (worstStatus [ other, trump, other ])
            trump.status
        )


worstStatusTests : Test
worstStatusTests =
    suite "worstStatus"
        [ suite "critical is worst of all"
            (List.map (trumps critical) [ warning, unknown, passing, other ])
        , suite "warning is worst of all but critical"
            (List.map (trumps warning) [ unknown, passing, other ])
        , suite "unknown is middle-of-the-road"
            (List.map (trumps unknown) [ passing, other ])
        , suite "passing is second to best"
            [ trumps passing other ]
        , suite "other doesn't beat anything"
            (List.map (\o -> trumps o other) [ critical, warning, unknown, passing ])
        , test "an empty list returns Unknown"
            (assertEqual (worstStatus []) Unknown)
        ]



-- tests


tests : Test
tests =
    suite "health"
        [ updateTests
        , addCheckTests
        , updateCheckDictTest
        , groupByTests
        , displayGroupingTest
        , isFocusedTests
        , worstStatusTests
        ]
