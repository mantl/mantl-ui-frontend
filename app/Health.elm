module Health where

import Attributes exposing (classes)
import Dict exposing (Dict)
import Effects exposing (Effects)
import Html exposing (..)
import Html.Attributes exposing (class)
import Http
import Json.Decode exposing (Decoder, list, object8, string, (:=))
import List exposing ((::))
import Task

-- MODEL

type alias Check = { node : String
                   , checkID : String
                   , name : String
                   , status : String
                   , notes : String
                   , output : String
                   , serviceID : String
                   , serviceName : String }

type alias Checks = List Check

type alias Model = { healthy : Maybe Bool
                   , checks : Checks
                   , error : Maybe String
                   , focus : Maybe (String, Maybe Checks) }

init : ( Model, Effects Action )
init =
  ( { healthy = Nothing
    , checks = [ ]
    , error = Nothing
    , focus = Nothing }
  , loadHealth )

-- UPDATE

type Action
  = NewChecks (Maybe Checks)
  | LoadChecks
  | Focus String

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    NewChecks Nothing ->
      ( { model | error <- Just "Could not retrieve health checks" }, Effects.none )

    NewChecks (Just checks) ->
      ( { model | checks <- checks
                , healthy <- Just (allHealthy checks)
                , error <- Nothing }
      , Effects.none)

    LoadChecks ->
      ( model, loadHealth )

    Focus name ->
      let
        groups = displayGrouping model.checks
        pair = Just (name, Dict.get name groups)
      in
        ( { model | focus <- pair }, Effects.none )

allHealthy : List Check -> Bool
allHealthy checks =
  checks |> List.all (\c -> c.status == "passing")

-- ACTIONS

loadHealth : Effects Action
loadHealth =
  Http.get (list healthCheckDecoder) "/consul/v1/health/state/any"
      |> Task.toMaybe
      |> Task.map NewChecks
      |> Effects.task

healthCheckDecoder : Decoder Check
healthCheckDecoder = object8 Check
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

-- UTILITIES

addCheck : Check -> Maybe Checks -> Maybe Checks
addCheck check val =
  case val of
    Nothing     -> Just [ check ]
    Just checks -> Just (check :: checks)

updateCheckDict : (Check -> String) -> Check -> Dict String Checks -> Dict String Checks
updateCheckDict selector check checks =
  Dict.update (selector check) (addCheck check) checks

groupBy : (Check -> String) -> Checks -> Dict String Checks
groupBy selector checks =
  List.foldl (updateCheckDict selector) Dict.empty checks

displayGrouping : Checks -> Dict String Checks
displayGrouping = groupBy .serviceName
