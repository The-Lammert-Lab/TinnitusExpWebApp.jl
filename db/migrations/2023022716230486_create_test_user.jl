module CreateTestUser

using SearchLight
using ..Main.UserApp.Users

function up()
    Users.User(username = "testuser", password = "testpass" |> Users.hash_password) |> save!
end

function down()
    findone(Users.User, username = "testuser") |> delete
end

end
