# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import jester
import json
import db_crud
import ../app_types

template render_json_for(stmts: untyped) =
  try:            
    var crud = stmts
    resp %*crud
  except:
    resp %*CRUDOBject(status: Error, error: getCurrentExceptionMsg(), content: parseJson("{}"))

routes:

  get "/welcome.json":
    resp %*{"content": "This finally works!"}

  get "/some_other_val.json":
    resp %*{"content": "this works loading too"}

# CREATE

  post "/create_movement.json":
    
    render_json_for:
      request.body.parseJson
                  .db_create(Movement)
  
#   post "/create_movement_combo.json":

#     render_json_for:
#       request.body.parseJson
#                   .to(MovementCombo)
#                   .db_insert
# READ

  post "/read_movement_info":

    render_json_for:
      request.body.parseJson
                  .db_read(MovementCategories, with="name", "=", "Combo: A")
#   post "/db_read_all_movements.json":

#     render_json_for:
#       db_read_all_rows_for(Movement())

#   post "/read_movement_by_name.json":

#     render_json_for:
#       Movement(name: request.body.parseJson.getStr).db_read

#   post "/get_movement_combo.json":

#     render_json_for:
#       MovementCombo(name: request.body.parseJson.getStr).db_read

# UPDATE
# DELETE