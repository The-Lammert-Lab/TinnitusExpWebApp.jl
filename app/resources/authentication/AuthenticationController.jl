module AuthenticationController

using Genie, Genie.Renderer, Genie.Renderer.Html
using SearchLight
using SearchLight.Validation
using Logging

using ..Main.UserApp
using ..Main.UserApp.Users
using ..Main.UserApp.GenieAuthenticationViewHelper

using GenieAuthentication
using GenieAuthentication.GenieSession
using GenieAuthentication.GenieSession.Flash
using GenieAuthentication.GenieSessionFileSession

function show_login()
    is_admin = current_user() isa Nothing ? nothing : current_user().is_admin
    html(:authentication, :login; context = @__MODULE__, is_admin)
end

function login()
    try
        user = findone(
            User,
            username = params(:username),
            password = Users.hash_password(params(:password)),
        )
        authenticate(user.id, GenieSession.session(params()))

        if user.is_admin
            redirect("/admin")
        else
            redirect("/profile")
        end
    catch ex
        flash("Authentication failed! ")

        redirect(:show_login)
    end
end

function success()
    html(:authentication, :success, context = @__MODULE__)
end

function logout()
    deauthenticate(GenieSession.session(params()))

    flash("Good bye! ")

    redirect(:show_login)
end

function show_register()
    html(:authentication, :register; context = @__MODULE__)
end

function register()
    try
        user = User(
            username = params(:username) |> strip,
            password = params(:password) |> Users.hash_password,
            is_admin = parse(Bool, params(:is_admin)),
        )

        validator = validate(user)
        if haserrors(validator)
            flash("Invalid: $(errors_to_string(validator))")
            return redirect(:show_register)
        end

        save(user) &&
            flash("""Successfully registered new user: "$(params(:username))". """)
        redirect(:show_register)
    catch ex
        @error ex

        if hasfield(typeof(ex), :msg)
            flash(ex.msg)
        else
            flash(string(ex))
        end

        redirect(:show_register)
    end
end

end
