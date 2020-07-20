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

proc to_json*(input: string): seq[JsonNode] =
    result = @[]

    try:
        result.add(input.parseJson)
    except:
        echo getCurrentExceptionMsg()

    return result

proc to_json*(objs: seq[Movement] | 
                    seq[MovementCombo] | 
                    seq[MovementComboAssignment] | 
                    seq[User] | 
                    seq[Session] |
                    seq[Routine]): seq[JsonNode] =

    result = @[]

    for obj in objs:

        var to_json = parseJson("{}")

        try:
            for key, val in obj.fieldPairs:

                if not restricted.contains(key):
                    
                    to_json{key}= %*val

            result.add(to_json)

        except:
            echo getCurrentExceptionMsg()
            continue

    return result

# For some reason I can't override the `%*` template for tuples
proc to_json*(ts: seq[tuple]): seq[JsonNode] =
    result = @[]

    for t in ts:
        try:
            var jnode = parseJson("{}")
            for key, val in t.fieldPairs:
                result.add(jnode{key}= %val)

        except:
            echo getCurrentExceptionMsg()
            continue

    return result

proc get_foreign_keys*(js: seq[JsonNode]): seq[JsonNode] =
    result = @[]

    for j in js: 

        try:

            var to_return = parseJson("{}")
            for key in j.keys:
                
                if key in foreign_prefixes:

                    to_return{key & "_id"}= j{key}.getOrDefault("id")

                else:

                    to_return{key}= j{key}

            result.add(to_return)

        except:
            echo getCurrentExceptionMsg()
            continue

    return result

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

proc into*(js: seq[JsonNode], e: EntryKind, t: typedesc): seq[t] =
    result = @[]

    for j in js: 
        var to_convert = parseJson("{}")
        to_convert{"kind"}= %e

        try:
            for key in j.keys:

                case e:
                    of New:
                        
                        if not restricted.contains(key):
                            to_convert{key}= %*j{key}

                    of Existing:

                        to_convert{key}= %*j{key}

            var obj = to_convert.to(t)

            if obj.is_complete:
                result.add(obj)

        except:
            echo getCurrentExceptionMsg()
            continue

    return result


proc get_id*(js: seq[JsonNode]): seq[int] =

    result = @[]

    for j in js:
        try:
            result.add(j{"id"}.getInt)
        except:
            echo getCurrentExceptionMsg()

proc to_Date*(dt: DateTime): Date =
    
    # TODO: add the times fields
    result = Date(
        Year: ord(dt.year),
        Month: ord(dt.month),
        Day: ord(dt.monthday)
    )

proc db_read_from_id*(ids: seq[int], into: DataTable): seq[JsonNode] =
    result = @[]

    for id in ids:
        var js = parseJson("{}")

        try:
            js = into.db_connect.find(id)
            result.add(js)

        except:
            echo getCurrentExceptionMsg()
            continue

    return result

proc add_foreign_objs*(js: seq[JsonNode]): seq[JsonNode] =
    result = @[]

    for j in js:

        try:
            var return_j = parseJson("{}")

            # loop through individual json object
            for key in j.keys:
                var foreign_id = j{key}.getInt

                # if there's something like "movement_id", or "movement_combo_id"
                if "_id" in key and foreign_id > 0:

                    # assume we stick to table_name_id > table_name convention
                    let 
                        table_name = key.replace("_id", "")

                        query = RDB().table(table_name)
                                     .where("id", "=", foreign_id)
                                     .get()
                                     .add_foreign_objs

                    for q in query:
                        return_j{table_name}= q

                # otherwise just copy over what's there
                else:

                    return_j{key} = j{key}

            result.add(return_j)
        
        except:

            echo getCurrentExceptionMsg()
            continue

    return result


##################
#### CREATE ######
##################

proc db_create*(s: string, t: typedesc, into: DataTable): seq[t] =
    
    result = @[]

    let 
        to_insert = s.to_json
                     .into(New, t)
                     .to_json
                     .get_foreign_keys

    try:
        result = into.db_connect
                     .insertID(to_insert)
                     .db_read_from_id(into = into)
                     .add_foreign_objs
                     .into(Existing, t)
    except:
        echo getCurrentExceptionMsg()


    return result

##################
###### READ ######
##################

proc db_read*(s: string, t: typedesc, from_table: DataTable): seq[t] =
    
    result = @[]

    echo s

    try:

        result = s.to_json
                  .get_id
                  .map(proc (id: int): seq[JsonNode] =

                    echo "id: ", id

                    result = from_table.db_connect
                                       .where("id", "=", id)
                                       .get()
                                       .add_foreign_objs
                  )
                  .concat
                  .into(Existing, t)

    except:
        echo getCurrentExceptionMsg()


    return result

##################
#### UPDATE ######
##################

proc db_update*(s: string, t: typedesc, into: DataTable): seq[t] =
    
    result = s.to_json
              .into(Existing, t)
              .to_json
              .get_foreign_keys
              .map(proc (j: JsonNode): int =

                    result = into.db_connect.where("id", "=", j{"id"}.getInt)
                                            .insertID(j)
              )
              .db_read_from_id(into = into)
              .add_foreign_objs
              .into(Existing, t)

    return result