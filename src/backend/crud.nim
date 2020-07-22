import ../app_types, database_schema
import allographer/query_builder
import json
import sequtils, strutils, strformat
import times

const restricted = @[
    "kind"
]

const foreign_prefixes = DataTable.mapIt($it)

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
                    seq[Routine] |
                    seq[RoutineAssignment]): seq[JsonNode] =

    result = @[]

    for obj in objs:

        var to_json = parseJson("{}")

        try:
            for key, val in obj.fieldPairs:

                if not restricted.contains(key):
                    
                    # TODO: Figure out why this works
                    when val is YYYYMMDD:

                        to_json{key}= %*val.to_string
                    
                    else:
                    
                        to_json{key}= %*val

            result.add(to_json)

        except:
            echo "to json error: ", getCurrentExceptionMsg()
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
                if key in foreign_prefixes and j{key}.hasKey("id"):

                    to_return{key & "_id"}= j{key}.getOrDefault("id")

                else:

                    to_return{key}= j{key}

            result.add(to_return)

        except:
            echo "get foreign keys error: ", getCurrentExceptionMsg()
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
                if "_date" in key:
                    
                    let
                        ymd = j{key}.getStr.split("-")
                    
                    if ymd.len == 3:
                        
                        let
                            year = ymd[0].parseInt
                            month = ymd[1].parseInt
                            day = ymd[2].parseInt

                        to_convert{key} = %*{
                            "Year" : year,
                            "Month": month,
                            "Day": day
                        }
                
                else:

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
            echo "into error: ", getCurrentExceptionMsg()
            continue

    return result


proc get_id*(js: seq[JsonNode]): seq[int] =

    result = @[]

    for j in js:
        try:
            result.add(j{"id"}.getInt)
        except:
            echo getCurrentExceptionMsg()

proc yyyy_mm_dd*(dt: DateTime): YYYYMMDD =
    
    # TODO: add the times fields
    result = YYYYMMDD(
        Year: ord(dt.year),
        Month: ord(dt.month),
        Day: ord(dt.monthday)
    )

proc to_string*(ymd: YYYYMMDD, sep="-"): string =
    &"{ymd.Year}{sep}{ymd.Month:02}{sep}{ymd.Day:02}"

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

        var return_j = parseJson("{}")

        # loop through individual json object
        for key in j.keys:

            # if there's something like "movement_id", or "movement_combo_id"
            if "_id" in key and not j{key}.isNil:
                if j{key}.getInt > 0:

                    # assume we stick to table_name_id > table_name convention
                    let 
                        table_name = key.replace("_id", "")

                        query = RDB().table(table_name)
                                    .where("id", "=", j{key}.getInt)
                                    .get()
                                    .add_foreign_objs

                    # add any objects from query into our attribute.  Should be for any nested object
                    for q in query:
                        return_j{table_name}= q

                    # safe to assume we only want existing objects, so add it as "Existing"
                    return_j{table_name}{"kind"}= %"Existing"

            # otherwise just copy over what's there
            else:

                return_j{key} = j{key}

        result.add(return_j)
        
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

    try:

        result = s.to_json
                  .get_id
                  .map(proc (id: int): seq[JsonNode] =


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
              .map(proc (j: JsonNode): JsonNode =

                    try:
                        into.db_connect.where("id", "=", j{"id"}.getInt)
                                       .update(j)

                        result = j

                    except:
                        echo getCurrentExceptionMsg()
              )
              .add_foreign_objs
              .into(Existing, t)

    return result

if isMainModule:

    echo now().yyyy_mm_dd.to_string