# Boonorbust

# To rollback production DB
- fly ssh console
- cd bin
- Determine version to rollback to from `version` column in `schema_migrations` table
- exec ./boonorbust eval "Ecto.Migrator.run(Boonorbust.Repo, :down, to: copied_from_version_column)"

 # TODO
 - Introduce Google Sign In
 - Introduce Local Currency for User
 - Introduce Dividend Histories
 - Calculate dividends earned per asset
