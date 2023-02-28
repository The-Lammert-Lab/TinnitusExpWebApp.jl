module AddColumnNBlocksToBlocks

import SearchLight.Migrations: add_columns, remove_columns, add_index, remove_index

function up()
    add_columns(:blocks, [
        :n_blocks => :int,
    ])
end

function down()
    remove_columns(:blocks, [
      :n_blocks,
    ])
end

end
