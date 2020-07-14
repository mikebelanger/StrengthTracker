# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import json
import ../app_types, ../app_routes, database_schema
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
                                                         .select()
                                                         .get()
                        resp %*all_movements

                    of ReadAllMovementAttrs:
                        let 
                            movement_table = MovementTable.db_connect
                            attributes = @["plane", "area", "concentric_type", "symmetry"]

                        var response = parseJson("{}")

                        for attr in attributes:
                            response{"all_" & attr} = %*movement_table.select(attr).distinct().get().mapIt(it{attr})

                        resp response

                    of ReadAllUsers:

                        var all_users = UserTable.db_connect
                                                 .select()
                                                 .get()

                        echo all_users
                        resp %*all_users

                    else:
                        echo "Not supported yet"

            # POST
            of HttpPost:
            
                case request.pathInfo:
                    of CreateMovement:

                        let 
                            movement_creation = 

                                # interpret json into sequence
                                request.body.interpretJson
                                            .db_create(Movement, into = MovementTable)
                            
                        if movement_creation.worked:
                            resp Http200, "Success"
                        else:
                            resp Http501, "Failed"

                    of ReadMovement:

                        let 
                            movement_table = MovementTable.db_connect
                            existing_movement = 
                                request.body.interpretJson
                                .mapIt(it.get_id)
                                .map(proc(id: int): JsonNode =

                                    result = movement_table.where("id", "=", id)
                                                           .first
                                )

                        # TODO: fix this for multiple movement creation
                        case existing_movement.len:
                            of 0:
                                resp Http501, "nothing found"
                            else:
                                resp existing_movement[0]

                    of UpdateMovement:

                        let 
                            movement_table = MovementTable.db_connect
                            existing_movements_updated = 
                                
                                # Interpret incoming JSON, convert to an existing movement
                                request.body.interpretJson
                                            .db_update(Movement, into = MovementTable)
    
                        
                        if existing_movements_updated.worked:
                            resp Http200, "Movement updated successfully"
                        else:
                            resp Http501, "Error updating movement"

                    
                    of CreateMovementCombo:
                        
                        # add row to movement combo table
                        var 
                            movement_combo_creation = 

                                request.body.interpretJson
                                            .db_create(MovementCombo, into = MovementComboTable)

                        if movement_combo_creation.worked:

                            resp Http200, "Assignments created successfully"

                        else:

                            resp Http501, "Either no combo id or there's no movement ids"

                    of CreateMovementComboAssignment:

                        let
                            combo_assignment_creation =
                                
                                request.body.interpretJson
                                            .db_create(MovementComboAssignment, MovementComboAssignmentTable)

                        if combo_assignment_creation.worked:

                            resp Http200, "Assignment made"
                        
                        else:

                            resp Http501, "Error creating assignment"


            # I seem to only need GET and POST
            else:

                echo "Not sure how to handle that method"


var server = initJester(match)
server.serve()