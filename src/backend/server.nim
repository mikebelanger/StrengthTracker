import options, asyncdispatch

import jester

import json
import ../app_routes, schema, crud, allographer/query_builder

converter route_to_string(r: Routes): string = 
    $r

proc string_to_json(str: string): seq[JsonNode] =
    if str.len > 0:
        try:
            result.add(str.parseJson)
        except:
            echo getCurrentExceptionMsg()

proc read_param*(json_nodes: seq[JsonNode], param: Basic | UserSchema | SessionSchema | WorkoutSchema): seq[JsonNode] =
    for jnode in json_nodes:
        if jnode.has_key(param):
            result.add(jnode)

routes:
    
    get "/read_user.json":

        let response = 
            request.body
            .string_to_json
            .read_param(id)
            .read(User)
            .get

        case response.len:
            of 0:
                resp "could not get value"
            else:
                resp Http200, $(%*response)

    get "/read_all_users.json":

        let response = 
            User
            .select
            .get
            .jexcel_user_table

        resp $(%*response)