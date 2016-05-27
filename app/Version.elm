module Version exposing (..)

import Attributes exposing (classes)
import Html exposing (..)
import Html.Attributes exposing (class)
import Http
import Task
import Task.Extra


-- MODEL


type alias Model =
    { current : Maybe String
    , hasUpdate : Bool
    }


init : ( Model, Cmd Msg )
init =
    ( { current = Nothing
      , hasUpdate = False
      }
    , loadVersion
    )



-- UPDATE


type Msg
    = NewVersion (Maybe String)


update : Msg -> Model -> ( Model, Cmd Msg )
update action model =
    case action of
        NewVersion Nothing ->
            model ! []

        NewVersion (Just new) ->
            case model.current of
                -- we should accept an update without triggering an update notification
                -- on initial load (AKA Nothing)
                Nothing ->
                    { model | current = Just new } ! []

                -- ... and if we get a new version after the initial value is set, we
                -- should trigger the update notification
                Just old ->
                    if old == new then
                        model ! []
                    else
                        { model
                            | current = Just new
                            , hasUpdate = True
                        }
                            ! []



-- ACTIONS


loadVersion : Cmd Msg
loadVersion =
    Http.getString "signature"
        |> Task.toMaybe
        |> Task.Extra.performFailproof NewVersion



-- VIEW


notification : Model -> Html a
notification model =
    if model.hasUpdate then
        div [ classes [ "navbar", "navbar-attention" ] ]
            [ div [ class "container" ]
                [ p [ class "nav-item" ] [ text "New version available. Please reload!" ] ]
            ]
    else
        div [] []


version : Model -> Html Msg
version model =
    div [ class "version" ]
        [ Maybe.withDefault "No Version" model.current |> text ]


view =
    version
