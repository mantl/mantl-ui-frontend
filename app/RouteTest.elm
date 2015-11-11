module RouteTest where

import Effects
import ElmTest.Assertion exposing (assertEqual)
import ElmTest.Test exposing (test, Test, suite)

import Route exposing (..)

routes : List (Location, String)
routes = [ (Home, "#/") ]

-- urlFor
urlForTest : (Location, String) -> Test
urlForTest (loc, path) =
  test (toString loc) (assertEqual (urlFor loc) path)

urlForTests : Test
urlForTests =
  suite "urlFor"
        (List.map urlForTest routes)

-- locFor
locForTest : (Location, String) -> Test
locForTest (loc, path) =
  test (toString loc) (assertEqual (locFor path) (Just loc))

locForTests : Test
locForTests =
  suite "locFor"
        ([ test "Nothing" (assertEqual (locFor "/bad/url") Nothing)
         , test "with hash" (assertEqual (locFor "#/") (Just Home)) ]
        ++ (List.map locForTest routes))

-- update
updateTests : Test
updateTests =
  suite "update"
        [ suite "PathChange"
                [ test "good path" (assertEqual
                                    (update (PathChange "/") Nothing)
                                    (Just Home, Effects.none)) ] ]

-- tests
tests : Test
tests =
  suite "routes" [ urlForTests, locForTests, updateTests ]
