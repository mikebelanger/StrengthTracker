import ../app_types, database_schema
import allographer/query_builder
import json
import sequtils, strutils

const restricted = @[
    "id",
    "kind"
]

#################
#### HELPERS ####
#################

proc exists*(i: int): bool =
    i > 0

proc worked*(i: seq[Movement | MovementCombo | MovementComboAssignment]): bool =
    if i.len == 0:
        return false

    elif i.anyIt(it.id <= 0):
        return false

    return true

proc to_json*(obj: Movement | MovementCombo | MovementComboAssignment | User): JsonNode =
    var to_json = parseJson("{}")

    for key, val in obj.fieldPairs:

        if not restricted.contains(key):

            # if key is object:
            #     echo key, " is object"

            to_json{key}= %*val

    return to_json

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

proc db_create*(jnodes: seq[JsonNode], t: typedesc, into: DataTable): seq[t] =
    
    result = jnodes.filterIt(it.is_valid_for(New, t))
                   .mapIt(it.to_new(t))
                   .filterIt(it.is_complete)
                   .mapIt(into.db_connect.insertID(it.to_json))
                   .filterIt(it > 0)
                   .mapIt(into.db_connect.find(it))
                   .mapIt(it.to_existing(t))
                   .filterIt(it.is_complete)

##################
#### UPDATE ######
##################

proc db_update*(jnodes: seq[JsonNode], t: typedesc, into: DataTable): seq[t] =
    
    result = jnodes.filterIt(it.is_valid_for(Existing, t))
                   .mapIt(it.to_existing(t))
                   .filterIt(it.is_complete)
                   .map(proc (this: object): object =
                        try:
                            into.db_connect.where("id", "=", this.id).update(this.to_json)
                            result = this
                        except:
                            echo getCurrentExceptionMsg()

                   ).filterIt(it.is_complete)                         



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

if isMainModule:

    let x = """
    { "stuf : erger' }
    """

    let 
        bad = """
        { erg\
        """

        stupid = """
        { "name" : "my fantastic movement" }
        """

        sort_of_ok = """
        { "name" : "push-up",
          "plane" : "Horizontal",
          "concentric_type" : "Push", 
          "area" : "Upper",
          "symmetry" : "Binaugural"
        }
        """

        should_work = """
        { "name" : "Kettlebell Step Up",
          "plane" : "Vertical",
          "concentric_type" : "Squat", 
          "area" : "Upper",
          "symmetry" : "Bilateral",
          "description" : "on the floor"
        }
        """

        should_work_updated = """
        { "id" : 1,
          "name" : "Kettlebell Step Up WITH FIRE",
          "plane" : "Vertical",
          "concentric_type" : "Squat", 
          "area" : "Upper",
          "symmetry" : "Bilateral",
          "description" : "stepping on a flaming brick"
        }
        """

        should_work_updated_wrong = """
        { "id" : 1,
          "name" : "Kettlebell Step Up WITH FIRE",
          "plane" : "Blah",
          "concentric_type" : "Squat", 
          "area" : "Upper",
          "symmetry" : "Bilateral",
          "description" : "stepping on a flaming brick"
        }
        """

        movement_combo = """
            { "name" : "some_new_combo" }
        """

        # movements_completed = 
    
        #     stupid.interpretJson.map(proc (j: JsonNode): Movement =
        #         try:
        #             result = j.to(Movement)
        #         except:
        #             echo getCurrentExceptionMsg()
        #     ).mapIt(it.is_complete)

        # movement_table = MovementTable.db_connect

    # if movements_completed.allIt(it):
    #     echo "they work!"
    # else:
    #     echo "They don't work"

    # echo "but I got to the end of the program!!!"

    # echo bad.interpretJson.mapIt(it.to_new(Movement))
    # echo stupid.interpretJson.mapIt(it.to_new(Movement))
    # echo sort_of_ok.interpretJson.mapIt(it.to_new(Movement))
    # let 
    #     to_insert = should_work.interpretJson
    #                             .mapIt(it.to_new(Movement))
    #                             .mapIt(it.to_json)

    #     inserted = MovementTable.db_connect.insertID(to_insert)

    # echo inserted

    # let test = stupid.interpretJson.mapIt(it.to_new(Movement))
    #                                        .mapIt(it.to_json)
    #                                        .mapIt(MovementTable.db_connect.insertID(it))
    #                                        .filterIt(it > 0)
    #                                        .map(proc (id: int): Movement =

    #                                             try:
    #                                                 result = MovementTable.db_connect
    #                                                                       .find(19)
    #                                                                       .to_existing(Movement)


    #                                             except:
    #                                                 echo getCurrentExceptionMsg()

    #                                        ).filterIt(it.kind == Existing)

    let sort_of = sort_of_ok.interpretJson.db_create(Movement, into = MovementTable)
    echo "sort_of", sort_of, sort_of.worked

    let new_movement = should_work.interpretJson.db_create(Movement, into = MovementTable)
    echo "movement", new_movement, new_movement.worked

    let updated_movement = should_work_updated.interpretJson.db_update(Movement, into = MovementTable)
    echo "updated movement: ", updated_movement, updated_movement.worked

    let updated_movement_wrong = should_work_updated_wrong.interpretJson
                                                          .db_update(Movement, into = MovementTable)

    echo "updated movement wrong: ", updated_movement_wrong, updated_movement_wrong.worked

    # echo "test", test

    
    # echo test
    # echo MovementComboTable.db_connect.insertID(test)
    # echo MovementTable.db_connect.query_matching_all((name: "Kettlebell Step Up")).first.to_existing(Movement)
    # echo id
    # echo MovementTable.db_connect.find(id[0])
    # echo id.mapIt(MovementTable.db_connect.find(it)