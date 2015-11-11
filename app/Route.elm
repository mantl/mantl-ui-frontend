module Route where

import Attributes exposing (classes)
import Effects exposing (Effects)
import Html exposing (..)
import Html.Attributes exposing (class, classList, href)
import String exposing (split)

-- MODEL

type Location = Home

type alias Model = Maybe Location

init : Model
init = Nothing

-- UPDATE

type Action = PathChange String

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    PathChange path ->
      ( (locFor path), Effects.none )

-- UTIL

urlFor : Location -> String
urlFor loc =
  let
    url =
      case loc of
        Home -> "/"
  in
    "#" ++ url

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

navItem : Model -> Location -> String -> Html
navItem model page caption =
  li [ classList [ ("nav-item", True)
                 , ("active", model == (Just page)) ] ]
     [ a [ class "nav-link"
         , href (urlFor page) ]
         [ text caption ] ]

view : Signal.Address Action -> Model -> Html
view address model =
  let
    link = navItem model
  in
    div [ classes [ "navbar", "navbar-inverted" ] ]
        [ div [ class "container" ]
              [ a [ class "navbar-brand"
                  , href (urlFor Home) ]
                  [ text "Mantl" ]
              , ul [ classes [ "nav", "navbar-nav" ] ]
                   [ link Home "Home" ] ] ]
