# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import jester
import json
import db_crud
import ../app_types
import db_sqlite
import options

routes:

  get "/welcome.json":
    resp %*{"content": "This finally works!"}

  get "/some_other_val.json":
    resp %*{"content": "this works loading too"}

# CREATE
  post "/create_movement.json":

    var 
      create_result: DbCRUDResult
      user_input = request.body.parseJson
      movement = user_input.to_movement
      
    # if we have a valid, complete Movement object, try to enter into db
    if isSome(movement):
      create_result = db.create_movement(get(movement))

      resp %*create_result
# READ
# UPDATE
# DELETE