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
                                                 .select("name", "id", "email")
                                                 .get()
                                                 .into(Existing, User)
                        resp %*all_users

                    else:
                        echo "Not supported yet"

            # POST
            of HttpPost:
            
                case request.pathInfo:
                    of CreateMovement:

                        let 
                            movement_creation = 

                                request.body.db_create(Movement, into = MovementTable)
                            
                        case movement_creation.len:
                            of 0:
                                resp Http501, "Failed"
                            else:
                                resp Http200, "Success"

                    of ReadMovement:

                        let 
                            movement_table = MovementTable.db_connect
                            id = request.body.to_json.get_id

                        case id.len:

                            of 0:
                                resp Http501, "nothing found"
                            
                            else:
                                var movement_find = movement_table.where("id", "=", id[0]).first

                                for m in movement_find:
                                    resp movement_find
                            


                    of UpdateMovement:

                        let 
                            existing_movements_updated = 
                                
                                # Interpret incoming JSON, convert to an existing movement
                                request.body.db_update(Movement, into = MovementTable)
    
                        
                        case existing_movements_updated.len:

                            of 0:
                                resp Http501, "Error updating movement"
                            else:
                                resp %*existing_movements_updated                           

                    
                    of CreateMovementCombo:
                        
                        # add row to movement combo table
                        var 
                            movement_combo_creation = 

                                request.body.db_create(MovementCombo, into = MovementComboTable)

                        case movement_combo_creation.len:

                            of 0:
                                resp Http501, "Error updating movement"
                            else:
                                resp %*movement_combo_creation                           

                    of CreateMovementComboAssignment:

                        let
                            combo_assignment_creation =
                                
                                request.body.db_create(MovementComboAssignment, MovementComboAssignmentTable)

                        case combo_assignment_creation.len:

                            of 0:
                                resp Http501, "Error updating movement"
                            else:
                                resp %*combo_assignment_creation                            


            # I seem to only need GET and POST
            else:

                echo "Not sure how to handle that method"


var server = initJester(match)
server.serve()