# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import jester
import json
import db_crud
import ../app_types
import db_sqlite

template respond_with_json(stmts: untyped) =
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
    
    respond_with_json:
      request.body.parseJson
                  .to(Movement)
                  .db_insert
    

# READ
# UPDATE
# DELETE