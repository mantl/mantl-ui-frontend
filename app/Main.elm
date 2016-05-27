module WebUI exposing (..)

import Mantl
import Navigation
import Route
import Time


main =
    Navigation.program (Navigation.makeParser Route.locFor)
        { init = Mantl.init
        , update = Mantl.update
        , urlUpdate = Mantl.updateRoute
        , view = Mantl.view
        , subscriptions = subscriptions
        }


subscriptions : Mantl.Model -> Sub Mantl.Msg
subscriptions model =
    Time.every (10 * Time.second) (\_ -> Mantl.Refresh)
