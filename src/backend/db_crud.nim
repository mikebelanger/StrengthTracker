import allographer/query_builder
import allographer/schema_builder
import ../app_types
import sequtils
import database_schema
import json

#################################
###### HELPERS / TEMPLATES ######
#################################

template safely_create(stmts: untyped) =

    try:
        stmts
    
    except:
        return CRUDObject(status: Error, error: getCurrentExceptionMsg())

    return CRUDObject(status: Complete, error: "")

proc filter_params(json_params: JsonNode): JsonNode =

    # I have to explicitely declare this json for some reason
    var result = parseJson("{}")

    for key in json_params.keys:

        if all_params.contains(key):
            var val = json_params{key}.getStr

            if val.len > 0:
                result{key}= %*val

    # for some reason, I have to explicitly return result here.  Otherwise its nil
    return result

proc convert_to*[T](input_params: JsonNode, t: typedesc[T]): T = 
    # ensure all input parameters are allowed before converting to an object
    var params = input_params.filter_params

    result = params.to(t)

proc db_read_id(table, matching: string, column = "name"): int =

    var query_results = RDB().table(table).select("id").where(column, "=", matching).get()

    for q in query_results:
        try:
            return q{"id"}.getInt
        except:
            return 0


proc db_read_id(m: Movement, matching: string): int =

    return db_read_id(table = "movement", matching = matching)


proc db_read_id(mc: MovementCombo, matching: string): int =

    return db_read_id(table = "movement_combo", matching = matching)


func exists(id: int): bool =
    return id > 0


proc add_any_foreign_keys(o: object, by: string): JsonNode =

    var result = parseJson("{}")

    for key, val in o.fieldPairs:
        
        case val.determine_relation:

            of ForeignKey:
            
                var id = val.db_read_id(matching = val.name)

                if id.exists:
                    
                    result{key & "_id"}= %*id

                else:
                    result{key & "_id"}= %*""

            else:

                result{key}= %*val

    return result
            

#####################
####### CREATE ######
#####################

proc db_create*(m: Movement, table = "movement"): CRUDObject =

    safely_create:
        RDB().table(table)
             .insert(%*m)


proc db_create*(movement_combo: MovementCombo, table = "movement_combo"): CRUDObject =

    safely_create:
        RDB().table(table)
             .insert(%*movement_combo)


proc db_create*(movement_combo_assignment: MovementComboAssignment, table = "movement_combo_assignment"): CRUDObject =
    
    safely_create:
        RDB().table(table)
             .insert(movement_combo_assignment.add_any_foreign_keys(by = "name"))


# #####################
# ####### READ ########
# #####################

proc db_read_any*[T](obj: T, table: string, matching = All): RDB =
    
    var table_conn = RDB().table(table)
    var columns: seq[string]

    # add all object attributes as columns to select
    for key, val in obj.fieldPairs:

        columns.add(key)

    table_conn.query["select"] = %*columns

    case matching:
        of All:

            # treat each json key-val pair as an AND condition with equals qualifier
            for key, val in obj.fieldPairs:
                
                if val.len > 0:
                    table_conn = table_conn.where(key, "=", val)

        of Any:
            
            # treat each json key-val pair as an AND condition with equals qualifier
            for key, val in obj.fieldPairs:
                
                if val.len > 0:
                    table_conn = table_conn.orWhere(key, "=", val)

    result = table_conn

proc db_read*(m: Movement, matching = All): seq[Movement] =

    m.db_read_any(table = "movement", matching = matching)
     .get().mapIt(it.to(m.typeof))

proc db_read_unique*(table, column_name: string): seq[string] =

    var table_conn = RDB().table(table).select(column_name)
    result = table_conn.distinct().get().mapIt(it.getOrDefault(key = column_name).getStr)

# #####################
# ####### UPDATE ######
# #####################

if isMainModule:

    var 
        some_json = parseJson("""
        {"name": "some_movement"}
        """)

        more_json = parseJson("""
        {
        "name": "chest-press",
        "area": "",
        "plane":"Vertical"
        }
        """)

        complete_json = parseJson("""
        {
        "name": "chest-press",
        "area": "Upper",
        "plane":"Vertical",
        "concentric_type": "Press",
        "symmetry": "Unilateral"
        }
        """)

        double_json = parseJson("""
        {
        "name": "bench press",
        "area":"Lower",
        "plane": "Horizontal",
        "concentric_type": "Press",
        "symmetry": "Unilateral"
        }
        """)

        pushup_json = parseJson("""
        {
        "name": "push up",
        "area": "Upper",
        "plane": "Horizontal",
        "concentric_type": "Press",
        "symmetry": "Bilateral"
        }
        """)

        query_json = parseJson("""
        {
        "name": "split-squat",
        "area": "Lower",
        "plane":"Frontal",
        "symmetry": "Bilateral",
        "concentric_type": "Squat",
        }
        """)

        split_a = parseJson("""
        {
        "name": "workout: a - split squat & push up"
        }
        """)

        pushup = pushup_json.convert_to(Movement)
        split_squat = query_json.convert_to(Movement)
        workout_split_a = split_a.convert_to(MovementCombo)
        mc_a = MovementComboAssignment(movement: pushup, movement_combo: workout_split_a)


    # echo pushup, split_squat, workout_split_a
    # echo pushup.db_create, split_squat.db_create, workout_split_a.db_create
    # echo mc_a.db_create
    echo @["name"].contains("name")
    # for m in @[pushup, split_squat]:
    #     MovementComboAssignment(movement: m, 
    #                             movement_combo: workout_split_a).db_create

    # echo more_json{"area"}.len
        # r1 = db_create(kind_of = Movement, json_parameters = some_json)
        # r2 = db_create(kind_of = Movement, json_parameters = more_json)
        # r3 = db_create(kind_of = Movement, json_parameters = complete_json)
        # r4 = db_create(schema_type = Movement, json_parameters = double_json)
        # r5 = db_create(schema_type = Movement, json_parameters = pushup_json)



    # echo r4
    # echo r5
    # echo query_json.db_read_multiple(MovementAttribute)

    # case complete_json.kind:
    #     of JObject:
    #         echo complete_json.convert(Movement(), schema_parameters = database_schema.movement_params)
    #                           .db_create(table = "movement")

    #     else:
    #         echo "not supported yet"
    # echo complete_json.convert_to(Movement)
    #                   .db_create
    
    # echo double_json.convert_to(Movement)
    #                 .db_create
    # echo double_json.convert_to(Movement)
    #                 .db_create
    # echo pushup_json.convert_to(Movement)
    #                 .db_create

    # echo query_json.convert_to(Movement)
    # echo db_read_any(Movement(area: "Upper"), table = "movement")
    # echo db_read_any(Movement(plane: "*"))

    # echo db_read_unique(table = "movement", "plane")