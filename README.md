## Introduction

This example demonstrates migration from relation table to inline link. The migration engine used in this case is Prisma but the concept applies to any similar migration. 

Note that all files mentioned in this readme are present in the root directory. 
Note that we assume that you are on a relatively newer version of Prisma (1.31+). 
Note that we assume that you have a Prisma server running with the `datamodel.prisma` deployed and the system contains some data that needs migration. In case you need to seed some data to test this example, please use `sample.graphql` or create your own data.

In terms of SQL we want to migrate from `source.sql` to `target.sql`. 
In terms of Prisma we want to migrate from `datamodel.prisma` to `datamodel-target.prisma`.

The following strategy will incur a small downtime but if any downtime is not feasible, we can take alternatives/workarounds that would be mentioned inline. 

1. From `alter.sql`, run the first SQL statement to create a new column that would reference the foreign table in an inline manner. 
```
ALTER TABLE
  User
ADD
  COLUMN address CHAR(25) COLLATE utf8 NOT NULL;
```

2. From `alter.sql`, run the following update SQL statement to fill this new column with the target value
```
UPDATE
  User
INNER JOIN
  _AddressToUser 
ON 
  _AddressToUser.B = User.id
```

Note that this operation requires mutations to be stopped or altered. If this operation is performed with running mutations, the following two scenarios might happen: 

a. The database will get out of sync with the new data and we would fail to apply the foreign key constraint (required by Prisma for this migration). 
b. The database will be in sync when we apply the foreign key constraint but the subsequent mutation would get the data to be out of sync. Specifically, There would be possibly new entries in `Address` table, `_AddressToUser` table but the newly added column `address` would be `null` for the respective mutations in `User` table and those mutations would start to fail. 

There are various ways in which we can mitigate this situation if stopping mutations for some time is not possible. 

a. Use a SQL trigger to fill/change the newly added `address` column whenever a row is added/updated in `_AddressToUser` table. 
b. Update your application code to fill the newly added `address` column and make a deployment along with step 1.
c. Use an online migartion system like `gh-ost` (requires bin logs to be enabled) or `pt-online-schema-change` (works on triggers)

3. Once the integrity of this foreign key constraint of this newly added `address` column is confirmed in an online/offline migration scenario. From `alter.sql` run the constraint SQL statement to create a foreign key, not null constraints on this column
```
ALTER TABLE
  User
ADD FOREIGN KEY(address) REFERENCES Address(`id`);
```

```
ALTER TABLE
  User
MODIFY
  address CHAR(25) CHARACTER SET utf8 NOT NULL;
```

Note that we haven't deleted the existing table, this would ensure that both older queries and newer queries always work for a seamless migration. 

4. At this moment, our Prisma server is out of sync with the underlying database, to bring that back in sync, copy the contents of `datamodel-target.prisma` to your respective `datamodel` file and run `prisma deploy --no-migrate`.

5. Step 4 should bring your Prisma server in sync with the underlying data structure. Make some queries to confirm that. 

6. From `drop.sql`, issue the SQL statement to delete the relation table. Make some more queries to make sure that the system is functional. With this the migration is complete. 