import db_sqlite
import allographer/schema_builder
import sequtils, strutils

const forbidden = @[
    "id"
    ]

proc is_permitted*(key: string): bool =

    result = forbidden.allIt(not key.contains(it))

proc get_permitted_params(columns: openArray[Column]): seq[string] = 

    result = columns.filterIt(it.name.is_permitted)
                    .mapIt(it.name)

let

    movement_table = [
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

    # derive permitted params from table, filtering out sensitive param names
    movement_params* = movement_table.get_permitted_params
    movement_combo_params* = movement_combo_table.get_permitted_params
    movement_combo_assignment_params* = movement_combo_assignment_table

if isMainModule:

    # now add to db
    schema([
        table("movement", movement_table),
        table("movement_combo", movement_combo_table),
        table("movement_combo_assignment", movement_combo_assignment_table)
    ])