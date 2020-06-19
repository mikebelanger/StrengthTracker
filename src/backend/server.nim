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
    resp %*CRUDOBject(status: Error, error: getCurrentExceptionMsg())

routes:

  get "/welcome.json":
    resp %*{"content": "This finally works!"}

  get "/some_other_val.json":
    resp %*{"content": "this works loading too"}

# CREATE
  post "/create_movement.json":
    
    render_json_for:
      request.body.parseJson
                  .to(Movement)
                  .db_insert

# READ
# UPDATE
# DELETE