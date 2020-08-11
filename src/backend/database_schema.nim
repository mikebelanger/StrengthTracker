import db_sqlite
import allographer/schema_builder

type
    DataTable* = enum
        UserTable = "user"
        MovementTable = "movement"
        MovementComboTable = "movement_combo"
        MovementComboAssignmentTable = "movement_combo_assignment"
        RoutineTable = "routine"
        WorkoutSetTable = "workout_set"

converter datatable_to_string(d: DataTable): string =
    return $d

proc id*(d: DataTable): string =
    return d & "_id"

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
        Column().foreign(MovementTable.id).reference("id").on(MovementTable).onDelete(SET_NULL),
        Column().foreign(MovementComboTable.id).reference("id").on(MovementComboTable).onDelete(SET_NULL),
        Column().foreign(RoutineTable.id).reference("id").on(RoutineTable).onDelete(SET_NULL)
    ]

    routine_table = [
        Column().increments("id"),
        Column().string("name").unique(),
        Column().boolean("active"),
        Column().foreign(UserTable.id).reference("id").on(UserTable).onDelete(SET_NULL)
    ]

    workout_set_table = [
        Column().increments("id"),
        Column().foreign(MovementTable.id).reference("id").on(MovementTable),
        Column().foreign(MovementComboTable.id).reference("id").on(MovementComboTable),
        Column().foreign(RoutineTable.id).reference("id").on(RoutineTable),
        Column().integer("reps"),
        Column().string("tempo"),
        Column().float("intensity"),
        Column().string("intensity_units"),
        Column().integer("duration_in_minutes"),
        Column().integer("start_duration"),
        Column().integer("eccentric_duration"),
        Column().integer("end_duration"),
        Column().integer("concentric_duration"),
        Column().integer("set_order"),
        Column().integer("routine_order"),
        Column().datetime("set_date")
    ]

if isMainModule:

    # # # now add to db
    schema([
        table(UserTable, user_table),
        table(MovementTable, movement_table),
        table(MovementComboTable, movement_combo_table),
        table(MovementComboAssignmentTable, movement_combo_assignment_table),
        table(RoutineTable, routine_table),
        table(WorkoutSetTable, workout_set_table)
    ])