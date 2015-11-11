module Attributes where

import Html exposing (Attribute)
import Html.Attributes exposing (classList)

classes : List String -> Attribute
classes cs =
  cs
    |> List.map (\m -> (m, True))
    |> classList
