module CreateAdminUser

using SearchLight
using ..Main.UserApp.Users

function up()
    Users.User(
        username = "admin",
        password = "adminpass" |> Users.hash_password,
        is_admin = true,
    ) |> save!
end

function down()
    findone(Users.User, username = "admin") |> delete
end

end
