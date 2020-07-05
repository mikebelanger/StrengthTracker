# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import json
import ../app_types
import allographer/query_builder
import jester, asyncdispatch, asyncnet
import sequtils

proc match(request: Request): Future[ResponseData] {.async.} =
    block route:

        case request.reqMeth:

            # GET
            of HttpGet:

                case request.pathInfo:
                
                    of Home:
                        redirect Index

                    of ReadAllMovement:
                        var all_movements = RDB().table($MovementTable).select().get()
                        resp %*all_movements

                    of ReadAllMovementAttrs:

                        resp %*{
                            "planes" : RDB().table($MovementTable).select("plane").distinct().get().mapIt(it{"plane"}),
                            "areas" : RDB().table($MovementTable).select("area").distinct().get().mapIt(it{"area"}),
                            "concentric_types" : RDB().table($MovementTable).select("concentric_type").distinct().get().mapIt(it{"concentric_type"}),
                            "symmetries" : RDB().table($MovementTable).select("symmetry").distinct().get().mapIt(it{"symmetry"})
                        }


                    else:
                        echo "Not supported yet"

            # POST
            of HttpPost:
            
                case request.pathInfo:
                    of CreateMovement:

                        var new_movement = request.body.parseJson.to(Movement)
                        RDB().table($MovementTable).insert(%*new_movement)
                        resp Http200, "Success"
                    
                    of CreateMovementCombo:

                        var 
                            new_movement_combo = request.body.parseJson.to(NewMovementComboRequest)
                            combo_id = RDB().table($MovementComboTable)
                                            .insertID(%*{ "name" : new_movement_combo.name})

                        # If we have enough movement ids
                        if combo_id is Positive and new_movement_combo.movement_ids.len > 0:
                            var assignments_table = RDB().table($MovementComboAssignmentTable)

                            for movement_id in new_movement_combo.movement_ids:
                                
                                assignments_table.insert(%*{ $MovementId : movement_id, $MovementComboId : combo_id})


                            resp Http200, "Assignments created successfully"

                        else:

                            resp Http501, "Either no combo id or there's no movement ids"


            # I seem to only need GET and POST
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