module Health exposing (..)

import Attributes exposing (classes)
import Debug
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (class, classList, href)
import Html.Events exposing (onClick)
import Http
import Json.Decode exposing (Decoder, list, object8, string, (:=), customDecoder)
import List exposing ((::))
import Maybe
import Result
import Route
import Task
import Task.Extra


-- MODEL


type alias Check =
    { node : String
    , checkID : String
    , name : String
    , status : Status
    , notes : String
    , output : String
    , serviceID : String
    , serviceName : String
    }


type Status
    = Passing
    | Unknown
    | Warning
    | Critical
    | Other String


type alias Checks =
    List Check


type alias Model =
    { status : Status
    , checks : Checks
    , error : Maybe String
    }


init : ( Model, Cmd Msg )
init =
    { status = Unknown
    , checks = []
    , error = Nothing
    }
        ! [ loadHealth ]



-- UPDATE


type Msg
    = NewChecks (Maybe Checks)
    | LoadChecks


update : Msg -> Model -> ( Model, Cmd Msg )
update action model =
    case action of
        NewChecks Nothing ->
            { model | error = Just "Could not retrieve health checks" } ! []

        NewChecks (Just checks) ->
            { model
                | checks = checks
                , status = worstStatus checks
                , error = Nothing
            }
                ! []

        LoadChecks ->
            ( model, loadHealth )



-- ACTIONS


loadHealth : Cmd Msg
loadHealth =
    Http.get (list healthCheckDecoder) "/consul/v1/health/state/any"
        |> Task.toMaybe
        |> Task.Extra.performFailproof NewChecks


healthCheckDecoder : Decoder Check
healthCheckDecoder =
    object8 Check
        ("Node" := string)
        ("CheckID" := string)
        ("Name" := string)
        ("Status" := statusDecoder)
        ("Notes" := string)
        ("Output" := string)
        ("ServiceID" := string)
        ("ServiceName" := string)


statusDecoder : Decoder Status
statusDecoder =
    customDecoder string
        <| \status ->
            case status of
                "passing" ->
                    Result.Ok Passing

                "unknown" ->
                    Result.Ok Unknown

                "warning" ->
                    Result.Ok Warning

                "critical" ->
                    Result.Ok Critical

                _ ->
                    Result.Ok (Other status)



-- VIEW


statusToClass : Status -> String
statusToClass status =
    case status of
        Passing ->
            "passing"

        Unknown ->
            "unknown"

        Warning ->
            "warning"

        Critical ->
            "critical"

        Other _ ->
            "other"


statusToString : Status -> String
statusToString status =
    case status of
        Other o ->
            "Unknown Status: " ++ o

        _ ->
            toString status


healthDot : Status -> String -> Html a
healthDot status size =
    span [ classes [ "healthdot", size, statusToClass status ] ]
        [ status |> statusToString |> text ]


attributes : List ( String, String ) -> Html Msg
attributes attrs =
    dl [ class "attributes" ]
        (attrs
            |> List.map
                (\( key, value ) ->
                    div [ class "attribute" ]
                        [ dt [] [ text key ]
                        , dd [] [ code [] [ text value ] ]
                        ]
                )
        )


checkSelector : String -> Checks -> Bool -> Html Msg
checkSelector name checks active =
    a
        [ classList
            [ ( "service", True )
            , ( "card", True )
            , ( "card-block", True )
            , ( worstStatus checks |> statusToClass, True )
            , ( "active", active )
            ]
        , href (Route.urlFor (Route.HealthCheck name))
        ]
        [ text name ]


checkDetail : Check -> Html Msg
checkDetail check =
    div [ classes [ "check", "card", "card-block", statusToClass check.status ] ]
        [ h2 [] [ text check.name ]
        , attributes
            [ ( "Status", check.status |> statusToString )
            , ( "Check ID", check.checkID )
            , ( "Node", check.node )
            , ( "Service ID", check.serviceID )
            , ( "Service Name", check.serviceName )
            ]
        , p
            [ classList
                [ ( "notes", True )
                , ( "hidden", not (hasNotes check |> Debug.log "has notes") )
                ]
            ]
            [ strong [] [ text "Notes: " ], text check.notes ]
        , p [] [ strong [] [ text "Output:" ] ]
        , pre [ class "output" ] [ code [] [ text check.output ] ]
        ]


view : Model -> Maybe String -> Html Msg
view model focus =
    let
        content =
            if List.isEmpty model.checks then
                p [ class "col-sm-12" ] [ text "No Health Checks loaded" ]
            else
                let
                    groups =
                        model.checks |> displayGrouping

                    focusedGroup =
                        case focus of
                            Nothing ->
                                Nothing

                            Just name ->
                                Dict.get name groups

                    focusContent =
                        case ( focus, focusedGroup ) of
                            ( Nothing, _ ) ->
                                div [] []

                            ( Just name, Nothing ) ->
                                div []
                                    [ h1 [] [ text ("No health checks found for " ++ name) ] ]

                            ( Just name, Just checks ) ->
                                div []
                                    [ h1 []
                                        [ healthDot (worstStatus checks) "large"
                                        , text name
                                        ]
                                    , div [ class "checks" ]
                                        (List.map checkDetail checks)
                                    ]
                in
                    div [ class "col-sm-12" ]
                        [ div [ classes [ "row", "controls" ] ]
                            [ div [ class "col-sm-12" ]
                                [ button
                                    [ classes [ "btn", "btn-sm", "btn-secondary" ]
                                    , onClick LoadChecks
                                    ]
                                    [ text "Reload Health Checks" ]
                                ]
                            ]
                        , div [ classes [ "row", "healthchecks" ] ]
                            [ div [ classes [ "services", "col-md-3" ] ]
                                (groups
                                    |> Dict.toList
                                    |> List.map
                                        (\( name, checks ) ->
                                            checkSelector name
                                                checks
                                                (isFocused name focus)
                                        )
                                )
                            , div [ class "col-md-9" ] [ focusContent ]
                            ]
                        ]
    in
        div [ class "row" ]
            [ content ]



-- UTILITIES


addCheck : Check -> Maybe Checks -> Maybe Checks
addCheck check val =
    case val of
        Nothing ->
            Just [ check ]

        Just checks ->
            Just (check :: checks)


updateCheckDict : (Check -> String) -> Check -> Dict String Checks -> Dict String Checks
updateCheckDict selector check checks =
    Dict.update (selector check) (addCheck check) checks


groupBy : (Check -> String) -> Checks -> Dict String Checks
groupBy selector checks =
    List.foldl (updateCheckDict selector) Dict.empty checks


displayGrouping : Checks -> Dict String Checks
displayGrouping checks =
    checks
        |> groupBy .serviceName
        |> Dict.toList
        |> List.map
            (\( k, v ) ->
                if k == "" then
                    ( "consul", v )
                else
                    ( k, v )
            )
        |> Dict.fromList


hasNotes : Check -> Bool
hasNotes check =
    check.notes /= ""


isFocused : String -> Maybe String -> Bool
isFocused name focus =
    case focus of
        Nothing ->
            False

        Just other ->
            name == other


worstStatus : Checks -> Status
worstStatus checks =
    checks
        |> List.map .status
        |> List.sortBy
            (\s ->
                case s of
                    Critical ->
                        0

                    Warning ->
                        1

                    Unknown ->
                        2

                    Passing ->
                        3

                    Other _ ->
                        4
            )
        |> List.head
        |> Maybe.withDefault Unknown


statusForService : String -> Model -> Status
statusForService name =
    .checks >> displayGrouping >> Dict.get name >> Maybe.withDefault [] >> worstStatus
