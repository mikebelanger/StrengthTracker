import ../app_types
import allographer/query_builder
import json

#################
#### HELPERS ####
#################

converter exists*(i: int): bool =
    i > 0

proc matching_any*(table: RDB, criteria: tuple): RDB =
        
    for each_property, content in criteria.fieldPairs:

        result = table.orWhere(each_property, "=", $content)


proc matching_all*(table: RDB, criteria: tuple): RDB =
        
    for each_property, content in criteria.fieldPairs:

        result = table.where(each_property, "=", $content)


proc db_query*(data_table: DataTable): RDB =
    RDB().table($data_table).select()

################
#### CREATE ####
################

proc db_create*(table_name: DataTable, obj: object): int =

    result = RDB().table($table_name).insertID(%*obj)

################
##### READ #####
################

proc db_read*(table: RDB): seq[JsonNode] =

    try:
        result = table.get()
    
    except:
        echo getCurrentExceptionMsg()
        result = @[parseJson("{}")]

proc db_read*(table_name: DataTable): seq[JsonNode] =
    RDB().table($table_name).select().get()

################
#### UPDATE ####
################

################
#### DELETE ####
################

if isMainModule:

    # let x = MovementTable.db_read

    # for i in x:
    #     echo $x

    # let y = x.len

    # echo y
    # echo y is Positive
    let 
        criteria = (
            symmetry: Bilateral,
            concentric_type: Push, 
            plane: Vertical
        )

        any = MovementTable.db_query
                           .matching_all(criteria)
                           .db_read
                                    
    # MovementTable.db_query.select("id", "name", "concentric_type")
    #                       .matching_any((id: 4)).update(%*{"name": "Ring Dips +"})
    
    echo any
    # echo all
    # echo any.len, all.len