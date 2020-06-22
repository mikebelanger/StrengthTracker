import times, db_sqlite
import json
import allographer/schema_builder
import allographer/query_builder
import ../app_types

# quick way of populating database with enum types
template add_enum_types_to_table*(table_name: string, input_enum: untyped) =    
    # loop through each enumeration as a separate row entry to table_name
    for enumerated_state in input_enum.low .. input_enum.high:
        RDB().table(table_name).insert(%*{"name": $enumerated_state})


let
    movement_plane_table = [
        Column().increments("id"),
        Column().string("name").unique()
    ]

    body_area_table = [
        Column().increments("id"),
        Column().string("name").unique()
    ]

    movement_type_table = [
        Column().increments("id"),
        Column().string("name").unique()
    ]

    movement_category_table = [
        Column().increments("id"),
        Column().string("name").unique()
    ]

    movement_table* = [
        Column().increments("id"),
        Column().string("name").unique(),
        Column().foreign("body_area_id").reference("id").on("body").onDelete(SET_NULL),
        Column().foreign("movement_type_id").reference("id").on("body").onDelete(SET_NULL),
        Column().foreign("movement_category_id").reference("id").on("movement_category").onDelete(SET_NULL),
        Column().foreign("movement_plane_id").reference("id").on("movement_plane").onDelete(SET_NULL)
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
        table("movement_plane", movement_plane_table),
        table("body_area", body_area_table),
        table("movement_type", movement_type_table),
        table("movement_category", movement_category_table),
        table("movement", movement_table),
        table("movement_combo", movement_combo_table),
        table("movement_combo_assignment", movement_combo_assignment_table)
    ])


        # add_enum_types_to_table(table_name = "movement_plane", input_enum = MovementPlane)
    add_enum_types_to_table(table_name = "body_area", input_enum = BodyArea)
    add_enum_types_to_table(table_name = "movement_type", input_enum = MovementType)
    add_enum_types_to_table(table_name = "movement_category", input_enum = MovementCategory)
    add_enum_types_to_table(table_name = "movement_plane", input_enum = MovementPlane)

