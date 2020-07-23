import db_sqlite
import allographer/schema_builder
import sequtils

type
    DataTable* = enum
        UserTable = "user"
        MovementTable = "movement"
        MovementComboTable = "movement_combo"
        MovementComboAssignmentTable = "movement_combo_assignment"
        RoutineAssignmentTable = "routine_assignment"
        IntensityTable = "intensity"
        RoutineTable = "routine"
        SessionTable = "session"
        WorkoutSetTable = "workout_set"

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
        Column().string("name").unique(),
    ]

    movement_combo_assignment_table = [
        Column().increments("id"),
        Column().foreign("movement_id").reference("id").on($MovementTable).onDelete(SET_NULL),
        Column().foreign("movement_combo_id").reference("id").on($MovementComboTable).onDelete(SET_NULL),
        Column().foreign("routine_id").reference("id").on($RoutineTable).onDelete(SET_NULL)
    ]

    routine_table = [
        Column().increments("id"),
        Column().string("name").unique(),
        Column().boolean("active"),
        Column().foreign("user_id").reference("id").on($UserTable).onDelete(SET_NULL)
    ]

    session_table = [
        Column().increments("id"),
        Column().foreign("routine_id").reference("id").on($RoutineTable).onDelete(SET_NULL),
        Column().datetime("session_date")
    ]

    routine_assignment_table = [
        Column().increments("id"),
        Column().foreign("movement_combo_id").reference("id").on($MovementComboTable).onDelete(SET_NULL),
        Column().foreign("routine_id").reference("id").on($RoutineTable).onDelete(SET_NULL),
        Column().integer("routine_order")
    ]

    intensity_table = [
        Column().increments("id"),
        Column().float("quantity"),
        Column().string("units")
    ]

    set_table = [
        Column().increments("id"),
        Column().foreign("movement_id").reference("id").on("movement"),
        Column().foreign("movement_combo_id").reference("id").on("movement_combo"),
        Column().integer("reps"),
        Column().string("tempo"),
        Column().foreign("intensity_id").reference("id").on("intensity").onDelete(SET_NULL),
        Column().foreign("session_id").reference("id").on("session").onDelete(SET_NULL),
        Column().integer("duration_in_minutes"),
        Column().integer("set_order")
    ]

if isMainModule:

    # # now add to db
    schema([
        table($UserTable, user_table),
        table($MovementTable, movement_table),
        table($MovementComboTable, movement_combo_table),
        table($MovementComboAssignmentTable, movement_combo_assignment_table),
        table($RoutineTable, routine_table),
        table($RoutineAssignmentTable, routine_assignment_table),
        table($IntensityTable, intensity_table),
        table($SessionTable, session_table),
        table($WorkoutSetTable, set_table)
    ])