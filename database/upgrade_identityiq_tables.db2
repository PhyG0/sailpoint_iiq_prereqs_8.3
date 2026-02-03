--
-- This script contains DDL statements to upgrade a database schema to
-- reflect changes to the model.  This file should only be used to
-- upgrade from the last formal release version to the current code base.
--

CONNECT TO iiq;

    create table identityiq.spt_bundle_profile_relation (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        bundle_id varchar(32),
        source_bundle_id varchar(32),
        source_profile_id varchar(32),
        source_application varchar(32),
        type varchar(255),
        attribute varchar(322),
        value varchar(450),
        display_value varchar(450),
        required smallint,
        permitted smallint,
        or_member smallint,
        inherited smallint,
        attributes clob(100000000),
        app_status varchar(255),
        hash varchar(128),
        hash_code integer,
        display_value_ci generated always as (upper(display_value)),
        value_ci generated always as (upper(value)),
        attribute_ci generated always as (upper(attribute)),
        primary key (id)
    ) IN identityiq_ts;

    alter table identityiq.spt_bundle_profile_relation
       add constraint FKmagmq7lgmic1artsln48lpcaw
       foreign key (source_application)
       references identityiq.spt_application;

    create index identityiq.FKmagmq7lgmic1artsln48lpcaw on identityiq.spt_bundle_profile_relation (source_application);

    create table identityiq.spt_bundle_profile_relation_step (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        bundle_profile_relation_id varchar(32),
        step_type varchar(255),
        bundle_id varchar(32),
        idx integer,
        primary key (id)
    ) IN identityiq_ts;

create index identityiq.spt_bpr_bundle_id_hash_code on identityiq.spt_bundle_profile_relation (bundle_id, hash_code);
create index identityiq.spt_bpr_type on identityiq.spt_bundle_profile_relation (type);
create index identityiq.spt_bpr_app_status on identityiq.spt_bundle_profile_relation (app_status);
create index identityiq.spt_bprs_bundle_id on identityiq.spt_bundle_profile_relation_step (bundle_id);

    alter table identityiq.spt_bundle_profile_relation_step
       add constraint FK9ge6smvhp8n0fcl408e86tvia
       foreign key (bundle_profile_relation_id)
       references identityiq.spt_bundle_profile_relation;

create index identityiq.FK9ge6smvhp8n0fcl408e86tvia on identityiq.spt_bundle_profile_relation_step (bundle_profile_relation_id);

create index identityiq.spt_bpr_attr_ci on identityiq.spt_bundle_profile_relation (attribute_ci);

create index identityiq.spt_bpr_value_ci on identityiq.spt_bundle_profile_relation (value_ci);

create index identityiq.spt_bpr_display_value_ci on identityiq.spt_bundle_profile_relation (display_value_ci);
--
-- modifications to the post commit notification object table
-- this table never should have been used so just redefine it
--
drop table identityiq.spt_post_commit_notification_object;

create table identityiq.spt_post_commit_notification_object (
   id varchar(32) not null,
    class_name varchar(1024) not null,
    modified_id varchar(1024) not null,
    type varchar(255) not null,
    created bigint,
    modified bigint,
    consumer varchar(256),
    committed_object_string clob(100000000),
    primary key (id)
) IN identityiq_ts;

create table identityiq.spt_bundle_profile_relation_object (
   id varchar(32) not null,
    modified_id varchar(1024) not null,
    type varchar(255) not null,
    created bigint,
    modified bigint,
    hash_code integer,
    primary key (id)
) IN identityiq_ts;

create table identityiq.spt_native_identity_change_event (
   id varchar(32) not null,
    created bigint,
    modified bigint,
    launched bigint,
    type varchar(255),
    identity_id varchar(255),
    link_id varchar(255),
    managed_attribute_id varchar(255),
    old_native_identity varchar(322),
    new_native_identity varchar(322),
    uuid varchar(255),
    application_id varchar(255),
    instance varchar(128),
    status varchar(255),
    uuid_ci generated always as (upper(uuid)),
    managed_attribute_id_ci generated always as (upper(managed_attribute_id)),
    link_id_ci generated always as (upper(link_id)),
    identity_id_ci generated always as (upper(identity_id)),
    old_native_identity_ci generated always as (upper(old_native_identity)),
    primary key (id)
) IN identityiq_ts;

create index identityiq.spt_nativeidchange_identity_ci on identityiq.spt_native_identity_change_event (identity_id_ci);
create index identityiq.spt_nativeidchange_link_ci on identityiq.spt_native_identity_change_event (link_id_ci);
create index identityiq.spt_nativeidchange_ma_ci on identityiq.spt_native_identity_change_event (managed_attribute_id_ci);
create index identityiq.spt_nativeidchange_uuid_ci on identityiq.spt_native_identity_change_event (uuid_ci);
create index identityiq.spt_nativeidchange_oldni_ci on identityiq.spt_native_identity_change_event(old_native_identity_ci);

alter table identityiq.spt_service_definition add iiqlock varchar(128);


-- add iiq_elevated_access column to ManagedAttribute and Bundle
alter table identityiq.spt_managed_attribute add iiq_elevated_access smallint ;
update identityiq.spt_managed_attribute set iiq_elevated_access = 0;
alter table identityiq.spt_managed_attribute alter column iiq_elevated_access set not null;

alter table identityiq.spt_bundle add iiq_elevated_access smallint ;
update identityiq.spt_bundle set iiq_elevated_access = 0;
alter table identityiq.spt_bundle alter column iiq_elevated_access set not null;

alter table identityiq.spt_certification_item add iiq_elevated_access smallint;


--
-- This is necessary to maintain the schema version. DO NOT REMOVE.
--
update identityiq.spt_database_version set schema_version = '8.3-21' where name = 'main';

--
-- If this fails, please execute reorg on the spt_bundle and spt_managed_attribute tables which will be in
-- pending reorg state due to schema changes.
--
call sysproc.admin_cmd('reorg table IDENTITYIQ.SPT_BUNDLE');
call sysproc.admin_cmd('reorg table IDENTITYIQ.SPT_MANAGED_ATTRIBUTE');
