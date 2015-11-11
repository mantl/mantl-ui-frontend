module WebUI where

import Effects
import History
import Html exposing (Html)
import Mantl
import Route
import Signal
import StartApp
import Task

app : StartApp.App Mantl.Model
app = StartApp.start { init = Mantl.init
                     , update = Mantl.update
                     , view = Mantl.view
                     , inputs = [ ]
                     , inits = [ hash ] }

main : Signal Html
main = app.html

hash : Signal Mantl.Action
hash = Signal.map (Route.PathChange >> Mantl.RouteAction) History.hash

port tasks : Signal (Task.Task Effects.Never ())
port tasks = app.tasks
