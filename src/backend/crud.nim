import ../app_types, database_schema
import allographer/query_builder
import json
import sequtils, strutils, options
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

proc worked*(i: int): bool =
    i > 0

proc worked*(i: Option[int]): bool =
    if i.isSome:
        return false
    elif i.get < 1:
        return false
    else:
        return true

proc worked*(i: JsonNode): bool =
    if i.getOrDefault("id").getInt > 0:
        return true
    else:
        return false

proc worked*(i: seq[JsonNode]): bool =
    if i.len == 0:
        return false

    elif i.anyIt(it{"id"}.getInt <= 0):
        return false

    return true

proc to_json*(input: string): Option[JsonNode] =
    try:
        result = input.parseJson.some
    except:
        echo getCurrentExceptionMsg()
        result = JsonNode.none

    return result

proc to_json*(obj: Option[Movement] | 
                   Option[MovementCombo] | 
                   Option[MovementComboAssignment] | 
                   Option[User] | 
                   Option[Session] |
                   Option[Routine]): Option[JsonNode] =

    if obj.isSome:

        var to_json = parseJson("{}")

        try:
            for key, val in obj.get.fieldPairs:

                if not restricted.contains(key):
                    
                    to_json{key}= %*val

            return to_json.some

        except:
            echo getCurrentExceptionMsg()
            return JsonNode.none


# For some reason I can't override the `%*` template for tuples
proc to_json*(t: tuple): JsonNode =
    result = parseJson("{}")
    for key, val in t.fieldPairs:
        result{key}= %val

proc get_foreign_keys*(j: Option[JsonNode]): Option[JsonNode] =

    if j.isSome:
        var to_return = parseJson("{}")
        for key in j.get.keys:
            
            if key in foreign_prefixes:

                to_return{key & "_id"}= j.get{key}.getOrDefault("id")

            else:

                to_return{key}= j.get{key}

        result = to_return.some


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

proc into*(j: Option[JsonNode], e: EntryKind, t: typedesc): Option[t] =
    
    if j.isSome:
        var to_convert = parseJson("{}")
        to_convert{"kind"}= %e

        try:
            for key in j.get.keys:
                
                if not restricted.contains(key):
                    to_convert{key}= %*j.get{key}

            var obj =  to_convert.to(t)

            if obj.is_complete:
                result = obj.some
            else:
                result = none(t)
        except:
            echo getCurrentExceptionMsg()
            result = none(t)

        return result


proc get_id*(j: Option[JsonNode]): Option[int] =

    if j.isSome:
        try:
            result = j.get{"id"}.getInt.some
        except:
            echo getCurrentExceptionMsg()
            result = int.none

    else:
        return int.none

proc to_Date*(dt: DateTime): Date =
    
    # TODO: add the times fields
    result = Date(
        Year: ord(dt.year),
        Month: ord(dt.month),
        Day: ord(dt.monthday)
    )

##################
#### CREATE ######
##################

proc db_create*(s: string, t: typedesc, into: DataTable): int =
    
    let insert = s.to_json
                  .into(New, t)
                  .to_json
                  .get_foreign_keys

    if insert.isSome:
        result = into.db_connect.insertID(insert.get)


##################
#### UPDATE ######
##################

proc db_update*(s: string, t: typedesc, into: DataTable): int =
    
    let insert = s.to_json
                    .into(Existing, t)
                    .to_json
                    .get_foreign_keys

    if insert.isSome:
        result = into.db_connect.where("id", "=", insert.get{"id"}.getInt)
                                .insertID(insert.get)


proc db_read_from_id*(id: int, into: DataTable): JsonNode =
    result = parseJson("{}")

    try:
        result = into.db_connect.find(id)

    except:
        echo getCurrentExceptionMsg()

    return result