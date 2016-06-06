module Mantl exposing (..)

import Attributes exposing (classes)
import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (class, href)
import Health
import Route
import Services
import Version


-- MODEL


type alias Model =
    { route : Route.Model
    , services : Services.Model
    , version : Version.Model
    , health : Health.Model
    }


init : Maybe Route.Location -> ( Model, Cmd Msg )
init location =
    let
        route =
            Route.init location

        ( services, scmd ) =
            Services.init

        ( health, hcmd ) =
            Health.init

        ( version, vcmd ) =
            Version.init
    in
        { route = route
        , services = services
        , health = health
        , version = version
        }
            ! [ Cmd.map ServicesMsg scmd
              , Cmd.map HealthMsg hcmd
              , Cmd.map VersionMsg vcmd
              ]



-- UPDATE


type Msg
    = Refresh
    | ServicesMsg Services.Msg
    | VersionMsg Version.Msg
    | HealthMsg Health.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update action model =
    case action of
        Refresh ->
            model
                ! [ Cmd.map VersionMsg Version.loadVersion
                  , Cmd.map HealthMsg Health.loadHealth
                  , Cmd.map ServicesMsg Services.loadServices
                  ]

        ServicesMsg sub ->
            let
                ( services, cmd ) =
                    Services.update sub model.services
            in
                { model | services = services } ! [ Cmd.map ServicesMsg cmd ]

        VersionMsg sub ->
            let
                ( version, cmd ) =
                    Version.update sub model.version
            in
                { model | version = version } ! [ Cmd.map VersionMsg cmd ]

        HealthMsg sub ->
            let
                ( health, cmd ) =
                    Health.update sub model.health
            in
                { model | health = health } ! [ Cmd.map HealthMsg cmd ]


updateRoute : Maybe Route.Location -> Model -> ( Model, Cmd Msg )
updateRoute route model =
    { model | route = route } ! []



-- VIEW


view : Model -> Html Msg
view model =
    let
        link =
            \page caption -> Route.navItem model.route page caption

        body =
            case model.route of
                Just (Route.Home) ->
                    App.map ServicesMsg <| Services.view model.services model.health

                Just (Route.HealthOverview) ->
                    App.map HealthMsg <| Health.view model.health Nothing

                Just (Route.HealthCheck app) ->
                    App.map HealthMsg <| Health.view model.health (Just app)

                Nothing ->
                    Route.notfound
    in
        div [ class "app" ]
            [ Version.notification model.version
            , div [ classes [ "navbar", "navbar-inverted" ] ]
                [ div [ class "container" ]
                    [ a
                        [ class "navbar-brand"
                        , href (Route.urlFor Route.Home)
                        ]
                        [ text "Mantl" ]
                    , ul [ classes [ "nav", "navbar-nav" ] ]
                        [ link Route.Home "Home"
                        , link Route.HealthOverview "Health"
                        ]
                    , div [ classes [ "nav", "navbar-nav", "pull-right" ] ]
                        [ a
                            [ classes [ "nav-item", "nav-link", "health", Health.statusToClass model.health.status ]
                            , href (Route.urlFor Route.HealthOverview)
                            ]
                            [ Health.healthDot model.health.status "small"
                            , model.health.status |> Health.statusToString |> text
                            ]
                        ]
                    ]
                ]
            , div [ classes [ "container", "content" ] ]
                [ body
                , App.map VersionMsg <| Version.view model.version
                ]
            ]
