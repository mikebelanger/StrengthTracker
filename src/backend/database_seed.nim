import allographer/query_builder
import ../app_types, database_schema
import json, strutils, sequtils
import crud

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
    users = [
        User(
            kind: New,
            name: "Mike",
            email: "mikejamesbelanger@gmail.com"
        )
    ]

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

    movement_combo = MovementCombo(
        kind: New,
        name: "Pull-up + Split Squat Combo"
    )

    # assignments = [
    #     MovementComboAssignment(
    #         kind: New,
    #         movement_combo: movement_combo,
    #         movement: ring_pullup
    #     ),

    #     MovementComboAssignment(
    #         kind: New,
    #         movement_combo: movement_combo,
    #         movement: split_squat
    #     )
    # ]


if isMainModule:

    var movement_table = RDB().table($MovementTable)

    movement_table.insert(
        movements.mapIt(it.to_json)
    )

        # echo ring_pullup, split_squat

        # for assi in assignments:
        #     discard assi.db_create


    
    # for u in users:
    #     discard u.db_create