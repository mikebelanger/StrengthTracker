import db_sqlite
import allographer/schema_builder

type
    DataTable* = enum
        UserTable = "user"
        MovementTable = "movement"
        MovementComboTable = "movement_combo"
        MovementComboAssignmentTable = "movement_combo_assignment"
        IntensityTable = "intensity"
        RoutineTable = "routine"
        SessionTable = "session"
        SetTable = "set"

let
    user_table = [
        Column().increments("id"),
        Column().string("name").unique(),
        Column().string("email").unique()
    ]
    movement_table = [
        Column().increments("id"),
        Column().string("name").unique(),
        Column().string("area"),
        Column().string("concentric_type"),
        Column().string("symmetry"),
        Column().string("plane"),
        Column().longText("description")
    ]

    movement_combo_table = [
        Column().increments("id"),
        Column().string("name").unique()
    ]

    movement_combo_assignment_table = [
        Column().increments("id"),
        Column().foreign("movement_id").reference("id").on("movement_combo").onDelete(SET_NULL),
        Column().foreign("movement_combo_id").reference("id").on("movement_combo").onDelete(SET_NULL)
    ]

if isMainModule:


    # # now add to db
    schema([
        table($UserTable, movement_table),
        table($MovementTable, movement_table),
        table($MovementComboTable, movement_combo_table),
        table($MovementComboAssignmentTable, movement_combo_assignment_table)
    ])