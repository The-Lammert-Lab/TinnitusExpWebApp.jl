module AddColumnUserIdToTrials

import SearchLight.Migrations: add_columns, remove_columns, add_index, remove_index

function up()
    add_columns(:trials, [
        :user_id => :int
    ])
    add_index(:trials, :user_id)
end

function down()
    remove_index(:trials, :user_id)

    remove_columns(:trials, [
      :user_id
    ])
end

end
