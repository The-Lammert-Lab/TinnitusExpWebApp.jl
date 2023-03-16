module AddColumnUserIdToUserExperiments

import SearchLight.Migrations: add_columns, remove_columns, add_index, remove_index

function up()
    add_columns(:userexperiments, [:user_id => :int])
    add_index(:userexperiments, :user_id)
end

function down()
    remove_index(:userexperiments, :user_id)

    remove_columns(:userexperiments, [:user_id])
end

end
