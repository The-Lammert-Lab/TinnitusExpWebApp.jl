module CreateTableExperiments

import SearchLight.Migrations: create_table, column, columns, pk, add_index, drop_table, add_indices

function up()
  create_table(:experiments) do
    [
      pk()
      columns([
        :stimgen_settings => :string,
        :stimgen_type => :string,
        :n_trials => :int,
        :n_blocks => :int,
        :n_trials_per_block => :int,
        :name => :string,
        :visible => :bool
      ])
    ]
  end

  add_index(:experiments, :name)
end

function down()
  drop_table(:experiments)
end

end
