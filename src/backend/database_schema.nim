import times, db_sqlite
import json
import allographer/schema_builder
import allographer/query_builder
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

    # now add to db
    schema([
        table("movement", movement_table),
        table("movement_combo", movement_combo_table),
        table("movement_combo_assignment", movement_combo_assignment_table)
    ])