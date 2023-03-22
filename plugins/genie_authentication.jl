using Genie

using GenieAuthentication
import ..Main.UserApp.AuthenticationController
import ..Main.UserApp.Users
import SearchLight: findone

export current_user
export current_user_id
export username

current_user() = findone(Users.User, id = get_authentication())
current_user_id() = current_user() === nothing ? nothing : current_user().id

function username(id::Int)
    user = findone(Users.User; id = id)
    return user === nothing ? nothing : user.username
end

function username(id::DbId)
    user = findone(Users.User; id = id)
    return user === nothing ? nothing : user.username
end

route("/login", AuthenticationController.show_login, named = :show_login)
route("/login", AuthenticationController.login, method = POST, named = :login)
route("/success", AuthenticationController.success, method = GET, named = :success)
route("/logout", AuthenticationController.logout, named = :logout)

#===#

# route("/register", AuthenticationController.show_register, named = :show_register)
# route("/register", AuthenticationController.register, method = POST, named = :register)
