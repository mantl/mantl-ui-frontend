module Version exposing (..)

import Attributes exposing (classes)
import Effects exposing (Effects)
import Html exposing (..)
import Html.Attributes exposing (class)
import Http
import Signal
import Task

-- MODEL

type alias Model = { current : Maybe String
                   , hasUpdate : Bool }

init : (Model, Effects Action)
init =
  ( { current = Nothing
    , hasUpdate = False }
  , loadVersion )

-- UPDATE

type Action = NewVersion (Maybe String)

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    NewVersion Nothing ->
      ( model, Effects.none )

    NewVersion (Just new) ->
      case model.current of
        -- we should accept an update without triggering an update notification
        -- on initial load (AKA Nothing)
        Nothing ->
          ( { model | current = Just new }, Effects.none )

        -- ... and if we get a new version after the initial value is set, we
        -- should trigger the update notification
        Just old ->
          if old == new
          then ( model, Effects.none )
          else ( { model | current = Just new
                         , hasUpdate = True }
               , Effects.none)

-- ACTIONS

loadVersion : Effects Action
loadVersion =
  Http.getString "signature"
      |> Task.toMaybe
      |> Task.map NewVersion
      |> Effects.task

-- VIEW

notification : Signal.Address Action -> Model -> Html
notification address model =
  if model.hasUpdate
  then div [ classes [ "navbar", "navbar-attention" ] ]
           [ div [ class "container" ]
                 [ p [ class "nav-item" ] [ text "New version available. Please reload!" ] ] ]
  else div [] []

version : Signal.Address Action -> Model -> Html
version address model =
  div [ class "version" ]
      [ Maybe.withDefault "No Version" model.current |> text ]

view = version
