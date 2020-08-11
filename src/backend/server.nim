# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import json
import ../app_types, ../app_routes, database_schema
import allographer/query_builder
import jester, asyncdispatch
import sequtils, strutils
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
                        let 
                            all_movements = MovementTable.select()
                                                         .get()
                                                         .into(Existing, Movement)
                            columns = Movement().get_obj_columns


                        resp %*{"all_movements" : all_movements, 
                                "columns": columns}

                    of ReadAllUsers:

                        var all_users = UserTable.select
                                                 .get()
                                                 .into(Existing, User)
                        resp %*all_users

                    of ReadAllMovementComboGroups:

                        var 
                            all_assignments = 
                                MovementComboTable.select
                                    .get()
                                    .into(Existing, MovementCombo)
                                    .map(proc (mc: MovementCombo): MovementComboGroup =

                                        result = MovementComboGroup(
                                            movement_combo: mc,
                                            movements: 
                                                MovementComboAssignmentTable
                                                    .select
                                                    .where($MovementComboTable.id, "=", mc.id)
                                                    .get()
                                                    .add_foreign_objs
                                                    .into(Existing, MovementComboAssignment)
                                                    .mapIt(it.movement)
                                        )

                                        return result

                                    )


                        resp %*all_assignments

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
                                resp Http501, "Error creating movement combo"
                            else:
                                resp %*movement_combo_creation                           

                    of CreateMovementComboAssignment:

                        let
                            combo_assignment_creation =

                                request.body.to_json
                                    .map(proc (j: JsonNode): MovementComboGroup =

                                        try:
                                            return j.to(MovementComboGroup)
                                        
                                        except:
                                            echo "cannot convert request to MovementComboGroup: "
                                            echo getCurrentExceptionMsg()

                                    )
                                    .map(proc (nmcr: MovementComboGroup): seq[int] =

                                        var to_insert_array: seq[JsonNode]

                                        for m in nmcr.movements:
                                            to_insert_array.add(%*{$MovementTable.id: m.id, $MovementComboTable.id : nmcr.movement_combo.id})

                                        return MovementComboAssignmentTable.insertID(to_insert_array)

                                    )
                                    .concat
                                    .filterIt(it > 0)
                                    .db_read_from_id(into = MovementComboAssignmentTable)
                                    .add_foreign_objs
                                    .into(Existing, MovementComboAssignment)
                                

                        case combo_assignment_creation.len:

                            of 0:
                                resp Http501, "Error updating movement"
                            else:
                                resp %*combo_assignment_creation

                    of CreateSession:
                        
                        # first load the active routine for this user
                        let routine = request.body.db_read(Routine, from_table = RoutineTable)

                        case routine.len:
                            of 0:
                                resp Http501, "Could not load routine"
                            else:
                                resp %*routine                   


                    of ReadUser:

                        let user =
                            request.body.db_read(User, from_table = UserTable)

                        case user.len:
                            of 0:
                                resp Http501, "Could not load user"
                            else:
                                resp %*user                   

                    of ReadActiveRoutine:
                        
                        let active_routine =

                            request.body.to_json.get_id.map(proc (user_id: int): seq[Routine] =

                                try:
                                    result =
                                        RoutineTable.query_matching_all((

                                            user_id: user_id,
                                            active: true

                                        ))
                                        .get()
                                        .add_foreign_objs
                                        .into(Existing, Routine)

                                except:
                                    echo "read active routine error: ", getCurrentExceptionMsg()

                            )
                            .concat

                        case active_routine.len:
                            of 0:
                                resp Http501, "No active routine found"
                            else:
                                resp %*active_routine

                    
                    # of UpdateActiveRoutine:

                    #     let updated_active_routine =
                    #         request.body
                    #         .to_json

                    #     if updated_active_routine:
                    #         resp Http200
                    #     else:
                    #         resp Http501, "could not update all assignments"


            # I seem to only need GET and POST
            else:

                echo "Not sure how to handle that method"


var server = initJester(match)
server.serve()