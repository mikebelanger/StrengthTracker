# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import json
import ../app_types
import allographer/query_builder
import jester, asyncdispatch
import sequtils
import crud

proc match(request: Request): Future[ResponseData] {.async.} =
    block route:

        case request.reqMeth:

            # GET
            of HttpGet:

                case request.pathInfo:
                
                    of Home:
                        redirect Index

                    of ReadAllMovement:
                        var all_movements = MovementTable.db_connect
                                                         .db_read
                        resp %*all_movements

                    of ReadAllMovementAttrs:

                        resp %*{
                            "planes" : MovementTable.db_connect.select("plane").distinct().get().mapIt(it{"plane"}),
                            "areas" : MovementTable.db_connect.select("area").distinct().get().mapIt(it{"area"}),
                            "concentric_types" : MovementTable.db_connect.select("concentric_type").distinct().get().mapIt(it{"concentric_type"}),
                            "symmetries" : MovementTable.db_connect.select("symmetry").distinct().get().mapIt(it{"symmetry"})
                        }


                    else:
                        echo "Not supported yet"

            # POST
            of HttpPost:
            
                case request.pathInfo:
                    of CreateMovement:

                        var movement_created = MovementTable.db_connect.db_create(
                            request.body.parseJson.to(Movement)
                        )
                        
                        if movement_created:
                            resp Http200, "Success"
                        else:
                            resp Http501, "Failed"
                    
                    of CreateMovementCombo:
                        
                        # add row to movement combo table
                        var 
                            new_movement_combo_request = request.body.parseJson.to(NewMovementComboRequest)
                            combo_id = MovementComboTable.db_connect.db_create(
                                new_movement_combo_request.movement_combo
                            )

                        # If that went through, and we have at least one movement combo id
                        # then let's make movement assignments
                        if combo_id and new_movement_combo_request.movement_ids:
                            var 
                                assignments_table = MovementComboAssignmentTable.db_connect
                                combo_assignments_made: seq[int]

                            # Create new movement assignment for each new movement id
                            for movement_id in new_movement_combo_request.movement_ids:
                                
                                combo_assignments_made.add(
                                    assignments_table.db_create(
                                        MovementComboAssignment(
                                            movement_id : movement_id, 
                                            movement_combo_id : combo_id
                                        )
                                    )
                                )

                            if combo_assignments_made:

                                resp Http200, "Assignments created successfully"

                            else:

                                resp Http501, "Either no combo id or there's no movement ids"


            # I seem to only need GET and POST
            else:

                echo "Not sure how to handle that method"


var server = initJester(match)
server.serve()