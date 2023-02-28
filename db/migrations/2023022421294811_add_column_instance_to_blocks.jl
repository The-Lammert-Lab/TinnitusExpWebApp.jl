module AddInstanceColumnToBlocks

import SearchLight.Migrations: add_columns, remove_columns, add_index, remove_index

function up()
    add_columns(:blocks, [
        :instance => :int
    ])
    add_index(:blocks, :instance)
end

function down()
    remove_index(:blocks, :instance)

    remove_columns(:blocks, [
      :instance
    ])
end

end
