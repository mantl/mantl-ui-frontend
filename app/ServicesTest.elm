module ServicesTest exposing (..)

import ElmTest exposing (test, Test, suite, assertEqual)
import Services exposing (..)


updateTests : Test
updateTests =
    suite "update"
        [ suite "NewServices"
            [ test "services are set"
                (let
                    services =
                        Just [ Service "test" "/test" "test" "test" ]

                    msg =
                        NewServices services
                 in
                    assertEqual (update msg Nothing)
                        (services ! [])
                )
            ]
        , suite "LoadServices"
            [ test "services are blanked out and action is returned"
                (assertEqual (update LoadServices (Just []))
                    ( (Just []), loadServices )
                )
            ]
        ]



-- tests


tests : Test
tests =
    suite "services" [ updateTests ]
