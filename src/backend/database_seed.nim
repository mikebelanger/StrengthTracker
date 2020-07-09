import allographer/query_builder
import ../app_types
import json, strutils, sequtils
import crud

let
    movements = @[

        ### Horizontal Upper Body
        Movement(
            name: "Push-up",
            area: Upper,
            symmetry: Bilateral,
            concentric_type: Push,
            plane: Horizontal,
            description: "Hands chest-width apart.  Elbows tucked in."
        ),
        Movement(
            name: "Ring Row",
            area: Upper,
            symmetry: Bilateral,
            concentric_type: Pull,
            plane: Horizontal,
            description: "Rings chest-width apart.  Straps hanging 30inches apart"
        ),
        Movement(
            name: "Bench Press",
            area: Upper,
            symmetry: Bilateral,
            concentric_type: Push,
            plane: Horizontal,
            description: "For maximum bro-ness."
        ),
        
        Movement(
            name: "Ring Dip",
            area: Upper,
            symmetry: Bilateral,
            concentric_type: Push,
            plane: Vertical,
            description: "Straps 18 inches apart, hanging 26 inches from bar"
        ),

        Movement(
            name: "Ring Pullup",
            area: Upper,
            symmetry: Bilateral,
            concentric_type: Pull,
            plane: Vertical,
            description: "Straps 28 inches apart, hanging 6 inches from the bar."
        ),

        Movement(
            name: "Bulgarian Split Squat",
            area: Lower,
            symmetry: Unilateral,
            concentric_type: Squat,
            plane: Frontal,
            description: "Back foot resting on black PVC pipe.  Pipe is sitting on top of rack, two notches up from bottom."
        ),

        Movement(
            name: "One-armed Kettlebell Swing",
            area: Lower,
            symmetry: Unilateral,
            concentric_type: Hinge,
            plane: Frontal,
        ),

        Movement(
            name: "Barbell Snatch",
            area: Full,
            symmetry: Bilateral,
            concentric_type: Pull,
            plane: MultiPlane
        ),

        Movement(
            name: "Side Lunge Squat",
            area: Lower,
            symmetry: Unilateral,
            concentric_type: Squat,
            plane: Lateral
        )
    ]



if isMainModule:

    var movement_table = RDB().table($MovementTable)

    movement_table.insert(
        movements.filterIt(it.is_complete).mapIt(%*it)
    )