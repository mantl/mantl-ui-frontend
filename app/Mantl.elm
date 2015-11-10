module Mantl where

import Html exposing (..)
import Html.Events exposing (onClick)
import Effects exposing (Effects)

-- MODEL

type alias Model = Int

init : ( Model, Effects Action )
init = ( 0, Effects.none )

-- UPDATE

type Action = Increment

update : Action -> Model -> (Model, Effects action)
update action model =
  case action of
    Increment ->
      ( model + 1, Effects.none )

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
  p [ onClick address Increment ]
    [ model |> toString |> text ]
