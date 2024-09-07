# Boonorbust

# To rollback production DB
- fly ssh console
- cd bin
- Determine version to rollback to from `version` column in `schema_migrations` table
- exec ./boonorbust eval "Ecto.Migrator.run(Boonorbust.Repo, :down, to: copied_from_version_column)"

 # TODO
- Introduce Google Sign In
- Introduce Local Currency for User instead of root_asset
- Introduce Dividend Histories
- Calculate dividends earned per asset
- Introduce trading_currency to Assets
- Attach a percentage to tag. A REIT can be X% Retail Y% Commercial for example
- Change asset to be a shared entity instead of per user. User will have a user_asset which is specific to each user.
- profit.cost need to be recalculated when we input a trade that is back dated
