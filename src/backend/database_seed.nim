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
          "user" : {
                    "kind" : "Existing",
                    "id" : 1,
                    "name": "Mike",
                    "email": "mikejamesbelanger@gmail.com"
                    }
        }

    """

    session = Session(
        kind: New,
        date: now().to_Date,
        routine: routine.parseJson.to(Routine)
    )

if isMainModule:
    # echo session
    # echo session.to_json
    # echo $session.to_json
    # echo ($session.to_json).interpretJson
    # echo (%*session).to(Session)

    let mike_try = mike.db_create(User, into = UserTable)
    echo "user", mike_try, mike_try.len

    let routine_try = routine.db_create(Routine, into = RoutineTable)
    echo "routine try: ", routine_try, routine_try.len 

    let session_try = ($session).db_create(Session, into = SessionTable)
    echo "session try: ", session_try, session_try.len

    let sort_of = sort_of_ok.db_create(Movement, into = MovementTable)
    echo "sort_of", sort_of, sort_of.len

    let new_movement = should_work.db_create(Movement, into = MovementTable)
    echo "movement", new_movement, new_movement.len

    let updated_movement = should_work_updated.db_update(Movement, into = MovementTable)
    echo "updated movement: ", updated_movement, updated_movement.len

    let updated_movement_wrong = should_work_updated_wrong.db_update(Movement, into = MovementTable)

    echo "updated movement wrong: ", updated_movement_wrong, updated_movement_wrong.len

    echo "movement combo: ", movement_combo.db_create(MovementCombo, into = MovementComboTable)

    let mca_as = movement_combo_assignment
                                        .db_create(MovementComboAssignment, into = MovementComboAssignmentTable)
    echo "movement combo assignment: ", mca_as

    # echo "movement_combo_reformed: ", mca_as.map(proc(j: JsonNode): MovementComboAssignment =
    #                                                 result = 
    #                                                     MovementComboAssignment(kind: Existing,
    #                                                                             id: j{"id"}.getInt,
    #                                                                             movement: j{"movement_id"}.getInt.db_read_from_id(into = MovementTable)
    #                                                                                                             .to_existing(Movement),
    #                                                                             movement_combo: j{"movement_combo_id"}.getInt.db_read_from_id(into = MovementComboTable)
    #                                                                                                             .to_existing(MovementCombo)
    #                                                     )
    #                                             )

    # var movement_table = RDB().table($MovementTable)

    # movement_table.insert(
    #     movements.mapIt(it.to_json)
    # )