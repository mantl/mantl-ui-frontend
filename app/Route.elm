module Route exposing (..)

import Attributes exposing (classes)
import Effects exposing (Effects)
-- import Health
import Html exposing (..)
import Html.Attributes exposing (class, classList, href)
import String exposing (split)

-- MODEL

type Location
  = Home
  | HealthOverview
  | HealthCheck String

type alias Model = Maybe Location

init : Model
init = Nothing

-- UPDATE

type Msg = PathChange String

update : Msg -> Model -> (Model, Effects Msg)
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
        Home            -> "/"
        HealthOverview  -> "/health/"
        HealthCheck app -> "/health/" ++ app ++ "/"
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
      []              -> Just Home
      ["health"]      -> Just HealthOverview
      ["health", app] -> Just (HealthCheck app)
      _               -> Nothing

parentFor : Location -> Location
parentFor child =
  case child of
    HealthCheck _ -> HealthOverview
    _             -> child

-- VIEW

notfound : Html
notfound =
  div [ class "row" ]
      [ p [ class "col-sm-12" ]
          [ text "Not found!" ] ]

navItem : Model -> Location -> String -> Html
navItem model page caption =
  let
    active =
      case model of
        Nothing      -> False
        Just current -> (parentFor current) == page
  in
    li [ classList [ ("nav-item", True)
                   , ("active", active) ] ]
       [ a [ class "nav-link"
           , href (urlFor page) ]
           [ text caption ] ]
