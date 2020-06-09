# exercise types
import options, json
import create_database
import allographer/schema_builder
import sequtils
import strutils

proc is_a_valid*(json_input: JsonNode, input_schema: openArray[Column]): bool =

    # TODO: make this less stupid
    var 
        idless_schema = input_schema.map(proc (x: Column): string = x.name.replace("_id", ""))
        missing = idless_schema.filterIt(not json_input.contains(it) and it != "id")

    if len(missing) > 0:
        echo "missing: ", missing
        return false

    else:
        return true

if isMainModule:

    for column in movement:
        echo column.name

