include karax/prelude
import karax/[kdom, kajax]
import json, sugar
import ../app_types
from dom import setTimeout

type
    Seconds = distinct int

const 
    span_class = "bg-green black-80 pt1"
    button_class = "f6 link dim br3 ph3 pv2 mb2 dib white bg-purple"

var 
    page_loaded: bool
    app_state: cstring
    return_button: cstring = "click here for more stuff"
    movement_left_blank = false

# template show_for(t: Seconds, stmts: untyped) = 
#     window.setTimeout(code = stmts, pause: t)

proc getJsonValue(input: cstring, key: string): cstring =
    var json_node = JsonNode(parseJson($input))
    return json_node[key].getStr()

proc getOptionValue(input_node_id: cstring): string =
    var select_elem = document.getElementById(input_node_id)
    for this_option in select_elem.options:
        if this_option.selected:
            return $this_option.text

proc validate_and_submit(submit_type: CreateType, name_id: cstring, option_box_ids: seq[string]) =
    # Get name of movement
    var name_elem = document.getElementById(name_id)
    var name = name_elem.value

    if name.isNil or name == "": 

        movement_left_blank = true

    else:

        movement_left_blank = false

        var submit_options = parseJson("{}")
        submit_options.add(key = $"status", val = newJString($"Incomplete"))
        submit_options.add(key = $"error", val = newJString($""))
        submit_options.add(key = $"name", val = newJString($name))

        for option_id in option_box_ids:
            submit_options.add(key = $option_id, val = newJString(getOptionValue(option_id)))

        case submit_type:
            of CreateMovement:
                try:
                    discard submit_options.to(Movement)
                except:
                    echo getCurrentExceptionMsg()

                ajaxPost(url = $submit_type, headers = @[], data = $submit_options, proc (status: int, resp: cstring) =
                    echo ($status, $resp))

proc render(): VNode =

    if window.location.pathname == "/index.html" or window.location.pathname == "/": 

        result = buildHtml():

            if not page_loaded:
                ajaxGet("/welcome.json", @[], proc (s: int, r: cstring) = 
                    app_state = getJsonValue(r, "content")
                    page_loaded = true
                )
            
            tdiv:
                span(class = span_class):
                    h1(class = span_class):
                        text app_state

                a(class = button_class, onclick = () =>
                    ajaxGet("/some_other_val.json", @[], proc (s: int, r: cstring) = 
                        return_button = getJsonValue(r, "content"))):
                        text return_button

                # TODO: make this a proc, or possibly template.  Couldn't do it because
                # the compiler didn't recognize `option` inside a template
                h3:
                    text "Add a new movement"
                    br()
                    span(class = span_class):
                        input(id = "movement_name", placeholder = "Enter movement")
                        tdiv(id = "movement_error"):
                            if movement_left_blank:
                                text "Movement can't be left blank"
                            else:
                                text ""

                    br()

                    span(class = span_class):
                        label(`for` = "movement_plane", class = span_class, id = "movement_plane_container"):
                            select(id = "movement_plane"):
                                option(value = "Select Movement Plane")
                                for movement_plane in MovementPlane.low .. MovementPlane.high:
                                    option(value = ord(movement_plane).toCstr):
                                        text $movement_plane

                    span(class = span_class):
                        label(`for` = "body_area", class = span_class, id = "body_area_container"):
                            select(id = "body_area"):
                                option(value = "Select Body Area")
                                for body_area in BodyArea.low .. BodyArea.high:
                                    option(value = ord(body_area).toCstr):
                                        text $body_area

                    span(class = span_class):
                        label(`for` = "movement_type", class = span_class, id = "movement_type_container"):
                            select(id = "movement_type"):
                                option(value = "Select Movement Type")
                                for movement_type in MovementType.low .. MovementType.high:
                                    option(value = ord(movement_type).toCstr):
                                        text $movement_type

                    span(class = span_class):
                        label(`for` = "movement_category", class = span_class, id = "movement_category_container"):
                            select(id = "movement_category"):
                                option(value = "Select Movement Category")
                                for movement_category in MovementCategory.low .. MovementCategory.high:
                                    option(value = ord(movement_category).toCstr):
                                        text $movement_category

                    a(class = button_class, onclick = () => 
                        validate_and_submit(submit_type = CreateMovement, name_id = "movement_name", option_box_ids = @["movement_plane", "body_area", "movement_type", "movement_category"])):
                        text "Click to submit"


    else:
        result = buildHtml():
            span(class = "ba p2"):
                h2:
                    text "Looks like your after the wrong url!"
    
    
    return result

setRenderer render