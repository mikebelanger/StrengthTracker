import allographer/query_builder
import allographer/schema_builder
import ../app_types
import sequtils
import database_schema
import json

#####################
###### HELPERS ######
#####################

proc any_missing_parameters(json_params: JsonNode, col: openArray[Column]): seq[string] =

    result = col.filterIt(json_params.hasKey(it.name) == false or json_params{it.name}.getStr.len == 0)
                .mapIt(it.name)


proc filter_params(json_params: JsonNode): JsonNode =

    # I have to explicitely declare this json for some reason
    var result = parseJson("{}")

    for key in json_params.keys:
        if key.is_permitted:
            result{key}= %*json_params{key}

    # for some reason, I have to explicitly return result here.  Otherwise its nil
    return result


proc convert*(input_params: JsonNode, obj: Movement): Movement = 

    # ensure all parameters are allowed
    var 
        params = input_params.filter_params
        missing = params.any_missing_parameters(database_schema.movement_params)

    if missing.len > 0:
        for m in missing:

            echo "missing: ", m

        result = Movement()

    else:

        result = params.to(Movement)
    

#####################
####### CREATE ######
#####################

proc db_create*(m: Movement, table_name = "movement"): CRUDObject =

    try:

        RDB().table(table_name)
             .insert(%*m)

        result.status = Complete

    except DbError:
        result = CRUDObject(status: Error, error: "Already exists: " & $m)



# #####################
# ####### READ ########
# #####################

proc db_read_any*(with: Movement, table_name = "movement", columns = database_schema.movement_params): seq[Movement] =
    
    var movement = RDB().table(table_name)
    movement.query["select"]= %*columns.mapIt(it.name)

    # treat each json key-val pair as an AND condition with equals qualifier
    for key, val in with.fieldPairs:
        
        if val.len > 0 and val != "*":
            movement = movement.where(key, "=", val)

    result = movement.get().mapIt(it.convert(Movement()))


proc db_read_unique*(table, column_name: string): seq[string] =

    var table_conn = RDB().table(table).select(column_name)
    result = table_conn.distinct().get().mapIt(it.getOrDefault(key = column_name).getStr)


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
        "area": "Upper",
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
        "distinct": ["plane", "concentric_type", "bogus_category", "symmetry"]        
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

    echo double_json.convert(Movement())
                    .db_create
    echo double_json.convert(Movement())
                    .db_create
    echo pushup_json.convert(Movement())
                    .db_create

    echo db_read_any(Movement(plane: "Horizontal"))
    echo db_read_any(Movement(plane: "*"))

    echo db_read_unique(table = "movement", "plane")