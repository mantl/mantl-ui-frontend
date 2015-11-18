module Mantl where

import Attributes exposing (classes)
import Effects exposing (Effects)
import Html exposing (..)
import Html.Attributes exposing (class, href)

import Health
import Route
import Services
import Version

-- MODEL

type alias Model = { route : Route.Model
                   , services : Services.Model
                   , version : Version.Model
                   , health : Health.Model }

init : ( Model, Effects Action )
init =
  let
    route = Route.init
    (services, sfx) = Services.init
    (version, vfx) = Version.init
    (health, hfx) = Health.init
  in
    ( { route = route
      , services = services
      , version = version
      , health = health }
    , Effects.batch [ Effects.map ServicesAction sfx
                    , Effects.map VersionAction vfx
                    , Effects.map HealthAction hfx ] )

-- UPDATE

type Action
  = Refresh
  | RouteAction Route.Action
  | ServicesAction Services.Action
  | VersionAction Version.Action
  | HealthAction Health.Action

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    Refresh ->
      ( model
      , Effects.batch [ Effects.map VersionAction Version.loadVersion
                      , Effects.map HealthAction Health.loadHealth ] )

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

    HealthAction sub ->
      let
        (health, fx) = Health.update sub model.health
      in
        ( { model | health <- health }
        , Effects.map HealthAction fx )

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
  let
    link = Route.navItem model.route
    body =
      case model.route of
        Just (Route.Home) ->
          Services.view (Signal.forwardTo address ServicesAction) model.services model.health

        Just (Route.HealthOverview) ->
          Health.view (Signal.forwardTo address HealthAction) model.health Nothing

        Just (Route.HealthCheck app) ->
          Health.view (Signal.forwardTo address HealthAction) model.health (Just app)

        Nothing -> Route.notfound
  in
    div [ class "app" ]
        [ Version.notification (Signal.forwardTo address VersionAction) model.version
        , div [ classes [ "navbar", "navbar-inverted" ] ]
              [ div [ class "container" ]
                    [ a [ class "navbar-brand"
                        , href (Route.urlFor Route.Home) ]
                        [ text "Mantl" ]
                    , ul [ classes [ "nav", "navbar-nav" ] ]
                         [ link Route.Home "Home"
                         , link Route.HealthOverview "Health" ]
                    , div [ classes [ "nav", "navbar-nav", "pull-right" ] ]
                          [ a [ classes [ "nav-item", "nav-link", "health", Health.statusToClass model.health.status ]
                                        , href (Route.urlFor Route.HealthOverview) ]
                              [ Health.healthDot model.health.status "small"
                              , model.health.status |> Health.statusToString |> text ] ] ] ]
        , div [ classes [ "container", "content" ] ]
              [ body
              , Version.view (Signal.forwardTo address VersionAction) model.version ] ]
