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
                                                         .into(Existing, Movement)
                        resp %*all_movements

                    of ReadAllMovementAttrs:

                        let response = 
                            %*{ "planes" : MovementPlane.mapIt($it),
                                "areas"  : MovementArea.mapIt($it),
                                "concentric_types" : ConcentricType.mapIt($it),
                                "symmetries": Symmetry.mapIt($it)
                            }

                        resp response

                    of ReadAllUsers:

                        var all_users = UserTable.db_connect
                                                 .select
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

                        let movement_read = request.body.db_read(Movement, from_table = MovementTable)

                        case movement_read.len:

                            of 0:
                                resp Http501, "nothing found"
                            
                            else:
                                resp %*movement_read
                            

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

                    of CreateSession:

                        let session_created =
                            request.body.db_create(Session, into = SessionTable)

                        case session_created.len:
                            of 0:
                                resp Http501, "Could not load session"
                            else:
                                resp %*session_created                   

                    of ReadSession:

                        let session =
                            request.body.db_read(Session, from_table = SessionTable)

                        case session.len:
                            of 0:
                                resp Http501, "Could not load session"
                            else:
                                resp %*session                   

                    of ReadUser:

                        let user =
                            request.body.db_read(User, from_table = UserTable)

                        case user.len:
                            of 0:
                                resp Http501, "Could not load user"
                            else:
                                resp %*user                   


                    of ReadRoutine:

                        # in addition to reading the routine, this loads the routine
                        # assignments associated to this particula routine, for convenience.

                        let routines = 
                            request.body.db_read(Routine, from_table = RoutineTable)
                                        .map(proc (routine: Routine): seq[JsonNode] =

                                            let result = 
                                                RoutineAssignmentTable
                                                        .db_connect
                                                        .query_matching_all(
                                                            (routine_id: routine.id)
                                                        )
                                                        .orderBy("order", Asc)
                                                        .get()
                                                        .add_foreign_objs

                                        )
                                        .concat
                                        .into(Existing, RoutineAssignment)
                                
                        case routines.len:

                            of 0:
                                resp Http501, "Error reading routine assignments"
                            else:
                                resp %*routines      


            # I seem to only need GET and POST
            else:

                echo "Not sure how to handle that method"


var server = initJester(match)
server.serve()