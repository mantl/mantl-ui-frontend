module Mantl where

import Effects exposing (Effects)
import Html exposing (..)
import Html.Events exposing (onClick)
import Route

-- MODEL

type alias Model = { route : Route.Model }

init : ( Model, Effects Action )
init =
  let
    route = Route.init
  in
    ( { route = route }
    , Effects.none )

-- UPDATE

type Action = RouteAction Route.Action

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    RouteAction sub ->
      let
        (route, fx) = Route.update sub model.route
      in
        ( { model | route <- route }
        , Effects.map RouteAction fx )

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
  p [ ]
    [ model |> toString |> text ]
