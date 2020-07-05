# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import json
import ../app_types
import allographer/query_builder
import strutils
import jester, strutils, asyncdispatch


proc match(request: Request): Future[ResponseData] {.async.} =
    block route:

        case request.reqMeth:

            # GET
            of HttpGet:

                case request.pathInfo:
                
                    of Home:
                        redirect Index

                    of ReadAllMovement:
                        resp %*{"content" : "getting move time baby!"}

                    else:
                        echo "Not supported yet"

            # POST
            of HttpPost:
            
                case request.pathInfo:
                    of CreateMovement:
                    
                        RDB().table($Movement).insert(request.body.parseJson)
                        resp Http200, "Success"
                    
                    of CreateMovementCombo:
                    
                        # Create the movement combo first
                        var combo_id = RDB().table($MovementCombo)
                                            .insertID(request.body.parseJson)

                        if request.body.parseJson.hasKey($MovementId):
                            var ids = request.body.parseJson{$MovementId}

                            case ids.kind:
                                of JArray:
                                    
                                    var r = RDB().table($MovementComboAssignment)

                                    # Loop through each movement
                                    # make it a movement combo assignment row
                                    for movement_id in ids:
                                        r.insert(%*{ $MovementId : movement_id, 
                                                    $MovementComboId : combo_id})
                                
                                    resp Http200, "Movement Combo Created Successfully"
                            
                                else:
                                    
                                    resp Http501, "Cannot use anything other than JArrays"
                

            else:

                echo "Not sure how to handle that method"

var server = initJester(match)
server.serve()

  # CREATE

# routes:

#   post home:
#     redirect "/index.html"
    
  #   render_json_for:
  #     RDB().table($Movement).insert(request.body.parseJson)

  # post $CreateMovementCombo:
    
  #   var combo_id = RDB().table($MovementCombo).insertID(request.body.parseJson)

  #   # Check if we have the movement_id key, and if so, its value is a JArray of values
  #   if request.body.parseJson.hasKey($MovementId):
  #     var ids = request.body.parseJson{$MovementId}

  #     case ids.kind:
  #       of JArray:
          
  #         var r = RDB().table($MovementComboAssignment)

  #         # Loop through each movement and make it a movement combo assignment row
  #         for movement_id in ids:
  #           r.insert(%*{ $MovementId : movement_id, $MovementComboId : combo_id})
      
  #         return CRUDObject(status: Complete)
      

  # # READ

  # get $ReadAllMovements:

  #   RDB().table($Movement).select().get()

  # get $ReadDistinctMovementAttributes:

  #   resp %*[
  #             { "planes": db_read_unique($Movement, "plane"),
  #               "areas": db_read_unique($Movement, "area"),
  #               "concentric_types": db_read_unique($Movement, "concentric_type"),
  #               "symmetries": db_read_unique($Movement, "symmetry")
  #           }
  #         ]
  # UPDATE
  # DELETE