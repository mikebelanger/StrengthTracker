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
                                                         .db_read
                        resp %*all_movements

                    of ReadAllMovementAttrs:
                        let movement_table = MovementTable.db_connect

                        resp %*{
                            "planes" : movement_table.select("plane").distinct().get().mapIt(it{"plane"}),
                            "areas" : movement_table.select("area").distinct().get().mapIt(it{"area"}),
                            "concentric_types" : movement_table.select("concentric_type").distinct().get().mapIt(it{"concentric_type"}),
                            "symmetries" : movement_table.select("symmetry").distinct().get().mapIt(it{"symmetry"})
                        }


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
                                .map(proc (j: JsonNode): NewMovement =

                                    # convert each one into a Movement
                                    try:
                                        result = j.to(NewMovement)
                                    except:
                                        echo getCurrentExceptionMsg()

                                )
                                # only insert ones that are complete
                                .filterIt(it.is_complete)
                                .map(db_create)
                            
                        if movement_creation.worked:
                            resp Http200, "Success"
                        else:
                            resp Http501, "Failed"

                    of ReadMovement:

                        let 
                            movement_table = MovementTable.db_connect
                            existing_movement = 
                                request.body.interpretJson
                                .map(proc (j: JsonNode): int =
                                    
                                    try:
                                        result = j{"id"}.getInt
                                    except:
                                        echo getCurrentExceptionMsg()

                                ).map(proc(id: int): JsonNode =

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
                                .map(proc (jnode: JsonNode): ExistingMovement =
                                    try:
                                        result = jnode.to(ExistingMovement)
                                    except:
                                        echo getCurrentExceptionMsg()
                            
                                )
                                .filterIt(it.is_complete)
                                .map(proc (em: ExistingMovement): bool =

                                    # Should only be one movement with the id, but just in case
                                    result = movement_table.where("id", "=", em.id)
                                                           .db_update(em.obj_to_json)
                                )
    
                        
                        if existing_movements_updated.allIt(it):
                            resp Http200, "Movement updated successfully"
                        else:
                            resp Http501, "Error updating movement"

                    
                    of CreateMovementCombo:
                        
                        # add row to movement combo table
                        var 
                            movement_combo_creation = 

                                request.body.interpretJson
                                .map(proc (j: JsonNode): NewMovementCombo =

                                    try:
                                        result = j.to(NewMovementCombo)
                                    except:
                                        echo getCurrentExceptionMsg()

                                # commit our new movement combo to the database, and return the object with its db id
                                ).map(db_create)

                        if movement_combo_creation.worked:

                            resp Http200, "Assignments created successfully"

                        else:

                            resp Http501, "Either no combo id or there's no movement ids"


            # I seem to only need GET and POST
            else:

                echo "Not sure how to handle that method"


var server = initJester(match)
server.serve()