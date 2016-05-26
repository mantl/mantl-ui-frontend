module VersionTest exposing (..)

import Effects
import ElmTest.Assertion exposing (assertEqual)
import ElmTest.Test exposing (test, Test, suite)

import Version exposing (..)

updateTests : Test
updateTests =
  suite "update"
        [ suite "NewVersion"
                [ test "nothing"
                       (let
                         (initial, _) = init
                         version = Nothing
                       in
                         assertEqual
                           (update (NewVersion version) initial)
                           ( initial, Effects.none ))
                , test "initial state"
                       (let
                         (initial, _) = init
                         version = "a"
                       in
                         assertEqual
                           (update (NewVersion (Just version)) initial)
                           ( { initial | current = Just version }, Effects.none) )
                , test "same version does not indicate change"
                       (let
                         (initial, _) = init
                         version = "a"
                         model = { initial | current = Just version }
                       in
                         assertEqual
                           (update (NewVersion (Just version)) model)
                           (model, Effects.none))
                , test "different version indicates change"
                       (let
                         (initial, _) = init
                         version = "a"
                         updated = "b"
                         model = { initial | current = Just version }
                         endState = { initial | current = Just updated
                                              , hasUpdate = True }
                       in
                         assertEqual
                           (update (NewVersion (Just updated)) model)
                           (endState, Effects.none)) ] ]

-- tests
tests : Test
tests =
  suite "version" [ updateTests ]
