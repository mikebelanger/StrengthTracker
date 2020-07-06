import allographer/query_builder
import ../app_types
import json, strutils, sequtils

proc is_complete*(x: object): bool =

    for key, val in x.fieldPairs:

        var value = $val
        if value.len == 0 or value.contains("Unspecified"):
            return false

    return true

const
    movements = @[

        ### Horizontal Upper Body
        Movement(
            name: "Push-up",
            area: Upper,
            symmetry: Bilateral,
            concentric_type: Push,
            plane: Horizontal
        ),
        Movement(
            name: "Ring Row",
            area: Upper,
            symmetry: Bilateral,
            concentric_type: Pull,
            plane: Horizontal
        ),
        Movement(
            name: "Bench Press",
            area: Upper,
            symmetry: Bilateral,
            concentric_type: Push,
            plane: Horizontal
        ),
        
        Movement(
            name: "Ring Dip",
            area: Upper,
            symmetry: Bilateral,
            concentric_type: Push,
            plane: Vertical
        ),

        Movement(
            name: "Ring Pullup",
            area: Upper,
            symmetry: Bilateral,
            concentric_type: Pull,
            plane: Vertical
        ),

        Movement(
            name: "Bulgarian Split Squat",
            area: Lower,
            symmetry: Unilateral,
            concentric_type: Squat,
            plane: Frontal
        ),

        Movement(
            name: "One-armed Kettlebell Swing",
            area: Lower,
            symmetry: Unilateral,
            concentric_type: Hinge,
            plane: Frontal
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