import ../app_types, database_schema
import allographer/query_builder
import json, strutils, sequtils
import crud, times

let
    movements = @[

        ### Horizontal Upper Body
        Movement(
            kind: New,
            name: "Push-up",
            area: Upper,
            symmetry: Bilateral,
            concentric_type: Push,
            plane: Horizontal,
            description: "Hands chest-width apart.  Elbows tucked in."
        ),
        Movement(
            kind: New,
            name: "Ring Row",
            area: Upper,
            symmetry: Bilateral,
            concentric_type: Pull,
            plane: Horizontal,
            description: "Rings chest-width apart.  Straps hanging 30inches apart"
        ),
        Movement(
            kind: New,
            name: "Bench Press",
            area: Upper,
            symmetry: Bilateral,
            concentric_type: Push,
            plane: Horizontal,
            description: "For maximum bro-ness."
        ),
        
        Movement(
            kind: New,
            name: "Ring Dip",
            area: Upper,
            symmetry: Bilateral,
            concentric_type: Push,
            plane: Vertical,
            description: "Straps 18 inches apart, hanging 26 inches from bar"
        ),

        Movement(
            kind: New,
            name: "One-armed Kettlebell Swing",
            area: Lower,
            symmetry: Unilateral,
            concentric_type: Hinge,
            plane: Frontal,
        ),

        Movement(
            kind: New,
            name: "Barbell Snatch",
            area: Full,
            symmetry: Bilateral,
            concentric_type: Pull,
            plane: MultiPlane
        ),

        Movement(
            kind: New,
            name: "Side Lunge Squat",
            area: Lower,
            symmetry: Unilateral,
            concentric_type: Squat,
            plane: Lateral
        )
    ]

    #### Users
    mike = """
    {"kind": "New",
    "name": "Mike",
    "email": "mikejamesbelanger@gmail.com"
    }
    """

    ring_pullup = Movement(
        kind: New,
        name: "Ring Pullup",
        area: Upper,
        symmetry: Bilateral,
        concentric_type: Pull,
        plane: Vertical,
        description: "Straps 28 inches apart, hanging 6 inches from the bar."
    )

    split_squat = Movement(
        kind: New,
        name: "Bulgarian Split Squat",
        area: Lower,
        symmetry: Unilateral,
        concentric_type: Squat,
        plane: Frontal,
        description: "Back foot resting on black PVC pipe.  Pipe is sitting on top of rack, two notches up from bottom."
    )


    x = """
    { "stuf : erger' }
    """

    bad = """
    { erg\
    """

    stupid = """
    { "name" : "my fantastic movement" }
    """

    sort_of_ok = """
    { "name" : "push-up",
        "plane" : "Horizontal",
        "concentric_type" : "Push", 
        "area" : "Upper",
        "symmetry" : "Binaugural"
    }
    """

    should_work = """
    { "name" : "Kettlebell Step Up",
        "plane" : "Vertical",
        "concentric_type" : "Squat", 
        "area" : "Upper",
        "symmetry" : "Bilateral",
        "description" : "on the floor"
    }
    """

    should_work_updated = """
    { "id" : 1,
        "name" : "Kettlebell Step Up WITH FIRE",
        "plane" : "Vertical",
        "concentric_type" : "Squat", 
        "area" : "Upper",
        "symmetry" : "Bilateral",
        "description" : "stepping on a flaming brick"
    }
    """

    should_work_updated_wrong = """
    { "id" : 1,
        "name" : "Kettlebell Step Up WITH FIRE",
        "plane" : "Blah",
        "concentric_type" : "Squat", 
        "area" : "Upper",
        "symmetry" : "Bilateral",
        "description" : "stepping on a flaming brick"
    }
    """

    movement_combo = """
        { "name" : "some_new_combo" }
    """

    movement_combo_assignment = """
        { "movement": { "id" : 1,
                        "kind" : "Existing",
                        "name" : "Kettlebell Step Up WITH FIRE",
                        "plane" : "Vertical",
                        "concentric_type" : "Squat", 
                        "area" : "Upper",
                        "symmetry" : "Bilateral",
                        "description" : "stepping on a flaming brick" },
            "movement_combo" : { "id" : 1,
                                "kind": "Existing",
                                "name" : "some_new_combo"
                                }
        }
    """

    routine = """
        { "kind" : "New",
          "name" : "Mikes current routine - strength",
          "active" : true,
          "user" : {
                    "kind" : "Existing",
                    "id" : 1,
                    "name": "Mike",
                    "email": "mikejamesbelanger@gmail.com"
                    }
        }

    """

# stupid, yes. but for the sake of simulating incoming serialized data, this converter makes sense
converter obj_to_jstr(o: object): string =
    $(%*o)

if isMainModule:
    # echo @[movement_combo_assignment.parseJson].into(New, MovementComboAssignment)
    # echo session
    # echo session.to_json
    # echo $session.to_json
    # echo ($session.to_json).interpretJson
    # echo (%*session).to(Session)

    let mike_try = mike.db_create(User, into = UserTable)
    echo "user", mike_try, mike_try.len

    let routine_try = routine.db_create(Routine, into = RoutineTable)
    echo "routine try: ", routine_try, routine_try.len 


    let sort_of = sort_of_ok.db_create(Movement, into = MovementTable)
    echo "sort_of", sort_of, sort_of.len

    let new_movement = should_work.db_create(Movement, into = MovementTable)
    echo "movement", new_movement, new_movement.len

    let updated_movement = should_work_updated.db_update(Movement, into = MovementTable)
    echo "updated movement: ", updated_movement, updated_movement.len

    let updated_movement_wrong = should_work_updated_wrong.db_update(Movement, into = MovementTable)

    echo "updated movement wrong: ", updated_movement_wrong, updated_movement_wrong.len

    let movement_combo_obj = movement_combo.db_create(MovementCombo, into = MovementComboTable)
    echo "movement combo: ", movement_combo_obj

    let mca_as = movement_combo_assignment.db_create(MovementComboAssignment, into = MovementComboAssignmentTable)
    echo "movement combo assignment: ", mca_as

    let routine_combo_assignment = RoutineAssignment(
        movement_combo: movement_combo_obj[0],
        routine: routine_try[0],
        routine_order: 1
    )

    let routine_created = routine_combo_assignment.db_create(RoutineAssignment, into = RoutineAssignmentTable)

    for r in routine_created:
        echo "routine assignment: ", r

    let session = Session(
        kind: New,
        routine: routine_try[0]
    )

    let ser_session = %*session
    ser_session{"session_date"}= %now().strftime
    echo "ser session", ser_session
    let session_try = ($ser_session).db_create(Session, into = SessionTable)
    echo "session try: ", session_try, session_try.len


    for m in movements:
        echo m.db_create(Movement, into = MovementTable)

    echo "made it to end of thing"

    let intensity = Intensity(
        quantity: 32.00,
        units: Pounds
    )

    let intensity_created = intensity.db_create(Intensity, into = IntensityTable)

    echo intensity_created

    for index, movement in updated_movement:

        echo "movement: ", movement
        echo movement_combo_obj, intensity_created, session_try

        let new_set = WorkoutSet(
            movement: movement,
            movement_combo: movement_combo_obj[index],
            reps: 4,
            tempo: "3-0-5-0",
            intensity: intensity_created[index],
            session: session_try[index],
            duration_in_minutes: 10,
            set_order: 2
        )

        echo new_set.db_create(WorkoutSet, into = WorkoutsetTable)