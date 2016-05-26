module WebUI exposing (..)

import Effects
import History
import Html exposing (Html)
import Mantl
import Route
import Signal
import StartApp
import Task
import Time exposing (every, second)

app : StartApp.App Mantl.Model
app = StartApp.start { init = Mantl.init
                     , update = Mantl.update
                     , view = Mantl.view
                     , inputs = [ refresh ]
                     , inits = [ hash ] }

main : Signal Html
main = app.html

hash : Signal Mantl.Msg
hash = Signal.map (Route.PathChange >> Mantl.RouteMsg) History.hash

refresh : Signal Mantl.Msg
refresh =
  every (10 * second)
    |> Signal.map (\_ -> Mantl.Refresh)

port tasks : Signal (Task.Task Effects.Never ())
port tasks = app.tasks
