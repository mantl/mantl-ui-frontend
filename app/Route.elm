module Route where

import Html exposing (..)
import Html.Attributes exposing (class)
import Effects exposing (Effects)
import String exposing (split)

-- MODEL

type Location = Home

type alias Model = Maybe Location

init : Model
init = Nothing

-- UPDATE

-- UTIL

urlFor : Location -> String
urlFor loc =
  case loc of
    Home -> "/"

locFor : String -> Maybe Location
locFor path =
  let
    segments =
      path
        |> split "/"
        |> List.filter (\seg -> seg /= "" && seg /= "#")
  in
    case segments of
      [] -> Just Home
      _  -> Nothing

-- VIEW

notfound : Html
notfound =
  div [ class "row" ]
      [ p [ class "col-sm-12" ]
          [ text "Not found!" ] ]
