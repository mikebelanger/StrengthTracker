import allographer/query_builder
import ../app_types
import sequtils
import database_schema
import json

#####################
###### HELPERS ######
#####################

proc any_missing_parameters(col: openArray[string], json_pars: JsonNode): seq[string] =

  result = col.filterIt(json_pars.hasKey(it) == false or json_pars{it}.getStr.len == 0)


proc filter_params(json_params: JsonNode): JsonNode =

    # I have to explicitely declare this json for some reason
    var result = parseJson("{}")

    for key in json_params.keys:
        if key.is_permitted:
            result{key}= %*json_params{key}

    # for some reason, I have to explicitly return result here.  Otherwise its nil
    return result


#####################
####### CREATE ######
#####################

proc db_create_one*(json_parameters: JsonNode, schema_type: SchemaType): CRUDObject =

    # ensure all parameters are allowed
    let params = json_parameters.filter_params

    case schema_type:
        of Movement:

            # check schema
            var any_missing_pars = any_missing_parameters(database_schema.movement_params, params)

            # if there's anything missing, report it
            if any_missing_pars.len > 0:

                let missing_str = any_missing_pars.foldl(a & "," & b)

                result = CRUDObject(status: Error, error: "Incomplete.  Missing: " & missing_str)

            else:

                try:

                    RDB().table("movement")
                         .insert(params)

                    result.status = Complete

                except DbError:
                    result = CRUDObject(status: Error, error: "Already exists: " & $params)

        else:
            echo "not supported yet"

#####################
####### READ ########
#####################

proc db_read_some*(json_parameters: JsonNode, schema_type: SchemaType): CRUDObject =

    # filter out any unnecessary / dangereous parameters
    let params = json_parameters.filter_params

    case schema_type:
        of Movement:

            var movement = RDB().table("movement")
                                .select("name", "area", "concentric_type", "symmetry", "plane")

            # treat each json key-val pair as an AND condition with equals qualifier
            for key, val in params.pairs:
                movement = movement.where(key, "=", val.getStr)
            
            result.content = %*movement.get()

        of MovementAttribute:
            result.content = parseJson("{}")

            var 
                movement = RDB().table("movement")
                sane_params = params["distinct"].filterIt(database_schema.movement_params.contains(it.getStr))
                                    .mapIt(it.getStr)

            # loop through json attributes
            
            for attr in sane_params:
                result.content{attr}= %*movement.select(attr).distinct().get().mapIt(it{attr})

        of MovementCombo, Set:
            echo "plural"

    result.status = Complete

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
    echo query_json.db_read_some(MovementAttribute)