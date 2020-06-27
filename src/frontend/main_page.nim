include karax/prelude
import karax/[kdom, kajax]
import json, sugar
import ../app_types
import components

type PageMode = enum Welcome, Workout, ManageMovements
var 
    page_loaded: bool
    app_state: cstring
    return_button: cstring = "click here for more stuff"
    movement_left_blank = false
    pageMode = Welcome
    all_movements = parseJson("[]")

# template show_for(t: Seconds, stmts: untyped) = 
#     window.setTimeout(code = stmts, pause: t)
proc switchTo(p: PageMode) =
    pageMode = p

proc switchTo(p: PageMode, cb: proc) =
    cb()
    pageMode = p

proc loadMovements() =
    ajaxPost(url = "/db_read_all_movements.json", headers = @[], data = "", proc (status: int, resp: cstring) =
        all_movements = parseJson($resp){"content"}
        echo all_movements)

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
                    echo ($status, $resp)
                )

                loadMovements()

proc repsSliderToOutput() = 
    var repsInputElement = document.getElementById("repsInputId")
    var repsOutputElement = document.getElementById("repsOutputId")
    repsOutputElement.value = repsInputElement.value & " reps"


proc render(): VNode =

    if window.location.pathname == "/index.html" or window.location.pathname == "":
        result = 
            buildHtml():
                tdiv:
                    createSpan(span = StatusSpan, header = InformationHeader, padding = 1, message = "Currently not logged in.")

                    case pageMode:
                        of Welcome:
                            
                            createSpan(span = AttentionSpan, header = AttentionHeader, padding = 3, message = "Welcome!")
                        
                            a(class = "br-pill ph2 pv2 mb2 white bg-blue", onclick = () => switchTo(Workout)):
                                text "Start the workout"

                            a(class = "br-pill ph2 pv2 mb2 white bg-blue", onclick = () => switchTo(ManageMovements, loadMovements)):
                                text "Look at Exercise Options"

                        of ManageMovements:
                            createSpan(span = AttentionSpan, header = DirectiveHeader, padding = 2, message = "Manage Movements")
                            table(class = "f6 ph3 mt0 center avenir"):
                                thead:
                                    th(class = "fw6 tl pa3 bg-green tl"):
                                        text "Movement"
                                    th(class = "fw6 tl pa3 bg-green tr"):
                                        text "Plane"
                                    th(class = "fw6 tl pa3 bg-green tr"):
                                        text "Body Area"
                                    th(class = "fw6 tl pa3 bg-green tr"):
                                        text "Type"
                                    th(class = "fw6 tl pa3 bg-green tr"):
                                        text "Category"

                                tbody(class = "lh-copy"):
                                    for m in all_movements.items:
                                        tr(class = "stripe-dark"):
                                            td(class = "pa3 tl tl"):
                                                text m{"name"}.getStr
                                            td(class = "pa3 tl tl"):
                                                text m{"movement_plane"}.getStr
                                            td(class = "pa3 tl tl"):
                                                text m{"body_area"}.getStr
                                            td(class = "pa3 tl tl"):
                                                text m{"movement_type"}.getStr
                                            td(class = "pa3 tl tl"):
                                                text m{"movement_category"}.getStr

                            createSpan(span = AttentionSpan, header = DirectiveHeader, padding = 2, message = "Add movement")

                            span(class = $InformationSpan):
                                input(id = "movement_name", placeholder = "Enter movement")
                                tdiv(id = "movement_error"):
                                    if movement_left_blank:
                                        text "Movement can't be left blank"
                                    else:
                                        text ""

                            br()

                            span(class = $InformationSpan):
                                label(`for` = "movement_plane", id = "movement_plane_container"):
                                    select(id = "movement_plane"):
                                        option(value = "Select Movement Plane")
                                        for movement_plane in MovementPlane.low .. MovementPlane.high:
                                            option(value = ord(movement_plane).toCstr):
                                                text $movement_plane

                            span(class = $InformationSpan):
                                label(`for` = "body_area", id = "body_area_container"):
                                    select(id = "body_area"):
                                        option(value = "Select Body Area")
                                        for body_area in BodyArea.low .. BodyArea.high:
                                            option(value = ord(body_area).toCstr):
                                                text $body_area

                            span(class = $InformationSpan):
                                label(`for` = "movement_type", id = "movement_type_container"):
                                    select(id = "movement_type"):
                                        option(value = "Select Movement Type")
                                        for movement_type in MovementType.low .. MovementType.high:
                                            option(value = ord(movement_type).toCstr):
                                                text $movement_type

                            span(class = $InformationSpan):
                                label(`for` = "movement_category", id = "movement_category_container"):
                                    select(id = "movement_category"):
                                        option(value = "Select Movement Category")
                                        for movement_category in MovementCategory.low .. MovementCategory.high:
                                            option(value = ord(movement_category).toCstr):
                                                text $movement_category

                            a(class = $BigGreenButton & " avenir tc", onclick = () => 
                                validate_and_submit(submit_type = CreateMovement, name_id = "movement_name", option_box_ids = @["movement_plane", "body_area", "movement_type", "movement_category"])):
                                text "Click to submit"

                        of Workout:
                            createSpan(span = AttentionSpan, header = DirectiveHeader, padding = 4, message = "Performing Workout: A")
                            createSpan(span = InformationSpan, header = AttentionHeader, padding = 2, message = "Right now, do:")
                            header(class = "tc"):
                                h1(class = $AttentionHeader & " pb2"):
                                    text "Pull-up"
                                input(type = "range", id = "repsInputId", value="8", min = "0", max = "30", oninput = repsSliderToOutput, class = "tl pl2")
                                output(id = "repsOutputId", class="pl3 avenir tr"):
                                    text "can you do " & $8 & " reps ?"
                                h1(class = $AttentionHeader):
                                    a(class = $BigGreenButton & " avenir tc"):
                                        text "Done Set"
                            br()
                            createSpan(span = AttentionSpan, header = DirectiveHeader, padding = 2, message = "This workout so far:")
                            tdiv(class = "bg-green avenir"):
                                table(class = "f6 ph3 mt0 underline center"):
                                    thead:
                                        tr(class = "stripe-dark"):
                                            th(class = "fw6 tl pa3 bg-green tl"):
                                                text "Exercise"
                                            th(class = "fw6 tl pa3 bg-green tr"):
                                                text "Sets"
                                    tbody(class = "lh-copy"):
                                        tr(class = "stripe-dark"):
                                            td(class = "pa3 tl tl"):
                                                text "Split Squat"
                                            td(class = "pa3 tl tr"):
                                                text "1, 5, 3"
                                        tr(class = "stripe-light"):
                                            td(class = "pa3 tl"):
                                                text "Pull Up"
                                            td(class = "pa3 tl"):
                                                text "4, 2, 1"

                            h1(class = "tc"):
                                a(class = $BigBlueButton & " avenir tc"):
                                    text "Done Combo"


    elif window.location.pathname == "/workout.html":
        result = createSpan(span = AttentionSpan, header = AttentionHeader, padding = 3, message = "Your currently doing")

        return result

    else:
        result = buildHtml():
            span(class = "ba p2"):
                h2:
                    text "Looks like your after the wrong url!"
    
    
    return result

setRenderer render