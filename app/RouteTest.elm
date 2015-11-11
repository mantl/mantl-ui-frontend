module RouteTest where

import Route exposing (..)
import ElmTest.Test exposing (test, Test, suite)
import ElmTest.Assertion exposing (assertEqual)
import ElmTest.Runner.Element exposing (runDisplay)

routes : List (Location, String)
routes = [ (Home, "/") ]

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
        ([ test "Nothing" (assertEqual (locFor "/bad/url") Nothing) ]
        ++ (List.map locForTest routes))

-- tests
tests : Test
tests =
  suite "routes" [ urlForTests, locForTests ]
