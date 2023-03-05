module AssignTestUserExampleExperiments

using SearchLight
using ..Main.UserApp.Users
using ..Main.UserApp.Experiments
using ..Main.UserApp.UserExperiments

function up()
    exps = (findone(Experiment, name = "TestExperiment_1"), 
            findone(Experiment, name = "TestExperiment_2")
    )
    usr = findone(User, username = "testuser")

    if nothing in exps
        println("Check migration status and make sure `create example experiments` is up")
    else
        foreach(exps) do ex
            UserExperiment(;
                user_id = usr.id,
                experiment_name = ex.name,
                instance = 1,
                percent_complete = 0.0
            ) |> save!
        end
        UserExperiment(;
            user_id = usr.id,
            experiment_name = exps[2].name,
            instance = 2,
            percent_complete = 25.0
        ) |> save!
    end
end

function down()
    findone(UserExperiment, experiment_name = "TestExperiment_1") |> delete
    findone(UserExperiment, experiment_name = "TestExperiment_2", instance = 1) |> delete
    findone(UserExperiment, experiment_name = "TestExperiment_2", instance = 2) |> delete
end

end
