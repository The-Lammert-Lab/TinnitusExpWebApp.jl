using SearchLight
using ..Main.UserApp.Users

# Function to seed users
function seed_users()
    # Create an admin user if it doesn't already exist
    if isnothing(findone(Users.User, username="admin"))
        admin_user = Users.User(
            username = "admin",
            password = "adminpass" |> Users.hash_password,
            is_admin = true
        )
        save!(admin_user)
        @info "Admin user created"
    else
        @info "Admin user already exists"
    end

    # Create a test user if it doesn't already exist
    if isnothing(findone(Users.User, username="testuser"))
        test_user = Users.User(
            username = "testuser",
            password = "testpass" |> Users.hash_password
        )
        save!(test_user)
        @info "Test user created"
    else
        @info "Test user already exists"
    end
end

# Run the seeding function
seed_users()
