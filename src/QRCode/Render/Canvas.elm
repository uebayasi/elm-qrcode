module QRCode.Render.Canvas exposing
    ( view
    , viewWithAbsoluteSize
    , viewWithModuleSize
    )

import Collage exposing (Form, collage, filled, group, move, moveX, moveY, square)
import Color exposing (black, white)
import Element
import Html exposing (Html)


view : List (List Bool) -> Html msg
view matrix =
    viewWithModuleSize 5 matrix


viewWithModuleSize : Int -> List (List Bool) -> Html msg
viewWithModuleSize moduleSize matrix =
    let
        quietZone =
            8 * moduleSize

        qrCodeSize =
            List.length matrix * moduleSize

        totalSize =
            qrCodeSize + quietZone

        centerDistance =
            toFloat (qrCodeSize - moduleSize) / 2
    in
    collage
        totalSize
        totalSize
        [ toFloat totalSize
            |> square
            |> filled white
        , matrixToForm moduleSize matrix
            |> move ( -centerDistance, centerDistance )
        ]
        |> Element.toHtml


matrixToForm : Int -> List (List Bool) -> Form
matrixToForm moduleSize matrix =
    List.indexedMap
        (\index row ->
            canvasRow moduleSize row
                |> moveY (toFloat (-index * moduleSize))
        )
        matrix
        |> group


canvasRow : Int -> List Bool -> Form
canvasRow moduleSize row =
    List.indexedMap
        (\index isDark ->
            if isDark then
                canvasModule moduleSize
                    |> moveX (toFloat (index * moduleSize))
                    |> Just

            else
                Nothing
        )
        row
        |> List.filterMap identity
        |> group


canvasModule : Int -> Form
canvasModule moduleSize =
    moduleSize
        |> toFloat
        |> square
        |> filled black


viewWithAbsoluteSize : Int -> List (List Bool) -> Html msg
viewWithAbsoluteSize matrixAbsSize matrix =
    let
        length =
            List.length matrix

        moduleSize =
            floor (toFloat matrixAbsSize / toFloat (length + 8))

        quietZone =
            matrixAbsSize - (moduleSize * length)

        qrCodeSize =
            length * moduleSize

        totalSize =
            qrCodeSize + quietZone

        centerDistance =
            toFloat (qrCodeSize - moduleSize) / 2
    in
    collage
        totalSize
        totalSize
        [ toFloat totalSize
            |> square
            |> filled white
        , if (totalSize + moduleSize) % 2 == 0 then
            matrixToForm moduleSize matrix
                |> move ( -centerDistance, centerDistance )

          else
            matrixToForm2 moduleSize matrix
                |> move ( -centerDistance, centerDistance )
        ]
        |> Element.toHtml


matrixToForm2 : Int -> List (List Bool) -> Form
matrixToForm2 moduleSize matrix =
    List.indexedMap
        (\index row ->
            canvasRow2 moduleSize row
                |> moveY (toFloat (-index * moduleSize) + 0.5)
        )
        matrix
        |> group


canvasRow2 : Int -> List Bool -> Form
canvasRow2 moduleSize row =
    List.indexedMap
        (\index isDark ->
            if isDark then
                canvasModule moduleSize
                    |> moveX (toFloat (index * moduleSize) + 0.5)
                    |> Just

            else
                Nothing
        )
        row
        |> List.filterMap identity
        |> group
