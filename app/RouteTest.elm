module RouteTest exposing (..)

import ElmTest exposing (test, Test, suite, assertEqual)
import Navigation
import Route exposing (..)


routes : List ( Location, String )
routes =
    [ ( Home, "#/" )
    , ( HealthOverview, "#/health/" )
    , ( HealthCheck "app", "#/health/app/" )
    ]


parents : List ( Location, Location )
parents =
    [ ( Home, Home )
    , ( HealthOverview, HealthOverview )
    , ( HealthCheck "app", HealthOverview )
    ]


locationWithHash : String -> Navigation.Location
locationWithHash hash =
    { hash = hash
    , hostname = ""
    , href = ""
    , origin = ""
    , password = ""
    , pathname = ""
    , port_ = ""
    , protocol = ""
    , search = ""
    , username = ""
    , host = ""
    }



-- urlFor


urlForTest : ( Location, String ) -> Test
urlForTest ( loc, path ) =
    test (toString loc) (assertEqual (urlFor loc) path)


urlForTests : Test
urlForTests =
    suite "urlFor"
        (List.map urlForTest routes)



-- locFor


locForTest : ( Location, String ) -> Test
locForTest ( loc, path ) =
    test (toString loc) (assertEqual (locFor <| locationWithHash path) (Just loc))


locForTests : Test
locForTests =
    suite "locFor"
        ([ test "Nothing" (assertEqual (locFor <| locationWithHash "/bad/url") Nothing)
         , test "with hash" (assertEqual (locFor <| locationWithHash "#/") (Just Home))
         ]
            ++ (List.map locForTest routes)
        )



-- parent


parentForTest : ( Location, Location ) -> Test
parentForTest ( child, parent ) =
    test (toString child) (assertEqual (parentFor child) parent)


parentForTests : Test
parentForTests =
    suite "parentFor"
        (List.map parentForTest parents)



-- tests


tests : Test
tests =
    suite "routes" [ urlForTests, locForTests, parentForTests ]
