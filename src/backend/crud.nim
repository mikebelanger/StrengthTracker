import ../app_types, database_schema
import allographer/query_builder
import json
import sequtils, strutils
import times

const restricted = @[
    "id",
    "kind"
]

const foreign_prefixes = @[
    "movement",
    "movement_combo",
    "user"
]

#################
#### HELPERS ####
#################

proc exists*(i: int): bool =
    i > 0

proc worked*(i: seq[JsonNode]): bool =
    if i.len == 0:
        return false

    elif i.anyIt(it{"id"}.getInt <= 0):
        return false

    return true


proc to_json*(obj: Movement | MovementCombo | MovementComboAssignment | User | Routine): JsonNode =
    var to_json = parseJson("{}")

    for key, val in obj.fieldPairs:

        if not restricted.contains(key):

            to_json{key}= %($val)

    return to_json


proc to_json*(obj: Session): JsonNode =

    result = %*{ "routine": obj.routine.to_json,
                 "date": obj.date.format("yyyy-MM-dd") }


proc get_foreign_keys*(j: JsonNode): JsonNode =

    result = parseJson("{}")

    for key in j.keys:

        if key in foreign_prefixes:

            result{key & "_id"}= j{key}{"id"}

        else:

            result{key}= j{key}

    return result

# For some reason I can't override the `%*` template for tuples
proc to_json*(t: tuple): JsonNode =
    result = parseJson("{}")
    for key, val in t.fieldPairs:
        result{key}= %val

# convenience function for when querying an equals with an orWhere
proc query_matching_any*(table: RDB, criteria: tuple): RDB =

    result = table
        
    for each_property, content in criteria.fieldPairs:

        result = table.orWhere(each_property, "=", $content)

# convenience function for when querying an equals with a Where
proc query_matching_all*(table: RDB, criteria: tuple): RDB =
    
    result = table

    for each_property, content in criteria.fieldPairs:

        result = table.where(each_property, "=", $content)


proc db_connect*(data_table: DataTable): RDB =
    RDB().table($data_table).select()

proc interpretJson*(input: string): seq[JsonNode] =
    result = @[]
    try:
        let j = parseJson(input)
        result.add(j)
    except:
        echo getCurrentExceptionMsg()

proc is_complete*(x: object): bool =

    for key, val in x.fieldPairs:

        case key:
            of "Description":
                return true
            
            else:
                var value = $val
                if value.len == 0 or value.contains("Unspecified"):
                    return false

    return true

proc to_new*(j: JsonNode, t: typedesc): object =
    var to_convert = parseJson("{}")
    to_convert{"kind"}= %"New"

    try:
        for key in j.keys:
            
            if not restricted.contains(key):
                to_convert{key}= %*j{key}

        result =  to_convert.to(t)
    except:
        echo getCurrentExceptionMsg()

    return result

proc to_existing*(j: JsonNode, t: typedesc): object =
    j{"kind"}= %"Existing"

    try:
        result =  j.to(t)

    except:
        echo getCurrentExceptionMsg()

    return result

proc is_valid_for(j: JsonNode, e: EntryKind, t: typedesc): bool =
    j{"kind"}= %e

    try:
        discard j.to(t)
        return true
    except:
        echo getCurrentExceptionMsg()
        return false

proc get_id*(j: JsonNode): int =
    try:
        result = j{"id"}.getInt
    except:
        echo getCurrentExceptionMsg()
    
    return result

##################
#### CREATE ######
##################

proc db_create*(jnodes: seq[JsonNode], t: typedesc, into: DataTable): seq[JsonNode] =
    
    result = jnodes.filterIt(it.is_valid_for(New, t))
                   .mapIt(it.to_new(t))
                   .filterIt(it.is_complete)
                   .mapIt(it.to_json.get_foreign_keys)
                   .mapIt(into.db_connect.insertID(it))
                   .filterIt(it > 0)
                   .mapIt(into.db_connect.find(it))

##################
#### UPDATE ######
##################

proc db_update*(jnodes: seq[JsonNode], t: typedesc, into: DataTable): seq[JsonNode] =
    
    result = jnodes.filterIt(it.is_valid_for(Existing, t))
                   .mapIt(it.to_existing(t))
                   .filterIt(it.is_complete)
                   .map(proc (this: object): JsonNode =
                        try:
                            var to_insert = this.to_json
                            into.db_connect.where("id", "=", this.id).update(to_insert)
                            result = to_insert
                        except:
                            echo getCurrentExceptionMsg()

                   )

proc db_read_from_id*(id: int, into: DataTable): JsonNode =
    result = parseJson("{}")

    try:
        result = into.db_connect.find(id)

    except:
        echo getCurrentExceptionMsg()

    return result
# if isMainModule:

#     let 
#         criteria = (
#             symmetry: Bilateral,
#             concentric_type: Push, 
#         )

    
#     var results = MovementTable.db_connect
#                                .query_matching_all(criteria)
#                                .select("name")
#                                .db_read
#     echo results
    # echo all
    # echo any.len, all.len

