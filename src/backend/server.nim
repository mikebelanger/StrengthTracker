# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import jester
import json
import db_crud
import ../app_types
import db_sqlite
import options

let db = open("./src/backend/v27.db", "", "", "")

routes:

  get "/welcome.json":
    resp %*{"content": "This finally works!"}

  get "/some_other_val.json":
    resp %*{"content": "this works loading too"}

  post "/create_movement.json":
 
    var 
      user_input = request.body.parseJson
      movement = user_input.to_movement

    if isSome(movement) and db.create_movement(get(movement)) != 0:

      resp %*{"content": "successfully inserted movement into db!"}

    else:
      
      resp %*{"content": "unable to insert into db!"}