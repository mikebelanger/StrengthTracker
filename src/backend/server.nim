# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import jester
import json
import ../app_types
import db_crud

template render_json_for(stmts: untyped) =
  try:            
    var crud = stmts
    resp %*crud
  except:
    resp %*CRUDOBject(status: Error, 
                      error: getCurrentExceptionMsg(), 
                      content: @[parseJson("{}")])

routes:

  # get "/welcome.json":
  #   resp %*{"content": "This finally works!"}

  # get "/some_other_val.json":
  #   resp %*{"content": "this works loading too"}
  get "/":
    redirect "/index.html"

  # CREATE

  post "/create_movement.json":
    
    render_json_for:
      request.body.parseJson
                  .convert_to(Movement)
                  .db_create

  # READ

  get "/read_distinct_movement_attributes.json":

    render_json_for:

      CRUDObject(status: Complete, 
                  content: @[
                    %*{ "plane": db_read_unique("movement", "plane"),
                        "area": db_read_unique("movement", "area"),
                        "concentric_type": db_read_unique("movement", "concentric_type"),
                        "symmetry": db_read_unique("movement", "symmetry")
                    }
                  ])
  # UPDATE
  # DELETE