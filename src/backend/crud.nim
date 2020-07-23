import ../app_types, database_schema
import allographer/query_builder
import json, typetraits
import sequtils, strutils, strformat
import times
import segfaults

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
                    seq[Intensity] |
                    seq[RoutineAssignment] |
                    seq[WorkoutSet]): seq[JsonNode] =

    result = @[]

    for obj in objs:

        var to_json = parseJson("{}")

        try:
            for key, val in obj.fieldPairs:

                if not restricted.contains(key):
                    
                    # TODO: Figure out why this works
                    when val is YYYYMMDD:

                        to_json{key}= %*val.strftime
                    
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

proc str_to_YYYYMMDD(str: string): YYYYMMDD =

    let
        ymd = str.split("-")

    if ymd.len == 3:
        
        result = YYYYMMDD(
            Year : ymd[0].parseInt,
            Month : ymd[1].parseInt,
            Day : ymd[2].parseInt
        )

 

proc into*(js: seq[JsonNode], e: EntryKind, t: typedesc): seq[t] =
    result = @[]

    for j in js: 

        try:

            when t is Session:
                
                if e == New:
                    let obj = Session(
                        kind: New,
                        session_date: j{"session_date"}.getStr(default = "0000-00-00").str_to_YYYYMMDD,
                        routine: j{"routine"}.to(Routine)
                    )

                    result.add(obj)
                
                else:

                    let obj = Session(
                        id: j{"id"}.getInt(-1), 
                        kind: Existing,
                        session_date: j{"session_date"}.getStr(default = "0000-00-00").str_to_YYYYMMDD,
                        routine: j{"routine"}.to(Routine)
                    )

                    result.add(obj)

            else:
                var to_convert = parseJson("{}")
                to_convert{"kind"}= %e

                for key in j.keys:
                    
                    case j{key}.kind:

                        of JFloat:
                            to_convert{key}= newJFloat(j{key}.getFloat(1.0))

                        of JObject:
                            
                            to_convert{key}= %*j{key}

                            if key == "session":

                                to_convert{key}{"session_date"}= %*j{key}{"session_date"}.getStr("0000-00-00").str_to_YYYYMMDD

                        else:
                            to_convert{key}= %*j{key}

                let obj = to_convert.to(t)

                result.add(obj)


        except:
            echo "into error: ", getCurrentExceptionMsg()
            continue

    return result


proc get_id*(js: seq[JsonNode]): seq[int] =

    result = @[]

    for j in js:
        try:
            result.add(j{"id"}.getInt(-1))
        except:
            echo "error getting id: ", getCurrentExceptionMsg()

converter to_YYYYMMDD*(dt: DateTime): YYYYMMDD =
    
    # TODO: add the times fields
    result = YYYYMMDD(
        Year: ord(dt.year),
        Month: ord(dt.month),
        Day: ord(dt.monthday)
    )

proc strftime*(ymd: YYYYMMDD, sep="-"): string =
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

            elif key == "quantity":

                return_j{key} = newJFloat(j{key}.getFloat)


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

    let blah = parseJson("""
    {"kind":"Existing",
    "id":1,
    "movement":
        {"id":1,"name":"Kettlebell Step Up WITH FIRE","area":"Upper","concentric_type":"Squat","symmetry":"Bilateral","plane":"Vertical","description":"stepping on a flaming brick","kind":"Existing"},
    "movement_combo":
        {"id":1,"name":"some_new_combo","kind":"Existing"},"reps":4,"tempo":"3-0-5-0","intensity":{"id":1,"quantity":0.0,"units":"Pounds","kind":"Existing"},
    "session":
        {"kind":"Existing","id":1,"session_date":{"Year":2020,"Month":7,"Day":22}},
    "duration_in_minutes":10,
    "set_order":2}
    """)

    echo blah