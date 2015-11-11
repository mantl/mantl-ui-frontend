module Mantl where

import Attributes exposing (classes)
import Effects exposing (Effects)
import Html exposing (..)
import Html.Attributes exposing (class)
import Route
import Services
import Version

-- MODEL

type alias Model = { route : Route.Model
                   , services : Services.Model
                   , version : Version.Model }

init : ( Model, Effects Action )
init =
  let
    route = Route.init
    (services, sfx) = Services.init
    (version, vfx) = Version.init
  in
    ( { route = route
      , services = services
      , version = version }
    , Effects.batch [ Effects.map ServicesAction sfx
                    , Effects.map VersionAction vfx ] )

-- UPDATE

type Action
  = Refresh
  | RouteAction Route.Action
  | ServicesAction Services.Action
  | VersionAction Version.Action

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    Refresh ->
      ( model
      , Effects.map VersionAction Version.getVersion )

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

    VersionAction sub ->
      let
        (version, fx) = Version.update sub model.version
      in
        ( { model | version <- version }
        , Effects.map VersionAction fx )

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
        [ Version.notification (Signal.forwardTo address VersionAction) model.version
        , Route.view (Signal.forwardTo address RouteAction) model.route
        , div [ classes [ "container", "content" ] ]
              [ body
              , Version.view (Signal.forwardTo address VersionAction) model.version ] ]
