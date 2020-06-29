import allographer/query_builder
import json
import ../app_types
import strutils
import sequtils
import database_schema
import allographer/schema_builder

#####################
##### HELPERS #######
#####################
proc any_missing_parameters(col: openArray[Column], json_pars: JsonNode): seq[string] =

    result = col.filterIt(it.name != "id")
                .filterIt(json_pars.hasKey(it.name) == false or json_pars{it.name}.getStr.len == 0)
                .mapIt(it.name)

#####################
####### CREATE ######
#####################

proc db_create*(json_parameters: JsonNode, kind_of: SchemaType): CRUDObject =

    case kind_of:
        of Movement:

            # check schema
            var any_missing_pars = any_missing_parameters(database_schema.movement_table, json_parameters)

            # if there's anything missing, report it
            if any_missing_pars.len > 0:

                let missing_str = any_missing_pars.foldl(a & "," & b)
                
                result = CRUDObject(status: Error, error: "Incomplete.  Missing: " & missing_str)

            else:

                try:

                    RDB().table("movement")
                         .insert(json_parameters)

                except DbError:
                    result = CRUDObject(status: Error, error: "Already exists: " & $json_parameters)

        else:
            echo "not supported yet"

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
    # echo more_json{"area"}.len
        r1 = db_create(kind_of = Movement, json_parameters = some_json)
        r2 = db_create(kind_of = Movement, json_parameters = more_json)
        r3 = db_create(kind_of = Movement, json_parameters = complete_json)
        r4 = db_create(kind_of = Movement, json_parameters = double_json)

    echo r1, r2, r3
    echo "r4: ", r4