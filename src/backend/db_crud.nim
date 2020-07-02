import allographer/query_builder
import allographer/schema_builder
import ../app_types
import sequtils
import database_schema
import json

#####################
###### HELPERS ######
#####################

proc filter_params(json_params: JsonNode): JsonNode =

    # I have to explicitely declare this json for some reason
    var result = parseJson("{}")

    echo all_params

    for key in json_params.keys:
        if all_params.contains(key):
            result{key}= %*json_params{key}

    # for some reason, I have to explicitly return result here.  Otherwise its nil
    echo result
    return result

proc convert_to*[T](input_params: JsonNode, t: typedesc[T]): T = 

    # ensure all parameters are allowed
    var params = input_params.filter_params

    result = params.to(t)


#####################
####### CREATE ######
#####################

proc db_create*(m: Movement, table = "movement"): CRUDObject =

    try:

        RDB().table(table)
             .insert(%*m)

        result.status = Complete

    except DbError:
        result = CRUDObject(status: Error, error: "Already exists: " & $m)


# #####################
# ####### READ ########
# #####################

proc db_read_any*[T](obj: T, table: string): seq[T] =
    
    var table_conn = RDB().table(table)
    var columns: seq[string]

    for key, val in obj.fieldPairs:

        columns.add(key)

    table_conn.query["select"] = %*columns

    # treat each json key-val pair as an AND condition with equals qualifier
    for key, val in obj.fieldPairs:
        
        if val.len > 0 and val != "*":
            table_conn = table_conn.where(key, "=", val)

    result = table_conn.get().mapIt(it.to(T.typeof))


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
    echo complete_json.convert_to(Movement)
                      .db_create
    
    echo double_json.convert_to(Movement)
                    .db_create
    echo double_json.convert_to(Movement)
                    .db_create
    echo pushup_json.convert_to(Movement)
                    .db_create

    echo query_json.convert_to(Movement)
    echo db_read_any(Movement(area: "Upper"), table = "movement")
    # echo db_read_any(Movement(plane: "*"))

    # echo db_read_unique(table = "movement", "plane")