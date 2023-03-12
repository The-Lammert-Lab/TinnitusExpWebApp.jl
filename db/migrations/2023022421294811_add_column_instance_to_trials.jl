module AddInstanceColumnToTrials

import SearchLight.Migrations: add_columns, remove_columns, add_index, remove_index

function up()
    add_columns(:trials, [
        :instance => :int
    ])
    add_index(:trials, :instance)
end

function down()
    remove_index(:trials, :instance)

    remove_columns(:trials, [
      :instance
    ])
end

end
