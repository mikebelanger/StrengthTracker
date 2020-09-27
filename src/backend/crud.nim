import allographer/query_builder
import schema
import json
import sequtils, sugar

converter load_table*(t: TableNames): RDB =
    RDB().table(t)

proc create*(params: seq[JsonNode], t: TableNames): seq[JsonNode] =
    var table = RDB().table(t)

    for param in params:
        for key in param.keys:
            try:
                let id = table.insertID(
                    param
                )

                param{"id"}= %*id
                result.add(param)

            except:
                echo getCurrentExceptionMsg()


proc read*(params: seq[JsonNode], t: TableNames): RDB =
    var table = RDB().table(t).select()

    for param in params:
        for key in param.keys:
            table = table.orWhere(key, "=", param{key}.getStr)

    return table

proc update*(params: seq[JsonNode], t: TableNames): seq[JsonNode] =
    var table = RDB().table(t).select()

    for param in params:
        if param.has_key(id):
            var to_update = parseJson("{}")

            for key in param.keys:
                if key != id:
                    to_update{key}= param{key}

            try:
                table.update(to_update)
            except:
                echo getCurrentExceptionMsg()
            
            result.add(
                table.find(id = param{$id}.getInt)
            )

proc delete*(params: seq[JsonNode], t: TableNames): bool =
    var table = RDB().table(t).select()

    for param in params:
        if param.has_key(id):
            try:
                table.delete(id = param{$id}.getInt)
                return true

            except:
                echo getCurrentExceptionMsg()
                return false

proc to_jexcel*(json_nodes: seq[JsonNode]): JsonNode =
    var columns, data: seq[JsonNode]

    for jnode in json_nodes:
        for key in jnode.keys:
            if not (columns.anyIt(it{"title"}.getStr == key)):
                columns.add(
                    %*{
                        "type": "text",
                        "title": key,
                        "width": 100
                    }
                )
            
            data.add(jnode)

    result = parseJson("{}")
    result{"columns"}= %*columns
    result{"data"}= %*data

proc jexcel_user_table*(jnodes: seq[JsonNode]): UserTable =
    try:
        result = UserTable(
            data: jnodes.map((each_node) => each_node.to(UserRow)),
            columns: [
                JExcelColumn(`type`: Numeric, title: "id", width: 100),
                JExcelColumn(`type`: Text, title: "name", width: 100),
                JExcelColumn(`type`: Text, title: "email", width: 250),
                JExcelColumn(`type`: CheckBox, title: "Active", width: 50)
            ]
        )

    except:
        echo getCurrentExceptionMsg()