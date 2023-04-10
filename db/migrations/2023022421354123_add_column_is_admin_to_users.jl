module AddColumnIsAdminToUsers

import SearchLight.Migrations: add_columns, remove_columns, add_index, remove_index

function up()
    add_columns(:users, [:is_admin => :bool])
end

function down()
    remove_columns(:users, [:user_id])
end

end
