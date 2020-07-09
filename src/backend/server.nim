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

                        let 
                            create_movement_worked = 

                                # interpret json into sequence
                                request.body.interpretJson.map(proc (j: JsonNode): Movement =

                                    # convert each one into a Movement
                                    try:
                                        result = j.to(Movement)
                                    except:
                                        echo getCurrentExceptionMsg()

                                )
                                # only insert ones that are complete
                                .filterIt(it.is_complete)
                                .map(proc (m: Movement): int =

                                    result = MovementTable.db_connect.db_create(m)

                                )
                            
                        if create_movement_worked:
                            resp Http200, "Success"
                        else:
                            resp Http501, "Failed"

                    of UpdateMovement:
                        
                        let 
                            existing_movements_updated = 
                                
                                # Interpret incoming JSON, convert to an existing movement
                                request.body.interpretJson.map(proc (jnode: JsonNode): ExistingMovement =
                                    try:
                                        result = jnode.to(ExistingMovement)
                                    except:
                                        echo getCurrentExceptionMsg()
                            
                                )
                                .filterIt(it.is_complete)
                                .map(proc (em: ExistingMovement): bool =

                                    # Should only be one movement with the id, but just in case
                                    MovementTable.db_connect.query_matching_all((

                                        id: em.id
                                    
                                    # finally commit to db
                                    )).db_update(em)
                                )
    
                        
                        if existing_movements_updated:
                            resp Http200, "Movement updated successfully"
                        else:
                            resp Http501, "Error updating movement"

                    
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