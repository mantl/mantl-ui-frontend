module Health where

import Attributes exposing (classes)
import Debug
import Dict exposing (Dict)
import Effects exposing (Effects)
import Html exposing (..)
import Html.Attributes exposing (class, classList)
import Html.Events exposing (onClick)
import Http
import Json.Decode exposing (Decoder, list, object8, string, (:=), customDecoder)
import List exposing ((::))
import Maybe
import Result
import Task

-- MODEL

type alias Check = { node : String
                   , checkID : String
                   , name : String
                   , status : Status
                   , notes : String
                   , output : String
                   , serviceID : String
                   , serviceName : String }

type Status
  = Passing
  | Unknown
  | Warning
  | Critical
  | Other String

type alias Checks = List Check

type alias Focus = (String, Maybe Checks)

type alias Model = { status : Status
                   , checks : Checks
                   , error : Maybe String
                   , focus : Maybe Focus }

init : ( Model, Effects Action )
init =
  ( { status = Unknown
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
                , status <- worstStatus checks
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
                             ("Status" := statusDecoder)
                             ("Notes" := string)
                             ("Output" := string)
                             ("ServiceID" := string)
                             ("ServiceName" := string)

statusDecoder : Decoder Status
statusDecoder =
  customDecoder string <| \status ->
    case status of
      "passing"  -> Result.Ok Passing
      "unknown"  -> Result.Ok Unknown
      "warning"  -> Result.Ok Warning
      "critical" -> Result.Ok Critical
      _          -> Result.Ok (Other status)

-- VIEW

statusToClass : Status -> String
statusToClass status =
  case status of
    Passing  -> "passing"
    Unknown  -> "unknown"
    Warning  -> "warning"
    Critical -> "critical"
    Other _  -> "other"

healthDot : Status -> Html
healthDot status =
  span [ classList [ ("healthdot", True)
                   , (statusToClass status, True) ] ]
       [ status |> toString |> text ]

attributes : List (String, String) -> Html
attributes attrs =
  dl [ class "attributes" ]
     (attrs
        |> List.map (\ (key, value) -> div [ class "attribute" ]
                                           [ dt [ ] [ text key ]
                                           , dd [ ] [ code [ ] [ text value ] ] ] ))

checkSelector : Signal.Address Action -> String -> Checks -> Bool -> Html
checkSelector address name checks active =
  p [ classList [ ("service", True)
                , ("card", True)
                , ("card-block", True)
                , (worstStatus checks |> statusToClass, True)
                , ("active", active) ]
    , onClick address (Focus name) ]
    [ text name ]

checkDetail : Signal.Address Action -> Check -> Html
checkDetail address check =
  div [ classes [ "check", "card", "card-block", statusToClass check.status ] ]
      [ h2 [ ] [ text check.name ]
      , attributes [ ("Status", check.status |> toString)
                   , ("Check ID", check.checkID)
                   , ("Node", check.node)
                   , ("Service ID", check.serviceID)
                   , ("Service Name", check.serviceName) ]
      , p [ classList [ ("notes", True)
                      , ("hidden", not (hasNotes check |> Debug.log "has notes")) ] ]
          [ strong [ ] [ text "Notes: " ], text check.notes ]
      , p [ ] [ strong [ ] [ text "Output:" ] ]
      , pre [ class "output" ] [ code [ ] [ text check.output ] ] ]

view : Signal.Address Action -> Model -> Html
view address model =
  let
    content =
      if List.isEmpty model.checks
      then p [ class "col-sm-12" ] [ text "No Health Checks loaded" ]
      else
        let
          groups = model.checks |> displayGrouping
          focusContent =
            case model.focus of
              Nothing                   -> div [ ] [ ]
              Just (name, Nothing)      -> div [ ] [ ]
              Just (name, Just checks)  ->
                div [ ]
                    [ h1 [ ]
                         [ healthDot (worstStatus checks)
                         , text name ]
                    , div [ class "checks" ]
                          (List.map (checkDetail address) checks) ]
        in
          div [ class "col-sm-12" ]
              [ div [ classes [ "row", "controls" ] ]
                    [ div [ class "col-sm-12" ]
                          [ button [ classes [ "btn", "btn-sm", "btn-secondary" ]
                                   , onClick address LoadChecks ]
                                   [ text "Reload Health Checks" ] ] ]
              , div [ classes [ "row", "healthchecks" ] ]
                    [ div [ classes [ "services", "col-md-3" ] ]
                          (groups
                             |> Dict.toList
                             |> List.map (\ (name, checks) ->
                                            checkSelector
                                              address name checks
                                              (isFocused name model.focus)))
                    , div [ class "col-md-9" ] [ focusContent ] ] ]
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
displayGrouping checks =
  checks
    |> groupBy .serviceName
    |> Dict.toList
    |> List.map (\ (k, v) ->
                  if k == ""
                  then ("consul", v)
                  else (k, v))
    |> Dict.fromList

hasNotes : Check -> Bool
hasNotes check = check.notes /= ""

isFocused : String -> Maybe Focus -> Bool
isFocused name focus =
  case focus of
    Nothing         -> False
    Just (other, _) -> name == other

worstStatus : Checks -> Status
worstStatus checks =
  checks
    |> List.map .status
    |> List.sortBy
         (\s ->
           case s of
             Critical -> 0
             Warning  -> 1
             Unknown  -> 2
             Passing  -> 3
             Other _  -> 4)
    |> List.head
    |> Maybe.withDefault Unknown

statusForService : String -> Model -> Status
statusForService name = .checks >> displayGrouping >> Dict.get name >> Maybe.withDefault [ ] >> worstStatus
