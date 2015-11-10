module WebUI where

import Mantl
import Effects
import Html exposing (Html)
import Signal
import StartApp
import Task

app : StartApp.App Mantl.Model
app = StartApp.start { init = Mantl.init
                     , update = Mantl.update
                     , view = Mantl.view
                     , inputs = [ ] }

main : Signal Html
main = app.html

port tasks : Signal (Task.Task Effects.Never ())
port tasks = app.tasks
