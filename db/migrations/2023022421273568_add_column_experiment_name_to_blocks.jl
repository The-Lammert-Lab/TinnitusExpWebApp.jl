module AddColumnExperimentNameToBlocks

import SearchLight.Migrations: add_columns, remove_columns, add_index, remove_index

function up()
    add_columns(:blocks, [
        :experiment_name => :string,
    ])
    add_index(:blocks, :experiment_name)
end

function down()
    remove_index(:blocks, :experiment_name)

    remove_columns(:blocks, [
      :experiment_name
    ])
end

end
