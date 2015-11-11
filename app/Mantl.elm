module Mantl where

import Effects exposing (Effects)
import Html exposing (..)
import Html.Attributes exposing (class)
import Route
import Services

-- MODEL

type alias Model = { route : Route.Model
                   , services : Services.Model }

init : ( Model, Effects Action )
init =
  let
    route = Route.init
    (services, sfx) = Services.init
  in
    ( { route = route
      , services = services}
    , Effects.batch [ Effects.map ServicesAction sfx ] )

-- UPDATE

type Action
  = RouteAction Route.Action
  | ServicesAction Services.Action

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    ServicesAction sub ->
      let
        (services, fx) = Services.update sub model.services
      in
        ( { model | services <- services }
        , Effects.map ServicesAction fx )

    RouteAction sub ->
      let
        (route, fx) = Route.update sub model.route
      in
        ( { model | route <- route }
        , Effects.map RouteAction fx )

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
  let
    body =
      case model.route of
        Just (Route.Home) ->
          Services.view (Signal.forwardTo address ServicesAction) model.services
        Nothing -> Route.notfound
  in
    div [ class "app" ]
        [ Route.view (Signal.forwardTo address RouteAction) model.route
        , div [ class "container" ]
              [ body ] ]
