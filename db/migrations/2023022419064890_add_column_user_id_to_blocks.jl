module AddColumnUserIdToBlocks

import SearchLight.Migrations: add_columns, remove_columns, add_index, remove_index

function up()
    add_columns(:blocks, [
        :user_id => :int
    ])
    add_index(:blocks, :user_id)
end

function down()
    remove_index(:blocks, :user_id)

    remove_columns(:blocks, [
      :user_id
    ])
end

end
