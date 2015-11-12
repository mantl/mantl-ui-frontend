module Health where

import Effects exposing (Effects)
import Html exposing (..)
import Html.Attributes exposing (class)
import Http
import Json.Decode exposing (Decoder, list, object8, string, (:=))
import Task

-- MODEL

type alias HealthCheck = { node : String
                         , checkID : String
                         , name : String
                         , status : String
                         , notes : String
                         , output : String
                         , serviceID : String
                         , serviceName : String }

type alias HealthChecks = List HealthCheck

type alias Model = { healthy : Maybe Bool
                   , checks : Maybe HealthChecks
                   , error : Maybe String }

init : ( Model, Effects Action )
init =
  ( { healthy = Nothing
    , checks = Nothing
    , error = Nothing }
  , loadHealth )

-- UPDATE

type Action
  = NewHealthChecks (Maybe HealthChecks)
  | LoadHealthChecks

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    NewHealthChecks Nothing ->
      ( { model | error <- Just "Could not retrieve health checks" }, Effects.none )

    NewHealthChecks (Just checks) ->
      ( { model | checks <- Just checks
                , healthy <- Just (allHealthy checks)
                , error <- Nothing }
      , Effects.none)

    LoadHealthChecks ->
      ( model, loadHealth )

allHealthy : List HealthCheck -> Bool
allHealthy checks =
  checks |> List.all (\c -> c.status == "passing")

-- ACTIONS

loadHealth : Effects Action
loadHealth =
  Http.get (list healthCheckDecoder) "/consul/v1/health/state/any"
      |> Task.toMaybe
      |> Task.map NewHealthChecks
      |> Effects.task

healthCheckDecoder : Decoder HealthCheck
healthCheckDecoder = object8 HealthCheck
                             ("Node" := string)
                             ("CheckID" := string)
                             ("Name" := string)
                             ("Status" := string)
                             ("Notes" := string)
                             ("Output" := string)
                             ("ServiceID" := string)
                             ("ServiceName" := string)

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
  let
    content =
      case model.checks of
        Nothing ->
          p [ class "col-sm-12" ] [ text "No Health Checks loaded" ]

        Just checks ->
          div [ class "col-sm-12" ] [ checks |> toString |> text ]
  in
    div [ class "row" ]
        [ content ]
