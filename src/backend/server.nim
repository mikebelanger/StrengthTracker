# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import json
import ../app_types, ../app_routes, database_schema
import allographer/query_builder
import jester, asyncdispatch
import sequtils, strutils, algorithm
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

                    of ReadAllUsers:

                        var all_users = UserTable.db_connect
                                                 .select
                                                 .get()
                                                 .into(Existing, User)
                        resp %*all_users

                    of ReadAllMovementComboGroups:

                        var 
                            all_assignments = MovementComboTable.db_connect
                                                                .select
                                                                .get()
                                                                .into(Existing, MovementCombo)
                                                                .map(proc (mc: MovementCombo): MovementComboGroup =

                                                                    result = MovementComboGroup(
                                                                        movement_combo: mc,
                                                                        movements: MovementComboAssignmentTable.db_connect
                                                                                                               .select
                                                                                                               .where("movement_combo_id", "=", mc.id)
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
                                            to_insert_array.add(%*{"movement_id": m.id, "movement_combo_id" : nmcr.movement_combo.id})

                                        return MovementComboAssignmentTable.db_connect.insertID(to_insert_array)

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

                    of ReadActiveRoutine:
                        
                        let active_routine =

                            request.body.to_json.get_id.map(proc (user_id: int): seq[Routine] =

                                try:
                                    result =
                                        RoutineTable.db_connect.query_matching_all((

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

                        # load routine based on its user, and that
                    of ReadRoutineAssignments:

                        # what we really want is the movement combos for this
                        # routine, but we have to query pretty indirectly to get them.

                        # first through the routine assignments
                        let movement_combos = 
                            request.body.db_read(Routine, from_table = RoutineTable)
                                        .map(proc (routine: Routine): seq[JsonNode] =

                                            return RoutineAssignmentTable
                                                        .db_connect
                                                        .query_matching_any(
                                                            (routine_id: routine.id)
                                                        )
                                                        .orderBy("routine_order", Asc)
                                                        .get()
                                                        .add_foreign_objs

                                        )
                                        .concat
                                        .into(Existing, RoutineAssignment)
                                        .map(proc (ra: RoutineAssignment): seq[JsonNode] =

                                            return MovementComboAssignmentTable
                                                        .db_connect
                                                        .query_matching_all(
                                                            (movement_combo_id: ra.movement_combo.id)
                                                        )
                                                        .get()
                                                        .add_foreign_objs

                                        )
                                        .concat
                                        .into(Existing, MovementComboAssignment)
                                
                        case movement_combos.len:

                            of 0:
                                resp Http501, "Error reading routine assignments"
                            else:
                                resp %*movement_combos      


            # I seem to only need GET and POST
            else:

                echo "Not sure how to handle that method"


var server = initJester(match)
server.serve()