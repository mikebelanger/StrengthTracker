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
      name = user_input["name"].getStr
      movement_plane = get_movement_plane(user_input["movement_plane"].getStr)
      body_area = get_body_area(user_input["body_area"].getStr)
      movement_type = get_movement_type(user_input["movement_type"].getStr)
      movement_category = get_movement_category(user_input["movement_category"].getStr)

    
    if name.len() > 0 and movement_plane.isSome and body_area.isSome and movement_type.isSome and
      movement_category.isSome:
    
      #   # now insert into DB
      var movement_id = db.create_movement(name = name, movement_plane = movement_plane.get, 
                                          body_area = body_area.get, movement_type = movement_type.get, 
                                          movement_category = movement_category.get)

    # echo request.body
    # echo parseJson(request.body).getOrDefault(key = "data").getStr()
      resp %*{"content": "successfully inserted movement into db!"}
    
    else:
      echo "movement_plane", movement_plane.isSome
      echo "body_area", body_area.isSome
      echo "movement_type", movement_type.isSome
      echo "movement_category", movement_category.isSome

      echo user_input

      resp %*{"content": "unable to insert into db!"}
    # echo request