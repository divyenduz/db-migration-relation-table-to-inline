ALTER TABLE
  User
ADD
  COLUMN address CHAR(25) COLLATE utf8 NOT NULL;

UPDATE
  User
  INNER JOIN _AddressToUser ON _AddressToUser.B = User.id

ALTER TABLE
  User
ADD FOREIGN KEY(address) REFERENCES Address(`id`);

SET
  User.address = _AddressToUser.A;