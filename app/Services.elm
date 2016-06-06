module Services exposing (..)

import Attributes exposing (classes)
import Health
import Html exposing (..)
import Html.Attributes exposing (href, class)
import Html.Events exposing (onClick)
import Http
import Json.Decode exposing ((:=), Decoder, object4, string, list)
import Route
import Task
import Task.Extra


-- MODEL


type alias Service =
    { name : String
    , id : String
    , check : String
    , path : String
    }


type alias Services =
    List Service


type alias Model =
    Maybe Services


init : ( Model, Cmd Msg )
init =
    ( Nothing, loadServices )



-- UPDATE


type Msg
    = LoadServices
    | NewServices Model


update : Msg -> Model -> ( Model, Cmd Msg )
update action model =
    case action of
        NewServices services ->
            services ! []

        LoadServices ->
            ( model, loadServices )



-- ACTIONS


loadServices : Cmd Msg
loadServices =
    Http.get (list serviceDecoder) "/_internal/services.json"
        |> Task.toMaybe
        |> Task.Extra.performFailproof NewServices


serviceDecoder : Decoder Service
serviceDecoder =
    object4 Service
        ("name" := string)
        ("id" := string)
        ("check" := string)
        ("path" := string)



-- VIEW


serviceView : Health.Status -> Service -> Html Msg
serviceView health service =
    div [ classes [ "col-sm-3", "service" ] ]
        [ div [ classes [ "card", "card-block" ] ]
            [ div [ class "logo" ] [ div [ class service.id ] [] ]
            , h4 [ class "card-title" ] [ text service.name ]
            , a
                [ classes [ "btn", "btn-block", "btn-primary" ]
                , href service.path
                ]
                [ text "Web UI" ]
            , a
                [ classes [ "btn", "btn-block", "btn-health", Health.statusToClass health ]
                , href (Route.urlFor (Route.HealthCheck service.check))
                ]
                [ text ("Checks: " ++ (Health.statusToString health)) ]
            ]
        ]


view : Model -> Health.Model -> Html Msg
view model health =
    let
        content =
            case model of
                Nothing ->
                    p [ class "col-sm-12" ] [ text "No services loaded" ]

                Just services ->
                    div [ class "col-sm-12" ]
                        [ div [ classes [ "row", "controls" ] ]
                            [ div [ class "col-sm-12" ]
                                [ button
                                    [ classes [ "btn", "btn-sm", "btn-secondary" ]
                                    , onClick LoadServices
                                    ]
                                    [ text "Reload Services" ]
                                ]
                            ]
                        , div [ classes [ "row", "services" ] ]
                            (services
                                |> List.map
                                    (\s ->
                                        serviceView (Health.statusForService s.check health)
                                            s
                                    )
                            )
                        ]
    in
        div [ class "row" ]
            [ content ]
