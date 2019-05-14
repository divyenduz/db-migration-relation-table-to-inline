ALTER TABLE
  User
ADD
  COLUMN address CHAR(25) CHARACTER SET utf8;
 
UPDATE
  User
  INNER JOIN _AddressToUser ON _AddressToUser.B = User.id
SET
  User.address = _AddressToUser.A

ALTER TABLE
  User
ADD
  CONSTRAINT FOREIGN KEY(address) REFERENCES Address(id);

ALTER TABLE
  User
MODIFY
  address CHAR(25) CHARACTER SET utf8 NOT NULL;