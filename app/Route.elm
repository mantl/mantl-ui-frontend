module Route exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, classList, href)
import String exposing (split)
import Navigation

-- MODEL

type Location
  = Home
  | HealthOverview
  | HealthCheck String

type alias Model = Maybe Location

init : Maybe Location -> (Model, Cmd Msg)
init location =
  location ! [ ]

-- UPDATE

type Msg = PathChange String

update : Msg -> Model -> (Model, Cmd Msg)
update action model =
  case action of
    PathChange path ->
      model ! [ ]

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

locFor : Navigation.Location -> Maybe Location
locFor path =
  let
    segments =
      path.hash
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

notfound : Html Msg
notfound =
  div [ class "row" ]
      [ p [ class "col-sm-12" ]
          [ text "Not found!" ] ]

navItem : Model -> Location -> String -> Html Msg
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
