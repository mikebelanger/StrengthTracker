include karax/prelude
import karax/[kdom, kajax]
import json, sugar
import ../app_types, ../app_routes
import components
import strutils, strformat, sequtils, algorithm

type PageMode = enum Login, UserMainPage, ShowRoutines, Workout, ManageMovements, ManageMovementCombos, EditRoutine
var
    page_loaded: bool
    app_state: cstring
    return_button: cstring = "click here for more stuff"
    movement_left_blank = false
    pageMode = Login
    all_movements: seq[Movement]
    all_movement_combos: seq[MovementComboGroup]
    current_user = User(kind: New, name: "not logged in", email: "")
    all_users: seq[User]
    planes = MovementPlane.mapIt($it).filterIt(it.contains("Unspecified") == false)
    areas = MovementArea.mapIt($it).filterIt(it.contains("Unspecified") == false)
    concentric_types = ConcentricType.mapIt($it).filterIt(it.contains("Unspecified") == false)
    symmetries = Symmetry.mapIt($it).filterIt(it.contains("Unspecified") == false)
    current_routine: seq[Routine]
    routine_movement_combos: seq[MovementComboGroup]
    finished_sets, finished_groups = 0
    current_session: Session
    new_movement_combo_count: int

proc switchTo(p: PageMode) =
    pageMode = p

proc switchTo(p: PageMode, callbacks: seq[proc]) =
    for cb in callbacks:
        cb()

    pageMode = p

proc add_any_new_to[T](x: T, list: seq[T]): seq[T] =
    var return_list = list

    when x is MovementComboGroup:

        if list.allIt(not it.movement_combo.id == x.movement_combo.id):
            return_list.add(x)

    else:
        if list.allIt(not it.id == x.id):
            return_list.add(x)

    return return_list

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
                var new_movement = parseJson($resp).mapIt(it.to(Movement))

                for i, movement in all_movements:
                    
                    for idx, new_m in new_movement:
                        if movement.id == new_m.id:
                            all_movements[i] = new_m

            else:
                echo "unexpected response: ", status
               
    )

proc readAllMovements() =
    # this part just resets the movement combos for creating new Movement Combos
    new_movement_combo_count = 0
    
    ajaxGet(url = $ReadAllMovement, headers = @[], proc (status: int, resp: cstring) =
        all_movements = parseJson($resp).mapIt(it.to(Movement))
    )

proc readAllMovementCombos() =

    ajaxGet(url = $ReadAllMovementComboGroups, headers = @[], proc (status: int, resp: cstring) =
        if status == 200:
            echo "got response: ", $resp
            all_movement_combos = parseJson($resp).mapIt(it.to(MovementComboGroup))
    )
    
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

proc next_movement() =
    finished_sets += 1

proc next_movement_group() =
    finished_groups += 1

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

proc createMovementCombo() =

    var movements: seq[Movement]
    # loop-thru and get each movement name, and grab its corresponding ID
    for mcn in 0..new_movement_combo_count:

        # get number
        var name_id = document.getElementById("movement_combo_movement_number_" & $mcn)
        if name_id.value.len > 0:         
            echo "name_id: ", name_id.value
            
            echo "all movements"
            var 
                movement_name = name_id.value
                movement = all_movements.filterIt(it.name == movement_name)
                                        # .foldl(a)

            movements.add(movement)

    var movement_combo_name = document.getElementById("movement_combo_name")

    if not (movement_combo_name.isNil) and movement_combo_name.value.len > 0:
        
        var movement_combo = MovementCombo(kind: New, name: $movement_combo_name.value)

        ajaxPost(url = $CreateMovementCombo, headers = @[], data = $(%*movement_combo), proc (status: int, resp: cstring) =
        
            if status == 200:
                
                var movement_combos = parseJson($resp).mapIt(it.to(MovementCombo))

                for mc in movement_combos:
                    
                    var new_movement_combo_request = %*MovementComboGroup(
                        movement_combo: mc,
                        movements: movements
                    )

                    ajaxPost($CreateMovementComboAssignment, headers = @[], data = $new_movement_combo_request, proc (status: int, resp: cstring) =
                    
                        if status == 200:
                            echo "response successful"
                    
                    )

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

proc logout() =
    current_user = User(kind: New, name: "not logged in", email: "")
    switchTo(Login)

proc readRoutine() =
    ajaxPost(ReadActiveRoutine, headers = @[], data = $(%*current_user), proc (status: int, resp: cstring) =

        if status == 200:

            echo "active routine: ", $resp

            for r in ($resp).parseJson:

                current_routine = r.to(Routine).add_any_new_to(current_routine)
    )

proc readRoutineAssignments() =
    ajaxPost(ReadRoutineAssignments, headers = @[], data = $(%current_routine[0]), proc (status: int, resp: cstring) =
            
        if status == 200:
            echo "readRoutineassignment response: ", $resp

            for mc in ($resp).parseJson:
                routine_movement_combos = mc.to(MovementComboGroup).add_any_new_to(routine_movement_combos)
    )

proc add_movement_combo_option() =
    new_movement_combo_count += 1

proc add_movement_combo_to_existing_routine() =
    routine_movement_combos.add(
        MovementComboGroup()
    )

proc add_movement(movement_combo_index: int) =
    routine_movement_combos[movement_combo_index].movements = routine_movement_combos[movement_combo_index].movements.concat(@[Movement(kind: New)])

proc render(): VNode =
    
    if window.location.pathname == "/index.html" or window.location.pathname == "":
        result = 
            buildHtml():
                tdiv:
                    header(class = $StatusSpanHeader):
                        tdiv(class = "pb2" & " pt0" & $StatusSpanHeader):
                            span(class = $StatusSpanHeader):
                                tdiv(class = "cf"):
                                    if current_user.email.len == 0:
                                        tdiv(class = "fl w-50"):
                                            text "Currently not logged in."
                                    else:
                                        tdiv(class = "fl w-50"):
                                            text "Logged in as " & current_user.name
                                        tdiv(class = "fr tr w-50"):
                                            a(onclick = () => logout()):
                                                text "(Logout)"

                    case pageMode:
                        of Login:
                            span(class = "w-100 ph2 tc m5"):      
                                for user in all_users:
                                    a(class = "br-pill ph2 m10 pv2 center bg-blue b--black-10", onclick = () => login(user)):
                                        text user.name

                        of UserMainPage:

                            createSpan(span = AttentionSpan, header = AttentionHeader, padding = 3, message = "Welcome, " & current_user.name)
                        
                            tdiv(class = "cf w-100"):
                                a(class = "avenir fl tc m2 ph2 pv4 white bg-blue w-100 w-third-ns", onclick = () => switchTo(ShowRoutines, @[readRoutine])):
                                    text "Check out sessions"

                                a(class = "avenir fl tc m2 ph2 pv4 white bg-light-red w-100 w-third-ns", onclick = () => switchTo(ManageMovements, @[readAllMovements])):
                                    text "Look at Exercise Options"

                                a(class = "avenir fl tc m2 ph2 pv4 white bg-red w-100 w-third-ns", onclick = () => switchTo(ManageMovementCombos, @[readAllMovements])):
                                    text "Add Movement Combo"

                        of ShowRoutines:

                            createSpan(span = AttentionSpan, header = AttentionHeader, padding = 3, message = "Click any routine to start a new session")

                            for cr in current_routine:
                                tdiv(class = "cf w-100"):
                                    a(class = "avenir fl tl m2 ph2 pv4 white bg-blue w-100 w-third-ns"):
                                        h2(onclick = () => switchTo(Workout, @[readRoutineAssignments])):
                                            text cr.name
                                        a(class = "avenir fl tl m2 ph2 pv4 white-red w-100 w-third-ns", onclick = () => switchTo(Workout, @[readRoutineAssignments, readAllMovementCombos])):
                                            text "Start new session"
                                        a(class = "avenir fl tl m2 ph2 pv4 white w-100 w-third-ns", onclick = () => switchTo(EditRoutine, @[readRoutineAssignments, readAllMovementCombos, readAllMovements])):
                                            text "Edit"

                        of EditRoutine:
                            for cr in current_routine:
                                h3(class = "avenir"):
                                    text "Editing " & cr.name

                                for index, movement_combo_group in routine_movement_combos:
                                    # if this is a new movement combo
                                    br()
                                    input(class = "avenir pv2 mv4", value=movement_combo_group.movement_combo.name)
                                    
                                    for idx, movement in movement_combo_group.movements:
                                        optionsMenu(name = ("movement_combo_movement_number_" & $idx),
                                            message = movement.name, options = all_movements.mapIt(it.name))
                                            
                                    br()
                                    a(class = $BigBlueButton & " avenir tc", onclick = () => add_movement(index)):
                                        text "Add Movement"
                                a(class = $BigBlueButton & " avenir tc", onclick = () => add_movement_combo_to_existing_routine()):
                                    text "Add Movement Combo"
                                a(class = $BigGreenButton & " avenir tc", onclick = () => createMovementCombo()):
                                    text "Save Changes to This Routine"

                            
                            # # nested movement combos - arrays sorted by sharing a common movement combo
                            # for movement_combo in all_movement_combos:
                            #     optionsMenu(name = "movement_combo", message = "click to change movement combo", options = movement_combo.movements.mapIt(it.name))

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


                        of ManageMovementCombos:

                            createSpan(span = AttentionSpan, header = DirectiveHeader, padding = 2, message = "Add Movement Combo")
                            input(id = "movement_combo_name", value="", placeholder="Movement Combo Name")

                            for m in 0..new_movement_combo_count:
                                optionsMenu(name = ("movement_combo_movement_number_" & $m), message = "choose movement combo", options = all_movements.mapIt(it.name))
                            br()
                            a(class = $BigBlueButton & " avenir tc", onclick = () => add_movement_combo_option()):
                                text "Add Movement"
                            a(class = $BigGreenButton & " avenir tc", onclick = () => createMovementCombo()):
                                text "Submit Movement Combo"

                        of Workout:
                            
                            if routine_movement_combos.len > 0:
                                var
                                    current_movement = routine_movement_combos[finished_groups].movements[finished_sets mod routine_movement_combos[finished_groups].movements.len]   
                                    set = WorkoutSet(
                                        movement: current_movement,
                                        movement_combo: routine_movement_combos[finished_groups].movement_combo,
                                        reps: 0,
                                        tempo: "1-0-1-0",
                                        intensity: Intensity(
                                            quantity: 5,
                                            units: Pounds
                                        ),
                                        session: current_session,
                                        set_order: 1
                                    )

                                for r in current_routine:
                                    createSpan(span = AttentionSpan, header = DirectiveHeader, padding = 4, message = fmt"Performing: {r.name}")
                                    createSpan(span = InformationSpan, header = AttentionHeader, padding = 2, message = "Right now, do:")
                                    header(class = "tc"):
                                        h1(class = $AttentionHeader & " pb2"):
                                            text set.movement.name
                                        input(type = "range", id = "repsInputId", value=($set.reps), min = "0", max = "30", oninput = repsSliderToOutput, class = "tl pl2")
                                        output(id = "repsOutputId", class="pl3 avenir tr"):
                                            text $set.reps & " reps ?"
                                        h1(class = $AttentionHeader):
                                            a(class = $BigGreenButton & " avenir tc", onclick = () => next_movement()):
                                                text "Done Set"
                            # br()
                            # createSpan(span = AttentionSpan, header = DirectiveHeader, padding = 2, message = "This workout so far:")
                            # tdiv(class = "bg-green avenir"):
                            #     table(class = "f6 ph3 mt0 underline center"):
                            #         thead:
                            #             tr(class = "stripe-dark"):
                            #                 th(class = "fw6 tl pa3 bg-green tl"):
                            #                     text "Exercise"
                            #                 th(class = "fw6 tl pa3 bg-green tr"):
                            #                     text "Sets"
                            #         tbody(class = "lh-copy"):
                            #             tr(class = "stripe-dark"):
                            #                 td(class = "pa3 tl tl"):
                            #                     text "Split Squat"
                            #                 td(class = "pa3 tl tr"):
                            #                     text "1, 5, 3"
                            #             tr(class = "stripe-light"):
                            #                 td(class = "pa3 tl"):
                            #                     text "Pull Up"
                            #                 td(class = "pa3 tl"):
                            #                     text "4, 2, 1"

                            h1(class = "tc"):
                                a(class = $BigBlueButton & " avenir tc pb3"):
                                    text "Done Combo"

                    if not (pageMode == UserMainPage) and current_user.email.len > 0:
                        br()
                        footer(class = $ReverseSpan & " avenir tl mt3 pt2 pb2", onclick = () => switchTo(UserMainPage)):
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