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

    intensity_table = [
        Column().increments("id"),
        Column().float("quantity"),
        Column().string("units")
    ]

    routine_table = [
        Column().increments("id"),
        Column().string("name").unique(),
        Column().foreign("user_id").reference("id").on("user").onDelete(SET_NULL)
    ]

    session_table = [
        Column().increments("id"),
        Column().foreign("routine_id").reference("id").on("routine").onDelete(SET_NULL),
        Column().datetime("session_date")
    ]

    set_table = [
        Column().increments("id"),
        Column().foreign("movement_id").reference("id").on("movement"),
        Column().foreign("movement_combo_id").reference("id").on("movement_combo"),
        Column().integer("reps"),
        Column().string("tempo"),
        Column().foreign("intensity_id").reference("id").on("intensity").onDelete(SET_NULL),
        Column().foreign("session_id").reference("id").on("session").onDelete(SET_NULL),
        Column().timestamp("duration"),
        Column().integer("order")
    ]

if isMainModule:

    # # now add to db
    schema([
        table($UserTable, user_table),
        table($MovementTable, movement_table),
        table($MovementComboTable, movement_combo_table),
        table($MovementComboAssignmentTable, movement_combo_assignment_table),
        table($IntensityTable, intensity_table),
        table($RoutineTable, routine_table),
        table($SessionTable, session_table),
        table($SetTable, set_table)
    ])