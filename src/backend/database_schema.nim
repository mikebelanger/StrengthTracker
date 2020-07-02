import db_sqlite
import allographer/schema_builder
import sequtils, strutils
import json

type

    Movement* = object
        name*: string
        area*: string
        concentric_type*: string
        symmetry*: string
        plane*: string

    MovementCombo* = object
        name*: string

    MovementComboAssignment* = object
        movement_id*: int
        movement_combo_id*: int

const 
    forbidden = @[
    "id"
    ]

    always_unique = @[
        "name"
    ]

proc is_permitted*(key: string): bool =

    result = forbidden.allIt(not key.contains(it))


proc get_permitted_params(columns: openArray[Column]): seq[Column] = 

    result = columns.filterIt(it.name.is_permitted)


proc create_column_array(o: object): seq[Column] =
    result.add(Column().increments("id"))

    for key, val in o.fieldPairs:

        if always_unique.anyIt(it == key):
            result.add(Column().string(key).unique())

        elif typeof(val) is int and key.contains("_id"):
            result.add(Column().foreign(key)
                               .reference("id")
                               .on(key.replace("_id", ""))
                               .onDelete(SET_NULL)
                               )
        
        elif typeof(val) is int:
            result.add(Column().integer(key))
        
        elif typeof(val) is string:
            result.add(Column().string(key))
            

        


let

    # movement_table = [
    #     Column().increments("id"),
    #     Column().string("name").unique(),
    #     Column().string("area"),
    #     Column().string("concentric_type"),
    #     Column().string("symmetry"),
    #     Column().string("plane")
    # ]

    # movement_combo_table = [
    #     Column().increments("id"),
    #     Column().string("name").unique()
    # ]

    # movement_combo_assignment_table = [
    #     Column().increments("id"),
    #     Column().foreign("movement_id").reference("id").on("movement_combo").onDelete(SET_NULL),
    #     Column().foreign("movement_combo_id").reference("id").on("movement_combo").onDelete(SET_NULL)
    # ]

    ### Movement
    movement_table = Movement().create_column_array

    ### MovementCombo
    movement_combo_table = MovementCombo().create_column_array

    ### MovementComboAssignment
    movement_combo_assignment_table = MovementComboAssignment().create_column_array


    # derive permitted params from table, filtering out sensitive param names
    movement_params* = movement_table.get_permitted_params
    movement_combo_params* = movement_combo_table.get_permitted_params
    movement_combo_assignment_params* = movement_combo_assignment_table.get_permitted_params

if isMainModule:


    # # now add to db
    schema([
        table("movement", movement_table),
        table("movement_combo", movement_combo_table),
        table("movement_combo_assignment", movement_combo_assignment_table)
    ])