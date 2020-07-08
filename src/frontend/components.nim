include karax/prelude
import karax/[kdom, kajax]

type
    Span* = enum
        AttentionSpan = "bg-green ph5-ns bt b--black-10 tc pt0 mb0"
        StatusSpan = "bg-blue white-70 ph2-ns bt b--black-10 tl pt0 mb0"
        InformationSpan = "bg-white ph5-ns bt b--black-10 tc pt0 mb0"
        ReverseSpan = "bg-red ph5-ns bt b--black-10 tc pt0 mb0"
    
    Header* = enum
        AttentionHeader = "avenir f4 mb0 black-80"
        StatusSpanHeader = "avenir f8 mb0"
        InformationHeader = "avenir f7 mb0 white-80"
        DirectiveHeader = "avenir f6 mb0 white-70 i"

    Button* = enum
        BigGreenButton = "w4 f10 no-underline br-pill ph2 pv2 mb2 white bg-green"
        BigBlueButton = "w4 f10 no-underline br-pill ph2 pv2 mb2 white bg-blue"
        BigRedButton = "w4 f10 no-underline br-pill ph2 pv2 mb2 white bg-red"


proc createSpan*(span: Span, header: Header, padding: int, message: string): VNode =
    result = buildHtml():
        header(class = $span):
            tdiv(class = "pb" & $padding & " pt0"):
                h1(class = $header):
                    text message

    return result