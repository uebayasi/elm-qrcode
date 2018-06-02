module Main exposing (..)

import Browser exposing (Page)
import Browser.Navigation
import Html exposing (..)
import Html.Attributes exposing (selected, title, type_, style, class, href)
import Html.Events exposing (on, onInput, onSubmit, targetValue)
import Html.Lazy exposing (lazy3)
import Json.Decode as Decode exposing (Value)
import Json.Encode as Encode
import QRCode exposing (QRCode, ErrorCorrection(..), Error(..))
import Url exposing (Url)


main : Program Value Model Msg
main =
    Browser.fullscreen
        { init = init
        , onNavigation = Just onNavigation
        , subscriptions = \_ -> Sub.none
        , update = update
        , view = view
        }


init : Browser.Env Value -> ( Model, Cmd Msg )
init { url, flags } =
    ( initModel url.fragment
    , Cmd.none
    )


onNavigation : Url -> Msg
onNavigation url =
    UrlChange url



-- MODEL


type alias Model =
    { message : String
    , ecLevel : ErrorCorrection
    , renderer : Renderer
    , finalMessage : String
    }


initModel : Maybe String -> Model
initModel mS =
    { message = ""
    , ecLevel = Quartile
    , renderer = Svg
    , finalMessage = Maybe.withDefault "Elm QR Code" mS
    }


type Renderer
    = Svg
    | String_



-- UPDATE


type Msg
    = UrlChange Url
    | UpdateMessage String
    | ChangeRenderer Renderer
    | ChangeErrorCorrection ErrorCorrection
    | Render


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChange _ ->
            ( model
            , Cmd.none
            )

        UpdateMessage message ->
            ( { model | message = message }
            , Cmd.none
            )

        ChangeRenderer renderer ->
            ( { model | renderer = renderer }
            , Cmd.none
            )

        ChangeErrorCorrection ecLevel ->
            ( { model | ecLevel = ecLevel }
            , Cmd.none
            )

        Render ->
            ( { model | finalMessage = model.message }
            , Cmd.none
            )



-- VIEW


view : Model -> Page Msg
view model =
    Page "Elm QR Code" (view_ model)


view_ : Model -> List (Html Msg)
view_ { ecLevel, renderer, finalMessage } =
    [ h1 [] [ text "Elm QR Code" ]
    , p [ class "subheading" ]
        [ a [ href "http://package.elm-lang.org/packages/pablohirafuji/elm-qrcode/latest" ]
            [ text "Package" ]
        , text " / "
        , a [ href "https://github.com/pablohirafuji/elm-qrcode" ]
            [ text "GitHub" ]
        , text " / "
        , a [ href "https://github.com/pablohirafuji/elm-qrcode/blob/master/demo/Main.elm" ]
            [ text "Source" ]
        ]
    , form [ onSubmit Render ]
        [ input
            [ onInput UpdateMessage
            , Html.Attributes.property "defaultValue"
                (Encode.string finalMessage)
            ]
            []
        , select
            [ title "Error Correction Level"
            , targetValue
                |> Decode.map
                    (\str ->
                        case str of
                            "Low" ->
                                Low

                            "Medium" ->
                                Medium

                            "Quartile" ->
                                Quartile

                            _ ->
                                High
                    )
                |> Decode.map ChangeErrorCorrection
                |> on "change"
            ]
            [ option
                [ selected (ecLevel == Low) ]
                [ text "Low" ]
            , option
                [ selected (ecLevel == Medium) ]
                [ text "Medium" ]
            , option
                [ selected (ecLevel == Quartile) ]
                [ text "Quartile" ]
            , option
                [ selected (ecLevel == High) ]
                [ text "High" ]
            ]
        , select
            [ title "Renderer"
            , targetValue
                |> Decode.map
                    (\str ->
                        if str == "SVG" then
                            Svg
                        else
                            String_
                    )
                |> Decode.map ChangeRenderer
                |> on "change"
            ]
            [ option
                [ selected (renderer == Svg) ]
                [ text "SVG" ]
            , option
                [ selected (renderer == String_) ]
                [ text "String" ]
            ]
        , button [ type_ "submit" ] [ text "Render" ]
        ]
    , lazy3 qrCodeView finalMessage ecLevel renderer
    ]


qrCodeView : String -> ErrorCorrection -> Renderer -> Html msg
qrCodeView message ecLevel renderer =
    QRCode.encodeWith message ecLevel
        |> qrCodeRender renderer
        |> \n ->
            case n of
                Ok a ->
                    a

                Err e ->
                    div []
                        [ p []
                            [ text "An error occured while encoding to QRCode: "
                            , i [] [ text (errorToString e) ]
                            ]
                        , p []
                            [ text "If the error is not "
                            , i [] [ text "InputLengthOverflow" ]
                            , text " then, please, report at "
                            , a [ href "https://github.com/pablohirafuji/elm-qrcode/issues" ] [ text "https://github.com/pablohirafuji/elm-qrcode/issues" ]
                            , text "."
                            ]
                        ]


errorToString : QRCode.Error -> String
errorToString e =
    case e of
        AlignmentPatternNotFound ->
            "AlignmentPatternNotFound"

        InvalidNumericChar ->
            "InvalidNumericChar"

        InvalidAlphanumericChar ->
            "InvalidAlphanumericChar"

        InvalidUTF8Char ->
            "InvalidUTF8Char"

        LogTableException i ->
            "LogTableException " ++ String.fromInt i

        PolynomialMultiplyException ->
            "PolynomialMultiplyException"

        PolynomialModException ->
            "PolynomialModException"

        InputLengthOverflow ->
            "InputLengthOverflow"


qrCodeRender : Renderer -> Result Error QRCode -> Result Error (Html msg)
qrCodeRender renderer =
    case renderer of
        Svg ->
            Result.map QRCode.toSvg

        String_ ->
            Result.map (QRCode.toString >> toHtml)


toHtml : String -> Html msg
toHtml qrCodeStr =
    Html.pre
        [ style "line-height" "0.6"
        , style "background" "white"
        , style "color" "black"
        , style "padding" "20px"
        , style "letter-spacing" "-0.5px"
        ]
        [ Html.code [] [ Html.text qrCodeStr ] ]
