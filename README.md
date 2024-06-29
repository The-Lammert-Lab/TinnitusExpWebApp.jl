# TinnitusExpBackEnd.jl

Codebase for website to run the tinnitus experimental protocol built using [Genie Framework](https://genieframework.com/).

Contains functionality for subject and admin users, careful organization and storage of data, dynamically generated pages,
creation of unique protocols, assigment of protocols to subjects, and more. 

To set up and host the website locally, follow these steps in the Julia REPL:

```Julia
>pkg add Genie
using Genie
Genie.lodapp()
```

Check the database connection in `db/connection.yml` and make sure either the sqlite database exists or the other database is active.
To set up the connection:
```Julia
>pkg add SearchLight
using SearchLight
SearchLight.Migrations.init() # Create the schema_migrations table
SearchLight.Migrations.allup() # Run all migrations in schema_migrations
SearchLight.Migrations.status() # Check that all migrations print as "UP"
```

Finally, to locally host the website, simply run `up()`.

Work in progress as of June 2024.
