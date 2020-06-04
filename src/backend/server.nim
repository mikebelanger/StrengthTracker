# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import jester
import json
import db_crud
import ../app_types
import db_sqlite
import options

let db = open("./src/backend/v27.db", "", "", "")

proc generateResponse(db_results: CRUDResult): JsonNode =
  var content: string = 
    case db_results.feedback_type:
    of createSuccess: "successfully inserted movement into db!: " 
    of createAlreadyExists: "db entry already exists!"
    of createInsufficientInput: "not enough input to add to database"
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
      crud_result: CRUDResult
      movement: Option[Movement]
      user_input = request.body.parseJson

    if user_input.contains("name") and user_input["name"].getStr.len > 0:

      movement = user_input.to_movement
      
      if isSome(movement):
        crud_result = db.create_movement(get(movement))

        resp generateResponse(crud_result)

      else:

        crud_result = (feedback_type: createInsufficientInput,
                    feedback_details: "likely a missing attribute to create movement object: " & user_input.getStr,
                    db_id: 0)

        resp generateResponse(crud_result)

    else:
      crud_result = (feedback_type: createInsufficientInput,
                  feedback_details: "Missing name",
                  db_id: 0)

      resp generateResponse(crud_result)

# READ
# UPDATE
# DELETE