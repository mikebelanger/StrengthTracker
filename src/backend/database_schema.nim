import db_sqlite
import allographer/schema_builder
import ../app_types

let

    movement_table* = [
        Column().increments("id"),
        Column().string("name").unique(),
        Column().string("area"),
        Column().string("concentric_type"),
        Column().string("symmetry"),
        Column().string("plane")
    ]

    movement_combo_table* = [
        Column().increments("id"),
        Column().string("name").unique()
    ]

    movement_combo_assignment_table* = [
        Column().increments("id"),
        Column().foreign("movement_id").reference("id").on("movement_combo").onDelete(SET_NULL),
        Column().foreign("movement_combo_id").reference("id").on("movement_combo").onDelete(SET_NULL)
    ]

if isMainModule:


    # # now add to db
    schema([
        table($Movement, movement_table),
        table($MovementCombo, movement_combo_table),
        table($MovementComboAssignment, movement_combo_assignment_table)
    ])