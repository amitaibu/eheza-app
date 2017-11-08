module User.Encoder exposing (encodeUser)

import Json.Encode exposing (Value, int, string, object, list)
import Restful.Endpoint exposing (encodeEntityId)
import User.Model exposing (User)


{-| This is mostly for caching the user in local storage.
It needs to be the inverse of `decodeUser`.
-}
encodeUser : User -> Value
encodeUser user =
    object
        [ ( "id", int user.id )
        , ( "label", string user.name )
        , ( "avatar_url", string user.avatarUrl )
        , ( "clinics", list (List.map encodeEntityId user.clinics) )
        ]
