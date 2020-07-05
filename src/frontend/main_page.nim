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
    planes = parseJson("[]")
    areas = parseJson("[]")
    concentric_types = parseJson("[]")
    symmetries = parseJson("[]")

# template show_for(t: Seconds, stmts: untyped) = 
#     window.setTimeout(code = stmts, pause: t)
proc switchTo(p: PageMode) =
    pageMode = p

proc switchTo(p: PageMode, cb: proc) =
    cb()
    pageMode = p

proc readAllMovements() =
    ajaxGet(url = $ReadAllMovement, headers = @[], proc (status: int, resp: cstring) =
        all_movements = parseJson($resp))

proc readDistinctMovementAttributes() =
    ajaxGet(url = $ReadAllMovementAttrs, headers = @[], proc (status: int, resp: cstring) =
        var parsed = parseJson($resp)
        planes = parsed{"planes"}
        areas = parsed{"areas"}
        concentric_types = parsed{"concentric_types"}
        symmetries = parsed{"symmetries"})

proc readMovementsAndDistinctAttributes() =
    readAllMovements()
    readDistinctMovementAttributes()

proc getJsonValue(input: cstring, key: string): cstring =
    var json_node = JsonNode(parseJson($input))
    return json_node[key].getStr()

proc getOptionValue(input_node_id: cstring): string =
    var select_elem = document.getElementById(input_node_id)
    for this_option in select_elem.options:
        if this_option.selected:
            return $this_option.value

proc validate_and_submit(submit_type, name_id: cstring, option_box_ids: seq[string]) =
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

        echo $submit_options
        ajaxPost(url = $submit_type, headers = @[], data = $submit_options, proc (status: int, resp: cstring) =
            echo ($status, $resp)
            
            if status == 200:
                readAllMovements()
        )


proc repsSliderToOutput() = 
    var repsInputElement = document.getElementById("repsInputId")
    var repsOutputElement = document.getElementById("repsOutputId")
    repsOutputElement.value = repsInputElement.value & " reps"

proc optionsMenu(name, message: cstring, options: JsonNode): VNode =

    return buildHtml():
            tdiv:
                label(`for` = name, id = name & "_container"):
                    select(id = name):
                        option(value = "", `selected data-default` = nil):
                            text message
                        for i in options.items:
                            option(value = i.getStr):
                                text i.getStr

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

                            a(class = "br-pill ph2 pv2 mb2 white bg-blue", onclick = () => switchTo(ManageMovements, readMovementsAndDistinctAttributes)):
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
                                                text m{"plane"}.getStr
                                            td(class = "pa3 tl tl"):
                                                text m{"area"}.getStr
                                            td(class = "pa3 tl tl"):
                                                text m{"concentric_type"}.getStr
                                            td(class = "pa3 tl tl"):
                                                text m{"symmetry"}.getStr

                            createSpan(span = AttentionSpan, header = DirectiveHeader, padding = 2, message = "Add movement")

                            span(class = $InformationSpan):
                                input(id = "movement_name", placeholder = "Enter movement")
                                tdiv(id = "movement_error"):
                                    if movement_left_blank:
                                        text "Movement name can't be left blank"
                                    else:
                                        text ""

                            br()

                            span(class = $InformationSpan):
                                optionsMenu(name = "plane", message = "Select Movement Plane", planes)
                                optionsMenu(name = "area", message = "Select Body Area", areas)
                                optionsMenu(name = "concentric_type", message = "Select Concentric Type", concentric_types)
                                optionsMenu(name = "symmetry", message = "Select Symmetry", symmetries)

                            a(class = $BigGreenButton & " avenir tc", onclick = () => 
                                validate_and_submit(submit_type = $CreateMovement, name_id = "movement_name", option_box_ids = @["plane", "area", "concentric_type", "symmetry"])):
                                text "Click to submit"

                            footer(class = $ReverseSpan & " avenir tl pt2 pb2", onclick = () => switchTo(Welcome)):
                                text "Back to main page"

 
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
                                a(class = $BigBlueButton & " avenir tc pb3"):
                                    text "Done Combo"

                            footer(class = $ReverseSpan & " avenir tl pt2 pb2", onclick = () => switchTo(Welcome)):
                                text "Back to main page"

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