import db_sqlite
import allographer/schema_builder
import sequtils, strutils
import json
import ../app_types

const 
    forbidden = @[
    "id"
    ]

    always_unique = @[
        "name"
    ]

type
    DbRelation = enum
        UniqueTableColumnString
        TableColumnString
        TableColumnInteger
        ForeignKey

func determine_relation(input: string): DbRelation =
    if always_unique.contains(input):
        UniqueTableColumnString
    else:
        TableColumnString

func determine_relation(input: int): DbRelation =
    TableColumnInteger

func determine_relation(input: Movement | MovementCombo): DbRelation =
    ForeignKey

func is_forbidden(key: string): bool =

    result = forbidden.anyIt(key.contains(it))


func get_permitted_params(columns: openArray[Column]): seq[Column] = 

    result = columns.filterIt(not it.name.is_forbidden)


func create_column_array(o: object): seq[Column] =
    result.add(Column().increments("id"))

    for key, val in o.fieldPairs:

        case val.determine_relation:

            of TableColumnString:
                result.add(Column().string(key))

            of UniqueTableColumnString:
                result.add(Column().string(key).unique())

            of TableColumnInteger:
                result.add(Column().integer(key))
            
            of ForeignKey:
                result.add(Column()
                      .foreign(key & "_id")
                      .reference("id")
                      .on(key)
                      .onDelete(SET_NULL)
                )
            

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
    movement_params = movement_table.get_permitted_params
    movement_combo_params = movement_combo_table.get_permitted_params
    movement_combo_assignment_params = movement_combo_assignment_table.get_permitted_params

    all_params* = concat(movement_params, movement_combo_params, movement_combo_assignment_params).mapIt(it.name)
if isMainModule:


    # # now add to db
    schema([
        table("movement", movement_table),
        table("movement_combo", movement_combo_table),
        table("movement_combo_assignment", movement_combo_assignment_table)
    ])