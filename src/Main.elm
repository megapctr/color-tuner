module Main exposing (main)

import Browser
import Dict
import Parsers
import Types exposing (Model, Msg(..))
import View exposing (view)



-- MAIN


main : Program () Model Msg
main =
    Browser.sandbox
        { init = Types.init |> (\m -> update (GotInputText m.inputText) m)
        , view = view
        , update = update
        }



-- UPDATE


update : Msg -> Model -> Model
update msg model =
    case msg of
        GotInputText value ->
            case Parsers.parseCssInput value of
                Ok themeColors ->
                    { model
                        | inputText = value
                        , inputErrors = []
                        , themeColorNames = List.map .name themeColors
                        , themeColorsByName =
                            List.map (\c -> ( c.name, c )) themeColors
                                |> Dict.fromList
                    }

                Err errors ->
                    { model
                        | inputText = value
                        , inputErrors = List.map Parsers.deadEndToString errors
                    }

        GotHsluvTextInput name hsl s ->
            let
                updateItem item =
                    let
                        newComponents =
                            case String.toFloat s of
                                Just value ->
                                    Types.setComponentValue (Just s) hsl value item.components

                                Nothing ->
                                    let
                                        component =
                                            Types.getThemeColorComponent hsl item.components
                                    in
                                    Types.setThemeColorComponent hsl
                                        { component
                                            | input = s
                                            , valid = False
                                        }
                                        item.components
                    in
                    { item
                        | newColor = Types.colorFromComponents newComponents
                        , components = newComponents
                    }
            in
            { model
                | themeColorsByName =
                    Dict.update name (Maybe.map updateItem) model.themeColorsByName
            }

        GotHsluvRangeInput name hsl value ->
            let
                updateItem item =
                    let
                        newComponents =
                            Types.setComponentValue Nothing hsl value item.components
                    in
                    { item
                        | newColor = Types.colorFromComponents newComponents
                        , components = newComponents
                    }
            in
            { model
                | themeColorsByName =
                    Dict.update name (Maybe.map updateItem) model.themeColorsByName
            }

        GotAverageRangeInput hsl old new ->
            let
                d =
                    new - old

                updateItem item =
                    let
                        component =
                            Types.getThemeColorComponent hsl item.components

                        newValue =
                            component.value + d

                        newComponents =
                            Types.setComponentValue Nothing hsl newValue item.components
                    in
                    { item
                        | newColor = Types.colorFromComponents newComponents
                        , components = newComponents
                    }
            in
            { model
                | themeColorsByName =
                    Dict.map (always updateItem) model.themeColorsByName
            }

        ToggleZoom component ->
            let
                zoom =
                    if model.zoom == Just component then
                        Nothing

                    else
                        Just component
            in
            { model | zoom = zoom }
