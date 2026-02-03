
CONNECT TO iiq_pl;

DROP TABLESPACE identityiq_pl_ts;
DROP BUFFERPOOL identityiq_pl_bp;
DROP SCHEMA identityiqPlugin RESTRICT;
COMMIT;

Disconnect iiq_pl;

DROP DATABASE iiq_pl;
