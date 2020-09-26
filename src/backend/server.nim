import options, asyncdispatch

import httpx

import json
import ../app_routes, schema, crud, allographer/query_builder

converter route_to_string(r: Routes): string = 
    $r

proc string_to_json(str: Option[string]): seq[JsonNode] =
    if str.isSome:
        try:
            result.add(str.get.parseJson)
        except:
            echo getCurrentExceptionMsg()

proc read_param*(json_nodes: seq[JsonNode], param: Basic | UserSchema | SessionSchema | WorkoutSchema): seq[JsonNode] =
    for jnode in json_nodes:
        if jnode.has_key(param):
            result.add(jnode)

proc onRequest(req: Request): Future[void] {.gcsafe.} =

    if req.httpMethod == some(HttpGet):
        case req.path.get()
            of Home:
                req.send("Hello World")

            of ReadUser:

                let response = 
                    req.body
                    .string_to_json
                    .read_param(id)
                    .read(User)
                    .get()

                case response.len:
                    of 0:
                        req.send("could not get value")
                    else:
                        req.send(Http200, $(response))

            of ReadAllUsers:

                let response = 
                    User.select().get()

                case response.len:
                    of 0:
                        req.send("could not get value")
                    else:
                        req.send(Http200, $(%*response))

            else:
                req.send(Http404)

run(onRequest)