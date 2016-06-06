module Attributes exposing (..)

import Html exposing (Attribute)
import Html.Attributes exposing (classList)


classes : List String -> Attribute msg
classes cs =
    cs
        |> List.map (\m -> ( m, True ))
        |> classList
