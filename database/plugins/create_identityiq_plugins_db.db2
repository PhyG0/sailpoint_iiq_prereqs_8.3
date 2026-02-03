
DISCONNECT iiq;

-- DB2 has a name size limit we can't use identityiq like the others.
-- You may also consider adding codeset and collation options.
CREATE DATABASE IIQ_PL AUTOMATIC STORAGE YES PAGESIZE 32 K;

CONNECT TO iiq_pl;

CREATE SCHEMA identityiqPlugin AUTHORIZATION identityiqPlugin;

CREATE BUFFERPOOL identityiq_pl_bp IMMEDIATE SIZE 2000 AUTOMATIC PAGESIZE 32 K;

CREATE TABLESPACE identityiq_pl_ts PAGESIZE 32 K
     MANAGED BY AUTOMATIC STORAGE
     INITIALSIZE 128 M
     INCREASESIZE 128 M
     BUFFERPOOL identityiq_pl_bp;

-- Grant everything to identityiqPlugin user for simplicity in dev/poc environments.
-- This is not necessary for production environments.  The minimal set of permissions is:
--   - CONNECT, CREATETAB, DATAACCESS on database
--   - USAGE of all sequences defined in the script

GRANT DBADM ON DATABASE TO USER identityiqPlugin;

DISCONNECT iiq_pl;

CONNECT TO iiq;
