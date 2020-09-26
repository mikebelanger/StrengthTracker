import json, schema, crud

let new_users = @[
    """{
        "name" : "Mike",
        "email": "mikejamesbelanger@gmail.com"
        }
    """,

    """{
        "megrer": erger\\
        }
    """
    ]

var new_users_json: seq[JsonNode]

for new_user in new_users:
    try:
        new_users_json.add(
            new_user.parseJson
        )

    except:
        echo getCurrentExceptionMsg()
        continue

echo new_users_json.create(User)
