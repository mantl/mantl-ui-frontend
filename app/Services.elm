module Services where

import Attributes exposing (classes)
import Effects exposing (Effects)
import Html exposing (..)
import Html.Attributes exposing (href, class)
import Html.Events exposing (onClick)
import Http
import Json.Decode exposing ((:=), Decoder, object2, string, list)
import Signal
import Task

-- MODEL

type alias Service = { name : String
                     , path : String }

type alias Services = List Service

type alias Model = Maybe Services

init : ( Model, Effects Action )
init =
  (Nothing, loadServices)

-- UPDATE

type Action
  = LoadServices
  | NewServices Model

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    NewServices services ->
      ( services, Effects.none )

    LoadServices ->
      ( model, loadServices )

    _ -> (model, Effects.none)

-- ACTIONS

loadServices : Effects Action
loadServices =
  Http.get (list serviceDecoder) "/_internal/services.json"
      |> Task.toMaybe
      |> Task.map NewServices
      |> Effects.task

serviceDecoder : Decoder Service
serviceDecoder = object2 Service
                         ("name" := string)
                         ("path" := string)

-- VIEW

serviceView : Signal.Address Action -> Service -> Html
serviceView address service =
  div [ classes [ "col-sm-3", "service" ] ]
      [ div [ classes [ "card", "card-block" ] ]
            [ div [ class "logo" ] [ div [ class service.name ] [ ] ]
            , h4 [ class "card-title"] [ text service.name ]
            , a [ classes [ "btn", "btn-block", "btn-primary" ]
                , href service.path ]
                [ text "Web UI" ] ] ]

view : Signal.Address Action -> Model -> Html
view address model =
  let
    content =
      case model of
        Nothing ->
          p [ class "col-sm-12" ] [ text "No services loaded" ]

        Just services ->
          div [ class "col-sm-12" ]
              [ div [ classes [ "row", "controls" ] ]
                    [ div [ class "col-sm-12" ]
                          [ button [ classes [ "btn", "btn-sm", "btn-secondary" ]
                                   , onClick address LoadServices ]
                                   [ text "Reload Services" ] ] ]
              , div [ classes [ "row", "services" ] ]
                    (List.map (serviceView address) services) ]
  in
    div [ class "row" ]
        [ content ]
