module AddColumnExperimentNameToUserExperiments

import SearchLight.Migrations: add_columns, remove_columns, add_index, remove_index

function up()
    add_columns(:userexperiments, [
        :experiment_name => :string
    ])
    add_index(:userexperiments, :experiment_name)
end

function down()
    remove_index(:userexperiments, :experiment_name)

    remove_columns(:userexperiments, [
      :experiment_name
    ])
end

end
