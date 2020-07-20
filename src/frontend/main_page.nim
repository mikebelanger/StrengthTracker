include karax/prelude
import karax/[kdom, kajax]
import json, sugar
import ../app_types, ../app_routes
import components
import strutils, sequtils

type PageMode = enum Login, UserMainPage, Workout, ManageMovements
var
    page_loaded: bool
    app_state: cstring
    return_button: cstring = "click here for more stuff"
    movement_left_blank = false
    pageMode = Login
    all_movements: seq[Movement]
    current_user: User
    all_users = @[User(name: "Another user", email: "anotheruser@email.com")]
    planes: seq[string]
    areas: seq[string]
    concentric_types: seq[string]
    symmetries: seq[string]

proc switchTo(p: PageMode) =
    pageMode = p

proc switchTo(p: PageMode, cb: proc) =
    cb()
    pageMode = p

proc read_all_users() =
             
    ajaxGet(url = $ReadAllUsers, headers = @[], proc(status: int, resp: cstring) =
        case status:
            of 200:
                try:
                    var users = parseJson($resp).mapIt(it.to(User))
                    all_users.add(users)

                except Exception as e:
                    echo "read_all_users error: ", e.msg

            else:
                echo "unhandled code: ", status
    )

proc readMovement(id: int) =
    var submit_data = %*{"id": id}

    ajaxPost(url = $ReadMovement, headers = @[], data = $submit_data, proc (status: int, resp: cstring) =
        case status:
            of 200:
                echo "parsing movement: ", $resp
                var new_movement = parseJson($resp).to(Movement)

                for i, movement in all_movements:

                    if movement.id == new_movement.id:
                        all_movements[i] = new_movement

            else:
                echo "unexpected response: ", status
               
    )

proc readAllMovements() =
    ajaxGet(url = $ReadAllMovement, headers = @[], proc (status: int, resp: cstring) =
        all_movements = parseJson($resp).mapIt(it.to(Movement))
    )
    
proc readDistinctMovementAttributes() =
    ajaxGet(url = $ReadAllMovementAttrs, headers = @[], proc (status: int, resp: cstring) =
        var parsed = parseJson($resp)

        planes = parsed{"planes"}.getElems.mapIt(it.str)
        areas = parsed{"areas"}.getElems.mapIt(it.str)
        concentric_types = parsed{"concentric_types"}.getElems.mapIt(it.str)
        symmetries = parsed{"symmetries"}.getElems.mapIt(it.str)
    )

proc readMovementsAndDistinctAttributes() =
    readAllMovements()
    readDistinctMovementAttributes()

proc getJsonValue(input: cstring, key: string): cstring =
    var json_node = JsonNode(parseJson($input))
    return json_node[key].getStr()

proc getTextValue(input_node_id: cstring): string =
    var node = document.getElementById(input_node_id)
    return $node.value

proc getOptionValue(input_node_id: cstring): string =
    var select_elem = document.getElementById(input_node_id)
    for this_option in select_elem.options:
        if this_option.selected:
            return $this_option.value


proc create_movement(name_id, area_id, plane_id, concentric_type_id, symmetry_id, description_id: cstring): proc () =

    result = proc () =
    
        var 
            name_elem = document.getElementById(name_id)
            name = name_elem.value

        if name.isNil or name == "":

            movement_left_blank = true

        else:

            movement_left_blank = false

            var 
                movement = Movement(
                    name: $name,
                    plane: parseEnum[MovementPlane](get_option_value(plane_id)),
                    area: parseEnum[MovementArea](get_option_value(area_id)),
                    concentric_type: parseEnum[ConcentricType](get_option_value(concentric_type_id)),
                    symmetry: parseEnum[Symmetry](get_option_value(symmetry_id)),
                    description: getTextValue(description_id)
                )

                submit_movement = %*movement
                
            ajaxPost(url = $CreateMovement, headers = @[], data = $submit_movement, proc (status: int, resp: cstring) =
                echo ($status, $resp)
                
                if status == 200:
                    readAllMovements()
            )


proc update_movement(db_id, name_id, area_id, plane_id, concentric_type_id, symmetry_id, description_id: cstring): proc () =

    result = proc () =
    
        var 
            name_elem = document.getElementById(name_id)
            name = name_elem.value
            movement = Movement(
                kind: Existing,
                id: db_id.parseInt,
                name: $name,
                plane: parseEnum[MovementPlane](get_option_value(plane_id)),
                area: parseEnum[MovementArea](get_option_value(area_id)),
                concentric_type: parseEnum[ConcentricType](get_option_value(concentric_type_id)),
                symmetry: parseEnum[Symmetry](get_option_value(symmetry_id)),
                description: getTextValue(description_id)
            )

            submit_movement = %*movement

        ajaxPost(url = $UpdateMovement, headers = @[], data = $submit_movement, proc (status: int, resp: cstring) =
            
            if status == 200:
                readMovement(id = movement.id)
        )


proc repsSliderToOutput() = 
    var repsInputElement = document.getElementById("repsInputId")
    var repsOutputElement = document.getElementById("repsOutputId")
    repsOutputElement.value = repsInputElement.value & " reps"

proc optionsMenu(name, message: cstring, selected = "", options: seq[string]): VNode =

    return buildHtml():
            tdiv:
                label(`for` = name, id = name & "_container"):
                    select(id = name):
                        if message.len > 0:
                            option(value = ""):
                                text message
                        
                        for option in options:
                            if option == selected:
                                option(value = selected, selected = "selected"):
                                    text selected
                            else:
                                option(value = option):
                                    text option

proc login(user: User) =
    ajaxPost(ReadUser, headers = @[], data = $(%*user), proc (status: int, resp: cstring) =

        if status == 200:

            for u in ($resp).parseJson:
                current_user = u.to(User)
    )
    switchTo(UserMainPage)


proc render(): VNode =
    
    if window.location.pathname == "/index.html" or window.location.pathname == "":
        result = 
            buildHtml():
                tdiv:
                    createSpan(span = StatusSpan, header = InformationHeader, padding = 1, message = "Currently not logged in.")

                    case pageMode:
                        of Login:
                            span(class = "ph2 tc m5"):      
                                for user in all_users:
                                    a(class = "br-pill ph2 m10 pv2 center bg-blue b--black-10", onclick = () => login(user)):
                                        text user.name


                        of UserMainPage:

                            createSpan(span = AttentionSpan, header = AttentionHeader, padding = 3, message = "Welcome, " & current_user.name)
                        
                            a(class = "br-pill ph2 pv2 mb2 white bg-blue", onclick = () => switchTo(Workout)):
                                text "Start the workout"

                            a(class = "br-pill ph2 pv2 mb2 white bg-blue", onclick = () => switchTo(ManageMovements, readMovementsAndDistinctAttributes)):
                                text "Look at Exercise Options"

                        of ManageMovements:

                            #########################################
                            #### VIEW/EDIT EXISTING MOVEMENTS #######
                            #########################################

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
                                        text "Symmetry"
                                    th(class = "fw6 tl pa3 bg-green tr"):
                                        text "Description"

                                tbody(class = "lh-copy"):
                                    for m in all_movements:
                                        let 
                                            # define IDs for submission
                                            db_id = $m.id
                                            m_name = m.name.toLowerAscii.replace(" ", "")
                                            m_id = m_name & "_id"
                                            m_plane = m_name & "_plane"
                                            m_area = m_name & "_area"
                                            m_concentric_type = m_name & "_concentric_type"
                                            m_symmetry = m_name & "_symmetry"
                                            m_description = m_name & "_description"


                                        tr(class = "stripe-dark"):
                                            input(type = "hidden", value = db_id, id = m_id)
                                            input(class = "pa3 tl tl", id = m_name, value = m.name)
                                            td(class = "pa3 tl tl"):
                                                optionsMenu(name = m_plane, message = "", selected = $m.plane, options = planes)
                                            td(class = "pa3 tl tl"):
                                                optionsMenu(name = m_area, message = "", selected = $m.area, options = areas)
                                            td(class = "pa3 tl tl"):
                                                optionsMenu(name = m_concentric_type, message = "", selected = $m.concentric_type, options = concentric_types)
                                            td(class = "pa3 tl tl"):
                                                optionsMenu(name = m_symmetry, message = "", selected = $m.symmetry, options = symmetries)
                                            td(class = "pa3 tl tl"):
                                                textarea(class = "pa3 tl tl", id = m_description, value = $m.description)
                                            td(class = "pa3 tl tl"):
                                                a(class = $BigGreenButton, onclick = 
                                                update_movement(db_id = db_id,
                                                                name_id = m_name, 
                                                                plane_id = m_plane, 
                                                                area_id = m_area, 
                                                                concentric_type_id = m_concentric_type, 
                                                                symmetry_id = m_symmetry,
                                                                description_id = m_description
                                                )):
                                                    text "Update"
                                            # td(class = "pa3 tl tl"):
                                            #     a(class = $BigRedButton):
                                            #         text "Delete"

                            createSpan(span = AttentionSpan, header = DirectiveHeader, padding = 2, message = "Add movement")

                            span(class = $InformationSpan):
                                input(id = "movement_name", placeholder = "Enter movement")
                                tdiv(id = "movement_error"):
                                    if movement_left_blank:
                                        text "Movement name can't be left blank"
                                    else:
                                        text ""

                            br()

                            ################################
                            #### CREATE NEW MOVEMENT #######
                            ################################

                            span(class = $InformationSpan):
                                optionsMenu(name = "plane_id", message = "Select Movement Plane", options = planes)
                                optionsMenu(name = "area_id", message = "Select Body Area", options = areas)
                                optionsMenu(name = "concentric_type_id", message = "Select Concentric Type", options = concentric_types)
                                optionsMenu(name = "symmetry_id", message = "Select Symmetry", options = symmetries)
                                textarea(class = "pa3 tl tl", id = "description_id", placeholder = "Enter description")

                            a(class = $BigGreenButton & " avenir tc", onclick = 
                                create_movement(name_id = "movement_name", plane_id = "plane_id", 
                                                                        area_id = "area_id",
                                                                        concentric_type_id = "concentric_type_id",
                                                                        symmetry_id = "symmetry_id",
                                                                        description_id = "description_id")):

                                text "Click to submit"

                            footer(class = $ReverseSpan & " avenir tl pt2 pb2", onclick = () => switchTo(UserMainPage)):
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

                            footer(class = $ReverseSpan & " avenir tl pt2 pb2", onclick = () => switchTo(UserMainPage)):
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
read_all_users()