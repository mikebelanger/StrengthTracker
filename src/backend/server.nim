# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import jester
import json
import db_crud
import ../app_types
import db_sqlite
import options

let db = open("./src/backend/v27.db", "", "", "")

proc generate_response(db_results: DbCRUDResult): JsonNode =
  var content: string = 
    case db_results.feedback_type:
    of createSuccess: "successfully inserted movement into db!: " 
    of createAlreadyExists: "db entry already exists!: "
    of createInsufficientInput: "not enough input to add to database: "
    of dbUndefinedError: "undefined error"

  return %*{"content": content & db_results.feedback_details}

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

      resp generate_response(create_result)

    # otherwise, let the user know the movement isn't valid
    else:

      create_result = (feedback_type: createInsufficientInput,
                      feedback_details: "likely a missing attribute to create movement object: " & user_input.getStr,
                      db_id: 0)

      resp generate_response(create_result)
# READ
# UPDATE
# DELETE