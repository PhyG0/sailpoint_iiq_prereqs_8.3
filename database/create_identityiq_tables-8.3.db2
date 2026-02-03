--
-- This script is a SAMPLE and can be modified as appropriate by the
-- customer as long as the equivalent tables and indexes are created.
-- The database name, user, and password must match those defined in
-- iiq.properties in the IdentityIQ installation.
--
-- These configuration parameters can be modified to match your environment.
--

-- DB2 has a name size limit we can't use identityiq like the others.
-- You may also consider adding codeset and collation options. 
CREATE DATABASE IIQ AUTOMATIC STORAGE YES PAGESIZE 32 K;

CONNECT TO iiq;

CREATE SCHEMA identityiq AUTHORIZATION identityiq;

CREATE BUFFERPOOL identityiq_bp IMMEDIATE SIZE 2000 AUTOMATIC PAGESIZE 32 K;

CREATE TABLESPACE identityiq_ts PAGESIZE 32 K
     MANAGED BY AUTOMATIC STORAGE
     INITIALSIZE 1 G
     INCREASESIZE 512 M
     BUFFERPOOL identityiq_bp;

-- Grant everything to identityiq user for simplicity in dev/poc environments. 
-- This is not necessary for production environments.  The minimal set of permissions is: 
--   - CONNECT, CREATETAB, DATAACCESS on database
--   - USAGE of all sequences defined in the script

GRANT DBADM ON DATABASE TO USER identityiq;


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

-- IdentityIQ NOTES
--
-- The job_data columns will contain lists of identities for certifications,
-- e.g. when scheduling a cert from selected identities in the results of a
-- search.  The original size for these columns was 2000, but this restriction
-- has been removed. 
--
-- Removing the 2000 bytes size of the column job_data as its giving DB2 exception if the data 
-- size is more than 2000 bytes. This happens during performing policies simulation for 
-- policies having rule attached.
-- 12/17/2013 updated for Quartz 2.2.1

create table identityiq.qrtz221_job_details(
sched_name varchar(120) not null,
job_name varchar(200) not null,
job_group varchar(80) not null,
description varchar(120),
job_class_name varchar(128) not null,
is_durable varchar(1) not null,
is_nonconcurrent varchar(1) not null,
is_update_data varchar(1) not null,
requests_recovery varchar(1) not null,
job_data blob,
primary key (sched_name,job_name,job_group)
) in identityiq_ts;

create table identityiq.qrtz221_triggers(
sched_name varchar(120) not null,
trigger_name varchar(200) not null,
trigger_group varchar(80) not null,
job_name varchar(200) not null,
job_group varchar(80) not null,
description varchar(120),
next_fire_time bigint,
prev_fire_time bigint,
priority integer,
trigger_state varchar(16) not null,
trigger_type varchar(8) not null,
start_time bigint not null,
end_time bigint,
calendar_name varchar(80),
misfire_instr smallint,
job_data blob(2000),
primary key (sched_name,trigger_name,trigger_group),
foreign key (sched_name,job_name,job_group) references identityiq.qrtz221_job_details(sched_name,job_name,job_group)
) in identityiq_ts;

create table identityiq.qrtz221_simple_triggers(
sched_name varchar(120) not null,
trigger_name varchar(200) not null,
trigger_group varchar(80) not null,
repeat_count bigint not null,
repeat_interval bigint not null,
times_triggered bigint not null,
primary key (sched_name,trigger_name,trigger_group),
foreign key (sched_name,trigger_name,trigger_group) references identityiq.qrtz221_triggers(sched_name,trigger_name,trigger_group)
) in identityiq_ts;

create table identityiq.qrtz221_cron_triggers(
sched_name varchar(120) not null,
trigger_name varchar(200) not null,
trigger_group varchar(80) not null,
cron_expression varchar(120) not null,
time_zone_id varchar(80),
primary key (sched_name,trigger_name,trigger_group),
foreign key (sched_name,trigger_name,trigger_group) references identityiq.qrtz221_triggers(sched_name,trigger_name,trigger_group)
) in identityiq_ts;

CREATE TABLE identityiq.qrtz221_simprop_triggers
  (          
    sched_name varchar(120) not null,
    trigger_name varchar(200) not null,
    trigger_group varchar(200) not null,
    str_prop_1 varchar(512),
    str_prop_2 varchar(512),
    str_prop_3 varchar(512),
    int_prop_1 int,
    int_prop_2 int,
    long_prop_1 bigint,
    long_prop_2 bigint,
    dec_prop_1 numeric(13,4),
    dec_prop_2 numeric(13,4),
    bool_prop_1 varchar(1),
    bool_prop_2 varchar(1),
    primary key (sched_name,trigger_name,trigger_group),
    foreign key (sched_name,trigger_name,trigger_group)
    references identityiq.qrtz221_triggers(sched_name,trigger_name,trigger_group)
) in identityiq_ts;

create table identityiq.qrtz221_blob_triggers(
sched_name varchar(120) not null,
trigger_name varchar(200) not null,
trigger_group varchar(80) not null,
blob_data blob(2000),
primary key (sched_name,trigger_name,trigger_group),
foreign key (sched_name,trigger_name,trigger_group) references identityiq.qrtz221_triggers(sched_name,trigger_name,trigger_group)
) in identityiq_ts;

create table identityiq.qrtz221_calendars(
sched_name varchar(120) not null,
calendar_name varchar(80) not null,
calendar blob(2000) not null,
primary key (sched_name,calendar_name)
) in identityiq_ts;

create table identityiq.qrtz221_fired_triggers(
sched_name varchar(120) not null,
entry_id varchar(95) not null,
trigger_name varchar(200) not null,
trigger_group varchar(80) not null,
instance_name varchar(80) not null,
fired_time bigint not null,
sched_time bigint not null,
priority integer not null,
state varchar(16) not null,
job_name varchar(200),
job_group varchar(80),
is_nonconcurrent varchar(1),
requests_recovery varchar(1),
primary key (sched_name,entry_id)
) in identityiq_ts;

create table identityiq.qrtz221_paused_trigger_grps(
sched_name varchar(120) not null,
trigger_group varchar(80) not null,
primary key (sched_name,trigger_group)
) in identityiq_ts;

create table identityiq.qrtz221_scheduler_state(
sched_name varchar(120) not null,
instance_name varchar(80) not null,
last_checkin_time bigint not null,
checkin_interval bigint not null,
primary key (sched_name,instance_name)
) in identityiq_ts;

create table identityiq.qrtz221_locks(
sched_name varchar(120) not null,
lock_name varchar(40) not null,
primary key (sched_name,lock_name)
) in identityiq_ts;

insert into identityiq.qrtz221_locks values('QuartzScheduler', 'TRIGGER_ACCESS');
insert into identityiq.qrtz221_locks values('QuartzScheduler', 'JOB_ACCESS');
insert into identityiq.qrtz221_locks values('QuartzScheduler', 'CALENDAR_ACCESS');
insert into identityiq.qrtz221_locks values('QuartzScheduler', 'STATE_ACCESS');
insert into identityiq.qrtz221_locks values('QuartzScheduler', 'MISFIRE_ACCESS');

create index identityiq.idx_qrtz221_j_req_recovery on identityiq.qrtz221_job_details(sched_name,requests_recovery);
create index identityiq.idx_qrtz221_j_grp on identityiq.qrtz221_job_details(sched_name,job_group);
create index identityiq.idx_qrtz221_t_j on identityiq.qrtz221_triggers(sched_name,job_name,job_group);
create index identityiq.idx_qrtz221_t_jg on identityiq.qrtz221_triggers(sched_name,job_group);
create index identityiq.idx_qrtz221_t_c on identityiq.qrtz221_triggers(sched_name,calendar_name);
create index identityiq.idx_qrtz221_t_g on identityiq.qrtz221_triggers(sched_name,trigger_group);
create index identityiq.idx_qrtz221_t_state on identityiq.qrtz221_triggers(sched_name,trigger_state);
create index identityiq.idx_qrtz221_t_n_state on identityiq.qrtz221_triggers(sched_name,trigger_name,trigger_group,trigger_state);
create index identityiq.idx_qrtz221_t_n_g_state on identityiq.qrtz221_triggers(sched_name,trigger_group,trigger_state);
create index identityiq.idx_qrtz221_t_next_fire_time on identityiq.qrtz221_triggers(sched_name,next_fire_time);
create index identityiq.idx_qrtz221_t_nft_st on identityiq.qrtz221_triggers(sched_name,trigger_state,next_fire_time);
create index identityiq.idx_qrtz221_t_nft_misfire on identityiq.qrtz221_triggers(sched_name,misfire_instr,next_fire_time);
create index identityiq.idx_qrtz221_t_nft_st_misfire on identityiq.qrtz221_triggers(sched_name,misfire_instr,next_fire_time,trigger_state);
create index identityiq.idx_qrtz221_t_nft_st_misfire_grp on identityiq.qrtz221_triggers(sched_name,misfire_instr,next_fire_time,trigger_group,trigger_state);
create index identityiq.idx_qrtz221_ft_trig_inst_name on identityiq.qrtz221_fired_triggers(sched_name,instance_name);
create index identityiq.idx_qrtz221_ft_inst_job_req_rcvry on identityiq.qrtz221_fired_triggers(sched_name,instance_name,requests_recovery);
create index identityiq.idx_qrtz221_ft_j_g on identityiq.qrtz221_fired_triggers(sched_name,job_name,job_group);
create index identityiq.idx_qrtz221_ft_jg on identityiq.qrtz221_fired_triggers(sched_name,job_group);
create index identityiq.idx_qrtz221_ft_t_g on identityiq.qrtz221_fired_triggers(sched_name,trigger_name,trigger_group);
create index identityiq.idx_qrtz221_ft_tg on identityiq.qrtz221_fired_triggers(sched_name,trigger_group);

    create table identityiq.spt_account_group (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        name varchar(128),
        description varchar(1024),
        native_identity varchar(322),
        reference_attribute varchar(128),
        member_attribute varchar(128),
        last_refresh bigint,
        last_target_aggregation bigint,
        uncorrelated smallint,
        attributes clob(100000000),
        key1 varchar(128),
        key2 varchar(128),
        key3 varchar(128),
        key4 varchar(128),
        owner varchar(32),
        assigned_scope varchar(32),
        application varchar(32),
        key4_ci generated always as (upper(key4)),
        key3_ci generated always as (upper(key3)),
        key2_ci generated always as (upper(key2)),
        key1_ci generated always as (upper(key1)),
        native_identity_ci generated always as (upper(native_identity)),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_account_group_inheritance (
       account_group varchar(32) not null,
        idx integer not null,
        inherits_from varchar(32) not null,
        primary key (account_group, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_account_group_perms (
       accountgroup varchar(32) not null,
        idx integer not null,
        target varchar(255),
        rights varchar(4000),
        annotation varchar(255),
        primary key (accountgroup, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_account_group_target_perms (
       accountgroup varchar(32) not null,
        idx integer not null,
        target varchar(255),
        rights varchar(4000),
        annotation varchar(255),
        primary key (accountgroup, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_activity_constraint (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        name varchar(2000),
        description varchar(4000),
        violation_owner_type varchar(255),
        compensating_control clob(100000000),
        disabled smallint,
        weight integer,
        remediation_advice clob(100000000),
        violation_summary clob(100000000),
        identity_filters clob(100000000),
        activity_filters clob(100000000),
        time_periods clob(100000000),
        owner varchar(32),
        assigned_scope varchar(32),
        policy varchar(32),
        violation_owner varchar(32),
        violation_owner_rule varchar(32),
        idx integer,
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_activity_data_source (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        description varchar(1024),
        collector varchar(255),
        type varchar(255),
        configuration clob(100000000),
        last_refresh bigint,
        targets clob(100000000),
        owner varchar(32),
        assigned_scope varchar(32),
        correlation_rule varchar(32),
        transformation_rule varchar(32),
        application varchar(32),
        idx integer,
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_activity_time_periods (
       application_activity varchar(32) not null,
        idx integer not null,
        time_period varchar(32) not null,
        primary key (application_activity, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_alert (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        extended1 varchar(255),
        attributes clob(100000000),
        alert_date bigint,
        native_id varchar(255),
        target_id varchar(255),
        target_type varchar(255),
        target_display_name varchar(255),
        last_processed bigint,
        display_name varchar(128),
        name varchar(255),
        type varchar(255),
        source varchar(32),
        extended1_ci generated always as (upper(extended1)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_alert_action (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        alert_def clob(100000000),
        action_type varchar(255),
        result_id varchar(255),
        result clob(100000000),
        alert varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_alert_definition (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        match_config clob(100000000),
        disabled smallint,
        name varchar(128) not null,
        description varchar(1024),
        display_name varchar(128),
        action_config clob(100000000),
        owner varchar(32),
        assigned_scope varchar(32),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_app_dependencies (
       application varchar(32) not null,
        idx integer not null,
        dependency varchar(32) not null,
        primary key (application, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_application (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        extended1 varchar(450),
        extended2 varchar(450),
        extended3 varchar(450),
        extended4 varchar(450),
        name varchar(128) not null,
        proxied_name varchar(128),
        app_cluster varchar(255),
        icon varchar(255),
        connector varchar(255),
        type varchar(255),
        features_string varchar(512),
        aggregation_types varchar(128),
        profile_class varchar(255),
        authentication_resource smallint,
        case_insensitive smallint,
        authoritative smallint,
        maintenance_expiration bigint,
        logical smallint,
        supports_provisioning smallint,
        supports_authenticate smallint,
        supports_account_only smallint,
        supports_additional_accounts smallint,
        no_aggregation smallint,
        sync_provisioning smallint,
        attributes clob(100000000),
        templates clob(100000000),
        provisioning_forms clob(100000000),
        provisioning_config clob(100000000),
        manages_other_apps smallint not null,
        managed_attr_customize_rule varchar(32),
        owner varchar(32),
        assigned_scope varchar(32),
        proxy varchar(32),
        correlation_rule varchar(32),
        creation_rule varchar(32),
        manager_correlation_rule varchar(32),
        customization_rule varchar(32),
        account_correlation_config varchar(32),
        scorecard varchar(32),
        target_source varchar(32),
        name_ci generated always as (upper(name)),
        extended1_ci generated always as (upper(extended1)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_application_remediators (
       application varchar(32) not null,
        idx integer not null,
        elt varchar(32) not null,
        primary key (application, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_application_activity (
       id varchar(32) not null,
        time_stamp bigint,
        source_application varchar(128),
        action varchar(255),
        result varchar(255),
        data_source varchar(128),
        instance varchar(128),
        username varchar(128),
        target varchar(128),
        info varchar(512),
        identity_id varchar(128),
        identity_name varchar(128),
        assigned_scope varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_application_schema (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope varchar(32),
        assigned_scope_path varchar(450),
        name varchar(128),
        object_type varchar(255),
        aggregation_type varchar(128),
        native_object_type varchar(255),
        identity_attribute varchar(255),
        display_attribute varchar(255),
        instance_attribute varchar(255),
        description_attribute varchar(255),
        group_attribute varchar(255),
        hierarchy_attribute varchar(255),
        reference_attribute varchar(255),
        include_permissions smallint,
        index_permissions smallint,
        child_hierarchy smallint,
        perm_remed_mod_type varchar(255),
        cloud_access_mgmt_type varchar(255),
        config clob(100000000),
        features_string varchar(512),
        association_schema_name varchar(255),
        creation_rule varchar(32),
        customization_rule varchar(32),
        correlation_rule varchar(32),
        refresh_rule varchar(32),
        application varchar(32),
        idx integer,
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_application_scorecard (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        incomplete smallint,
        composite_score integer,
        attributes clob(100000000),
        items clob(100000000),
        application_id varchar(32),
        owner varchar(32),
        assigned_scope varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_app_secondary_owners (
       application varchar(32) not null,
        idx integer not null,
        elt varchar(32) not null,
        primary key (application, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_arch_cert_item_apps (
       arch_cert_item_id varchar(32) not null,
        idx integer not null,
        application_name varchar(255),
        primary key (arch_cert_item_id, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_attachment (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        name varchar(256),
        description varchar(256),
        content blob(2147483647),
        owner varchar(32),
        assigned_scope varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_audit_config (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        disabled smallint,
        classes clob(100000000),
        resources clob(100000000),
        attributes clob(100000000),
        actions clob(100000000),
        owner varchar(32),
        assigned_scope varchar(32),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_audit_event (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        interface varchar(128),
        source varchar(128),
        action varchar(128),
        target varchar(255),
        application varchar(128),
        account_name varchar(256),
        instance varchar(128),
        attribute_name varchar(128),
        attribute_value varchar(450),
        tracking_id varchar(128),
        attributes clob(100000000),
        string1 varchar(450),
        string2 varchar(450),
        string3 varchar(450),
        string4 varchar(450),
        server_host varchar(128),
        client_host varchar(128),
        owner varchar(32),
        assigned_scope varchar(32),
        tracking_id_ci generated always as (upper(tracking_id)),
        attribute_value_ci generated always as (upper(attribute_value)),
        attribute_name_ci generated always as (upper(attribute_name)),
        instance_ci generated always as (upper(instance)),
        account_name_ci generated always as (upper(account_name)),
        application_ci generated always as (upper(application)),
        source_ci generated always as (upper(source)),
        interface_ci generated always as (upper(interface)),
        action_ci generated always as (upper(action)),
        target_ci generated always as (upper(target)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_authentication_answer (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        identity_id varchar(32),
        question_id varchar(32),
        answer varchar(512),
        owner varchar(32),
        idx integer,
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_authentication_question (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        question varchar(1024),
        owner varchar(32),
        assigned_scope varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_batch_request (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        file_name varchar(255),
        header varchar(4000),
        run_date bigint,
        completed_date bigint,
        record_count integer,
        completed_count integer,
        error_count integer,
        invalid_count integer,
        message varchar(4000),
        error_message clob(100000000),
        file_contents clob(100000000),
        status varchar(255),
        run_config clob(100000000),
        owner varchar(32),
        assigned_scope varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_batch_request_item (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        request_data varchar(4000),
        status varchar(255),
        message varchar(4000),
        error_message clob(100000000),
        result varchar(255),
        identity_request_id varchar(255),
        target_identity_id varchar(255),
        batch_request_id varchar(32),
        owner varchar(32),
        assigned_scope varchar(32),
        idx integer,
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_bulk_id_join (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        join_id varchar(128),
        join_property varchar(128),
        user_id varchar(128),
        user_id_ci generated always as (upper(user_id)),
        join_property_ci generated always as (upper(join_property)),
        join_id_ci generated always as (upper(join_id)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_bundle (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        extended1 varchar(450),
        extended2 varchar(450),
        extended3 varchar(450),
        extended4 varchar(450),
        name varchar(128) not null,
        display_name varchar(128),
        displayable_name varchar(128),
        disabled smallint,
        risk_score_weight integer,
        activity_config clob(100000000),
        mining_statistics clob(100000000),
        attributes clob(100000000),
        type varchar(128),
        selector clob(100000000),
        provisioning_plan clob(100000000),
        templates clob(100000000),
        provisioning_forms clob(100000000),
        or_profiles smallint,
        activation_date bigint,
        deactivation_date bigint,
        pending_delete smallint,
        iiq_elevated_access smallint not null,
        owner varchar(32),
        assigned_scope varchar(32),
        join_rule varchar(32),
        pending_workflow varchar(32),
        role_index varchar(32),
        scorecard varchar(32),
        name_ci generated always as (upper(name)),
        displayable_name_ci generated always as (upper(displayable_name)),
        extended1_ci generated always as (upper(extended1)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_bundle_archive (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        name varchar(128),
        source_id varchar(128),
        version integer,
        creator varchar(128),
        archive clob(100000000),
        owner varchar(32),
        assigned_scope varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_bundle_children (
       bundle varchar(32) not null,
        idx integer not null,
        child varchar(32) not null,
        primary key (bundle, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_bundle_permits (
       bundle varchar(32) not null,
        idx integer not null,
        child varchar(32) not null,
        primary key (bundle, idx)
    ) IN identityiq_ts;

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

    create table identityiq.spt_bundle_profile_relation_object (
       id varchar(32) not null,
        modified_id varchar(1024) not null,
        type varchar(255) not null,
        created bigint,
        modified bigint,
        hash_code integer,
        primary key (id)
    ) IN identityiq_ts;

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

    create table identityiq.spt_bundle_requirements (
       bundle varchar(32) not null,
        idx integer not null,
        child varchar(32) not null,
        primary key (bundle, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_capability (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        description varchar(1024),
        display_name varchar(128),
        applies_to_analyzer smallint,
        owner varchar(32),
        assigned_scope varchar(32),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_capability_children (
       capability_id varchar(32) not null,
        idx integer not null,
        child_id varchar(32) not null,
        primary key (capability_id, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_capability_rights (
       capability_id varchar(32) not null,
        idx integer not null,
        right_id varchar(32) not null,
        primary key (capability_id, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_category (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        targets clob(100000000),
        owner varchar(32),
        assigned_scope varchar(32),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_cert_action_assoc (
       parent_id varchar(32) not null,
        idx integer not null,
        child_id varchar(32) not null,
        primary key (parent_id, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_certification (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        attributes clob(100000000),
        iiqlock varchar(128),
        name varchar(256),
        short_name varchar(255),
        description varchar(1024),
        creator varchar(255),
        complete smallint,
        complete_hierarchy smallint,
        signed bigint,
        approver_rule varchar(512),
        finished bigint,
        expiration bigint,
        automatic_closing_date bigint,
        application_id varchar(255),
        manager varchar(255),
        group_definition varchar(512),
        group_definition_id varchar(128),
        group_definition_name varchar(255),
        comments clob(8192),
        error clob(8192),
        entities_to_refresh clob(100000000),
        commands clob(100000000),
        activated bigint,
        total_entities integer,
        excluded_entities integer,
        completed_entities integer,
        delegated_entities integer,
        percent_complete integer,
        certified_entities integer,
        cert_req_entities integer,
        overdue_entities integer,
        total_items integer,
        excluded_items integer,
        completed_items integer,
        delegated_items integer,
        item_percent_complete integer,
        certified_items integer,
        cert_req_items integer,
        overdue_items integer,
        remediations_kicked_off integer,
        remediations_completed integer,
        total_violations integer not null,
        violations_allowed integer not null,
        violations_remediated integer not null,
        violations_acknowledged integer not null,
        total_roles integer not null,
        roles_approved integer not null,
        roles_allowed integer not null,
        roles_remediated integer not null,
        total_exceptions integer not null,
        exceptions_approved integer not null,
        exceptions_allowed integer not null,
        exceptions_remediated integer not null,
        total_grp_perms integer not null,
        grp_perms_approved integer not null,
        grp_perms_remediated integer not null,
        total_grp_memberships integer not null,
        grp_memberships_approved integer not null,
        grp_memberships_remediated integer not null,
        total_accounts integer not null,
        accounts_approved integer not null,
        accounts_allowed integer not null,
        accounts_remediated integer not null,
        total_profiles integer not null,
        profiles_approved integer not null,
        profiles_remediated integer not null,
        total_scopes integer not null,
        scopes_approved integer not null,
        scopes_remediated integer not null,
        total_capabilities integer not null,
        capabilities_approved integer not null,
        capabilities_remediated integer not null,
        total_permits integer not null,
        permits_approved integer not null,
        permits_remediated integer not null,
        total_requirements integer not null,
        requirements_approved integer not null,
        requirements_remediated integer not null,
        total_hierarchies integer not null,
        hierarchies_approved integer not null,
        hierarchies_remediated integer not null,
        type varchar(255),
        task_schedule_id varchar(255),
        trigger_id varchar(128),
        certification_definition_id varchar(128),
        phase varchar(255),
        next_phase_transition bigint,
        phase_config clob(100000000),
        process_revokes_immediately smallint,
        next_remediation_scan bigint,
        entitlement_granularity varchar(255),
        bulk_reassignment smallint,
        continuous smallint,
        continuous_config clob(100000000),
        next_cert_required_scan bigint,
        next_overdue_scan bigint,
        exclude_inactive smallint,
        immutable smallint,
        electronically_signed smallint,
        self_cert_reassignment smallint,
        owner varchar(32),
        assigned_scope varchar(32),
        parent varchar(32),
        idx integer,
        phase_ci generated always as (upper(phase)),
        certification_definition_id_ci generated always as (upper(certification_definition_id)),
        trigger_id_ci generated always as (upper(trigger_id)),
        task_schedule_id_ci generated always as (upper(task_schedule_id)),
        type_ci generated always as (upper(type)),
        group_definition_name_ci generated always as (upper(group_definition_name)),
        group_definition_id_ci generated always as (upper(group_definition_id)),
        manager_ci generated always as (upper(manager)),
        application_id_ci generated always as (upper(application_id)),
        short_name_ci generated always as (upper(short_name)),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_certification_def_tags (
       cert_def_id varchar(32) not null,
        idx integer not null,
        elt varchar(32) not null,
        primary key (cert_def_id, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_certification_groups (
       certification_id varchar(32) not null,
        idx integer not null,
        group_id varchar(32) not null,
        primary key (certification_id, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_certification_tags (
       certification_id varchar(32) not null,
        idx integer not null,
        elt varchar(32) not null,
        primary key (certification_id, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_certification_action (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        owner_name varchar(255),
        email_template varchar(255),
        comments clob(8192),
        expiration timestamp,
        work_item varchar(255),
        completion_state varchar(255),
        completion_comments clob(8192),
        completion_user varchar(128),
        actor_name varchar(128),
        actor_display_name varchar(128),
        acting_work_item varchar(255),
        description varchar(1024),
        status varchar(255),
        decision_date bigint,
        decision_certification_id varchar(128),
        reviewed smallint,
        bulk_certified smallint,
        mitigation_expiration bigint,
        remediation_action varchar(255),
        remediation_details clob(100000000),
        additional_actions clob(100000000),
        revoke_account smallint,
        ready_for_remediation smallint,
        remediation_kicked_off smallint,
        remediation_completed smallint,
        auto_decision smallint,
        owner varchar(32),
        assigned_scope varchar(32),
        source_action varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_certification_archive (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        name varchar(256),
        certification_id varchar(255),
        certification_group_id varchar(255),
        signed bigint,
        expiration bigint,
        creator varchar(128),
        comments clob(8192),
        archive clob(100000000),
        immutable smallint,
        owner varchar(32),
        assigned_scope varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_certification_challenge (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        owner_name varchar(255),
        email_template varchar(255),
        comments clob(8192),
        expiration timestamp,
        work_item varchar(255),
        completion_state varchar(255),
        completion_comments clob(8192),
        completion_user varchar(128),
        actor_name varchar(128),
        actor_display_name varchar(128),
        acting_work_item varchar(255),
        description varchar(1024),
        challenged smallint,
        decision varchar(255),
        decision_comments clob(8192),
        decider_name varchar(255),
        challenge_decision_expired smallint,
        owner varchar(32),
        assigned_scope varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_certification_definition (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        name varchar(255) not null,
        description varchar(1024),
        attributes clob(100000000),
        owner varchar(32),
        assigned_scope varchar(32),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_certification_delegation (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        owner_name varchar(255),
        email_template varchar(255),
        comments clob(8192),
        expiration timestamp,
        work_item varchar(255),
        completion_state varchar(255),
        completion_comments clob(8192),
        completion_user varchar(128),
        actor_name varchar(128),
        actor_display_name varchar(128),
        acting_work_item varchar(255),
        description varchar(1024),
        review_required smallint,
        revoked smallint,
        owner varchar(32),
        assigned_scope varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_certification_entity (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        completed bigint,
        summary_status varchar(255),
        continuous_state varchar(255),
        last_decision bigint,
        next_continuous_state_change bigint,
        overdue_date bigint,
        has_differences smallint,
        action_required smallint,
        target_display_name varchar(255),
        target_name varchar(255),
        target_id varchar(255),
        custom1 varchar(450),
        custom2 varchar(450),
        custom_map clob(100000000),
        owner varchar(32),
        assigned_scope varchar(32),
        action varchar(32),
        delegation varchar(32),
        type varchar(255),
        bulk_certified smallint,
        attributes clob(100000000),
        identity_id varchar(450),
        firstname varchar(255),
        lastname varchar(255),
        composite_score integer,
        snapshot_id varchar(255),
        differences clob(100000000),
        new_user smallint,
        account_group varchar(450),
        application varchar(255),
        native_identity varchar(322),
        reference_attribute varchar(255),
        schema_object_type varchar(255),
        certification_id varchar(32),
        pending_certification varchar(32),
        lastname_ci generated always as (upper(lastname)),
        firstname_ci generated always as (upper(firstname)),
        target_display_name_ci generated always as (upper(target_display_name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_certification_group (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        name varchar(256),
        type varchar(255),
        status varchar(255),
        attributes clob(100000000),
        total_certifications integer,
        percent_complete integer,
        completed_certifications integer,
        certification_definition varchar(32),
        messages clob(100000000),
        owner varchar(32),
        assigned_scope varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_certification_item (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        completed bigint,
        summary_status varchar(255),
        continuous_state varchar(255),
        last_decision bigint,
        next_continuous_state_change bigint,
        overdue_date bigint,
        has_differences smallint,
        action_required smallint,
        target_display_name varchar(255),
        target_name varchar(255),
        target_id varchar(255),
        custom1 varchar(450),
        custom2 varchar(450),
        custom_map clob(100000000),
        owner varchar(32),
        assigned_scope varchar(32),
        action varchar(32),
        delegation varchar(32),
        bundle varchar(255),
        type varchar(255),
        sub_type varchar(255),
        bundle_assignment_id varchar(128),
        certification_entity_id varchar(32),
        needs_refresh smallint,
        exception_application varchar(128),
        exception_attribute_name varchar(255),
        exception_attribute_value varchar(2048),
        exception_permission_target varchar(255),
        exception_permission_right varchar(255),
        policy_violation clob(100000000),
        violation_summary varchar(256),
        wake_up_date bigint,
        reminders_sent integer,
        needs_continuous_flush smallint,
        phase varchar(255),
        next_phase_transition bigint,
        finished_date bigint,
        recommend_value varchar(100),
        iiq_elevated_access smallint,
        attributes clob(100000000),
        extended1 varchar(450),
        extended2 varchar(450),
        extended3 varchar(450),
        extended4 varchar(450),
        extended5 varchar(450),
        exception_entitlements varchar(32),
        challenge varchar(32),
        idx integer,
        extended1_ci generated always as (upper(extended1)),
        target_display_name_ci generated always as (upper(target_display_name)),
        exception_attribute_name_ci generated always as (upper(exception_attribute_name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_certifiers (
       certification_id varchar(32) not null,
        idx integer not null,
        certifier varchar(255),
        primary key (certification_id, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_cert_item_applications (
       certification_item_id varchar(32) not null,
        idx integer not null,
        application_name varchar(255),
        primary key (certification_item_id, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_cert_item_classifications (
       certification_item varchar(32),
        classification_name varchar(255)
    ) IN identityiq_ts;

    create table identityiq.spt_child_certification_ids (
       certification_archive_id varchar(32) not null,
        idx integer not null,
        child_id varchar(255),
        primary key (certification_archive_id, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_classification (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        name varchar(128) not null,
        display_name varchar(128),
        displayable_name varchar(128),
        attributes clob(100000000),
        origin varchar(128),
        type varchar(128),
        name_ci generated always as (upper(name)),
        displayable_name_ci generated always as (upper(displayable_name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_cloud_access3way (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        cloud_access_group varchar(32),
        cloud_access_role varchar(32),
        cloud_access_scope varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_cloud_access_group (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        name varchar(450) not null,
        uri varchar(450),
        display_name varchar(450),
        cloud_type varchar(80),
        event_time_stamp bigint,
        application_id varchar(32),
        object_type varchar(255),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_cloud_access_role (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        name varchar(450) not null,
        uri varchar(450),
        display_name varchar(450),
        cloud_type varchar(80),
        event_time_stamp bigint,
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_cloud_access_scope (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        name varchar(450) not null,
        uri varchar(450),
        display_name varchar(450),
        cloud_type varchar(80),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_configuration (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        description varchar(1024),
        attributes clob(100000000),
        owner varchar(32),
        assigned_scope varchar(32),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_correlation_config (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        description varchar(256),
        attribute_assignments clob(100000000),
        direct_assignments clob(100000000),
        owner varchar(32),
        assigned_scope varchar(32),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_custom (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        name varchar(128),
        description varchar(1024),
        attributes clob(100000000),
        owner varchar(32),
        assigned_scope varchar(32),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_database_version (
       name varchar(255) not null,
        system_version varchar(128),
        schema_version varchar(128),
        primary key (name)
    ) IN identityiq_ts;

    create table identityiq.spt_deleted_object (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        uuid varchar(128),
        name varchar(128),
        native_identity varchar(322) not null,
        last_refresh bigint,
        object_type varchar(128),
        application varchar(32),
        attributes clob(100000000),
        assigned_scope varchar(32),
        object_type_ci generated always as (upper(object_type)),
        name_ci generated always as (upper(name)),
        uuid_ci generated always as (upper(uuid)),
        native_identity_ci generated always as (upper(native_identity)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_dictionary (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        name varchar(128),
        owner varchar(32),
        assigned_scope varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_dictionary_term (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        value varchar(128) not null,
        dictionary_id varchar(32),
        owner varchar(32),
        assigned_scope varchar(32),
        idx integer,
        value_ci generated always as (upper(value)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_dynamic_scope (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        description varchar(1024),
        selector clob(100000000),
        allow_all smallint,
        population_request_authority clob(100000000),
        managed_attr_request_control varchar(32),
        managed_attr_remove_control varchar(32),
        owner varchar(32),
        assigned_scope varchar(32),
        role_request_control varchar(32),
        application_request_control varchar(32),
        role_remove_control varchar(32),
        application_remove_control varchar(32),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_dynamic_scope_exclusions (
       dynamic_scope_id varchar(32) not null,
        idx integer not null,
        identity_id varchar(32) not null,
        primary key (dynamic_scope_id, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_dynamic_scope_inclusions (
       dynamic_scope_id varchar(32) not null,
        idx integer not null,
        identity_id varchar(32) not null,
        primary key (dynamic_scope_id, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_email_template (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        description varchar(1024),
        from_address varchar(255),
        to_address varchar(255),
        cc_address varchar(255),
        bcc_address varchar(255),
        subject varchar(255),
        body clob(100000000),
        signature clob(100000000),
        owner varchar(32),
        assigned_scope varchar(32),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_email_template_properties (
       id varchar(32) not null,
        name varchar(78) not null,
        value varchar(255),
        primary key (id, name)
    ) IN identityiq_ts;

    create table identityiq.spt_entitlement_group (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        name varchar(128),
        application varchar(32),
        instance varchar(128),
        native_identity varchar(322),
        display_name varchar(128),
        account_only smallint not null,
        attributes clob(100000000),
        owner varchar(32),
        assigned_scope varchar(32),
        identity_id varchar(32),
        idx integer,
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_entitlement_snapshot (
       id varchar(32) not null,
        application varchar(255),
        instance varchar(128),
        native_identity varchar(322),
        display_name varchar(450),
        account_only smallint not null,
        attributes clob(100000000),
        certification_item_id varchar(32),
        idx integer,
        display_name_ci generated always as (upper(display_name)),
        native_identity_ci generated always as (upper(native_identity)),
        application_ci generated always as (upper(application)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_file_bucket (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        file_index integer,
        parent_id varchar(32),
        data blob(1700000),
        owner varchar(32),
        assigned_scope varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_form (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        description varchar(4000),
        hidden smallint,
        type varchar(255),
        application varchar(32),
        sections clob(100000000),
        buttons clob(100000000),
        attributes clob(100000000),
        owner varchar(32),
        assigned_scope varchar(32),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_full_text_index (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        name varchar(128) not null,
        description varchar(1024),
        iiqlock varchar(128),
        last_refresh bigint,
        attributes clob(100000000),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_generic_constraint (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        name varchar(2000),
        description varchar(4000),
        violation_owner_type varchar(255),
        compensating_control clob(100000000),
        disabled smallint,
        weight integer,
        remediation_advice clob(100000000),
        violation_summary clob(100000000),
        arguments clob(100000000),
        selectors clob(100000000),
        owner varchar(32),
        assigned_scope varchar(32),
        policy varchar(32),
        violation_owner varchar(32),
        violation_owner_rule varchar(32),
        idx integer,
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_group_definition (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        name varchar(255),
        description varchar(1024),
        filter clob(100000000),
        last_refresh bigint,
        null_group smallint,
        indexed smallint,
        private smallint,
        factory varchar(32),
        group_index varchar(32),
        owner varchar(32),
        assigned_scope varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_group_factory (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        name varchar(255),
        description varchar(1024),
        factory_attribute varchar(255),
        enabled smallint,
        last_refresh bigint,
        owner varchar(32),
        assigned_scope varchar(32),
        group_owner_rule varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_group_index (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        incomplete smallint,
        composite_score integer,
        attributes clob(100000000),
        items clob(100000000),
        business_role_score integer,
        raw_business_role_score integer,
        entitlement_score integer,
        raw_entitlement_score integer,
        policy_score integer,
        raw_policy_score integer,
        certification_score integer,
        total_violations integer,
        total_remediations integer,
        total_delegations integer,
        total_mitigations integer,
        total_approvals integer,
        definition varchar(32),
        name varchar(255),
        member_count integer,
        band_count integer,
        band1 integer,
        band2 integer,
        band3 integer,
        band4 integer,
        band5 integer,
        band6 integer,
        band7 integer,
        band8 integer,
        band9 integer,
        band10 integer,
        certifications_due integer,
        certifications_on_time integer,
        owner varchar(32),
        assigned_scope varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_group_permissions (
       entitlement_group_id varchar(32) not null,
        idx integer not null,
        target varchar(255),
        annotation varchar(255),
        rights varchar(4000),
        attributes clob(100000000),
        primary key (entitlement_group_id, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_identity (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        extended1 varchar(450),
        extended2 varchar(450),
        extended3 varchar(450),
        extended4 varchar(450),
        extended5 varchar(450),
        extended6 varchar(450),
        extended7 varchar(450),
        extended8 varchar(450),
        extended9 varchar(450),
        extended10 varchar(450),
        name varchar(128) not null,
        description varchar(1024),
        protected smallint,
        needs_refresh smallint,
        iiqlock varchar(128),
        attributes clob(100000000),
        display_name varchar(128),
        firstname varchar(128),
        lastname varchar(128),
        email varchar(128),
        manager_status smallint,
        inactive smallint,
        last_login bigint,
        last_refresh bigint,
        password varchar(450),
        password_expiration bigint,
        password_history varchar(2000),
        bundle_summary varchar(2000),
        assigned_role_summary varchar(2000),
        correlated smallint,
        correlated_overridden smallint,
        type varchar(128),
        software_version varchar(128),
        auth_lock_start bigint,
        failed_auth_question_attempts integer,
        failed_login_attempts integer,
        controls_assigned_scope smallint,
        certifications clob(100000000),
        activity_config clob(100000000),
        preferences clob(100000000),
        attribute_meta_data clob(100000000),
        workgroup smallint,
        owner varchar(32),
        assigned_scope varchar(32),
        extended_identity1 varchar(32),
        extended_identity2 varchar(32),
        extended_identity3 varchar(32),
        extended_identity4 varchar(32),
        extended_identity5 varchar(32),
        manager varchar(32),
        administrator varchar(32),
        scorecard varchar(32),
        uipreferences varchar(32),
        name_ci generated always as (upper(name)),
        software_version_ci generated always as (upper(software_version)),
        type_ci generated always as (upper(type)),
        email_ci generated always as (upper(email)),
        lastname_ci generated always as (upper(lastname)),
        firstname_ci generated always as (upper(firstname)),
        display_name_ci generated always as (upper(display_name)),
        extended5_ci generated always as (upper(extended5)),
        extended4_ci generated always as (upper(extended4)),
        extended3_ci generated always as (upper(extended3)),
        extended2_ci generated always as (upper(extended2)),
        extended1_ci generated always as (upper(extended1)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_identity_archive (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        name varchar(128),
        source_id varchar(128),
        version integer,
        creator varchar(128),
        archive clob(100000000),
        assigned_scope varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_identity_assigned_roles (
       identity_id varchar(32) not null,
        idx integer not null,
        bundle varchar(32) not null,
        primary key (identity_id, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_identity_bundles (
       identity_id varchar(32) not null,
        idx integer not null,
        bundle varchar(32) not null,
        primary key (identity_id, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_identity_capabilities (
       identity_id varchar(32) not null,
        idx integer not null,
        capability_id varchar(32) not null,
        primary key (identity_id, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_identity_controlled_scopes (
       identity_id varchar(32) not null,
        idx integer not null,
        scope_id varchar(32) not null,
        primary key (identity_id, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_identity_entitlement (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        start_date bigint,
        end_date bigint,
        attributes clob(100000000),
        name varchar(255),
        value varchar(450),
        annotation varchar(450),
        display_name varchar(255),
        native_identity varchar(450),
        instance varchar(128),
        application varchar(32),
        identity_id varchar(32) not null,
        aggregation_state varchar(255),
        source varchar(64),
        assigned smallint,
        allowed smallint,
        granted_by_role smallint,
        assigner varchar(128),
        assignment_id varchar(64),
        assignment_note varchar(1024),
        type varchar(255),
        request_item varchar(32),
        pending_request_item varchar(32),
        certification_item varchar(32),
        pending_certification_item varchar(32),
        source_ci generated always as (upper(source)),
        value_ci generated always as (upper(value)),
        instance_ci generated always as (upper(instance)),
        native_identity_ci generated always as (upper(native_identity)),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_identity_external_attr (
       id varchar(32) not null,
        object_id varchar(64),
        attribute_name varchar(64),
        value varchar(322),
        value_ci generated always as (upper(value)),
        attribute_name_ci generated always as (upper(attribute_name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_identity_history_item (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        identity_id varchar(32),
        type varchar(255),
        certifiable_descriptor clob(100000000),
        action clob(100000000),
        certification_link clob(100000000),
        comments clob(8192),
        certification_type varchar(255),
        status varchar(255),
        actor varchar(128),
        entry_date bigint,
        application varchar(128),
        instance varchar(128),
        account varchar(128),
        native_identity varchar(322),
        attribute varchar(450),
        value varchar(450),
        policy varchar(255),
        constraint_name varchar(2000),
        role varchar(255),
        value_ci generated always as (upper(value)),
        attribute_ci generated always as (upper(attribute)),
        native_identity_ci generated always as (upper(native_identity)),
        account_ci generated always as (upper(account)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_identity_request (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        name varchar(255),
        state varchar(255),
        type varchar(255),
        source varchar(255),
        target_id varchar(128),
        target_display_name varchar(255),
        target_class varchar(255),
        requester_display_name varchar(255),
        requester_id varchar(128),
        end_date bigint,
        verified bigint,
        priority varchar(128),
        completion_status varchar(128),
        execution_status varchar(128),
        has_messages smallint not null,
        external_ticket_id varchar(128),
        attributes clob(100000000),
        assigned_scope varchar(32),
        external_ticket_id_ci generated always as (upper(external_ticket_id)),
        requester_display_name_ci generated always as (upper(requester_display_name)),
        target_display_name_ci generated always as (upper(target_display_name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_identity_request_item (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        start_date bigint,
        end_date bigint,
        attributes clob(100000000),
        name varchar(255),
        value varchar(450),
        annotation varchar(450),
        display_name varchar(255),
        native_identity varchar(450),
        instance varchar(128),
        application varchar(255),
        owner_name varchar(128),
        approver_name varchar(128),
        operation varchar(128),
        retries integer,
        provisioning_engine varchar(255),
        approval_state varchar(128),
        provisioning_state varchar(128),
        compilation_status varchar(128),
        expansion_cause varchar(128),
        identity_request_id varchar(32),
        idx integer,
        instance_ci generated always as (upper(instance)),
        native_identity_ci generated always as (upper(native_identity)),
        value_ci generated always as (upper(value)),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_identity_role_metadata (
       identity_id varchar(32) not null,
        idx integer not null,
        role_metadata_id varchar(32) not null,
        primary key (identity_id, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_identity_snapshot (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        name varchar(128),
        identity_id varchar(255),
        identity_name varchar(255),
        summary varchar(2000),
        differences varchar(2000),
        applications varchar(2000),
        scorecard clob(100000000),
        attributes clob(100000000),
        bundles clob(100000000),
        exceptions clob(100000000),
        links clob(100000000),
        violations clob(100000000),
        assigned_roles clob(100000000),
        assigned_scope varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_identity_trigger (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        name varchar(256),
        description varchar(1024),
        disabled smallint,
        type varchar(255),
        rule_id varchar(32),
        attribute_name varchar(256),
        old_value_filter varchar(256),
        new_value_filter varchar(256),
        selector clob(100000000),
        handler varchar(256),
        parameters clob(100000000),
        assigned_scope varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_identity_workgroups (
       identity_id varchar(32) not null,
        idx integer not null,
        workgroup varchar(32) not null,
        primary key (identity_id, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_integration_config (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        description varchar(4000),
        executor varchar(255),
        exec_style varchar(255),
        role_sync_style varchar(255),
        template smallint,
        maintenance_expiration bigint,
        signature clob(100000000),
        attributes clob(100000000),
        resources clob(100000000),
        application_id varchar(32),
        role_sync_filter clob(4000),
        container_id varchar(32),
        assigned_scope varchar(32),
        plan_initializer varchar(32),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_jasper_files (
       result varchar(32) not null,
        idx integer not null,
        elt varchar(32) not null,
        primary key (result, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_jasper_page_bucket (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        bucket_number integer,
        handler_id varchar(128),
        xml clob(1073741823),
        assigned_scope varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_jasper_result (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        handler_id varchar(128),
        print_xml clob(1073741823),
        page_count integer,
        pages_per_bucket integer,
        handler_page_count integer,
        attributes clob(100000000),
        assigned_scope varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_jasper_template (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        design_xml clob(1073741823),
        assigned_scope varchar(32),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_link (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        key1 varchar(450),
        key2 varchar(255),
        key3 varchar(255),
        key4 varchar(255),
        extended1 varchar(450),
        extended2 varchar(450),
        extended3 varchar(450),
        extended4 varchar(450),
        extended5 varchar(450),
        uuid varchar(128),
        display_name varchar(128),
        instance varchar(128),
        native_identity varchar(322) not null,
        last_refresh bigint,
        last_target_aggregation bigint,
        manually_correlated smallint,
        entitlements smallint not null,
        identity_id varchar(32),
        application varchar(32),
        iiq_disabled smallint,
        iiq_locked smallint,
        attributes clob(100000000),
        password_history varchar(2000),
        component_ids varchar(256),
        attribute_meta_data clob(100000000),
        assigned_scope varchar(32),
        display_name_ci generated always as (upper(display_name)),
        extended1_ci generated always as (upper(extended1)),
        key1_ci generated always as (upper(key1)),
        uuid_ci generated always as (upper(uuid)),
        native_identity_ci generated always as (upper(native_identity)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_link_external_attr (
       id varchar(32) not null,
        object_id varchar(64),
        attribute_name varchar(64),
        value varchar(322),
        value_ci generated always as (upper(value)),
        attribute_name_ci generated always as (upper(attribute_name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_localized_attribute (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        name varchar(255),
        locale varchar(128),
        attribute varchar(128),
        value varchar(1024),
        target_class varchar(255),
        target_name varchar(255),
        target_id varchar(255),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_managed_attribute (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        extended1 varchar(450),
        extended2 varchar(450),
        extended3 varchar(450),
        purview varchar(128),
        application varchar(32),
        type varchar(255),
        aggregated smallint,
        attribute varchar(322),
        value varchar(450),
        hash varchar(128) not null,
        display_name varchar(450),
        displayable_name varchar(450),
        uuid varchar(128),
        attributes clob(100000000),
        requestable smallint,
        uncorrelated smallint,
        last_refresh bigint,
        last_target_aggregation bigint,
        key1 varchar(128),
        key2 varchar(128),
        key3 varchar(128),
        key4 varchar(128),
        iiq_elevated_access smallint not null,
        assigned_scope varchar(32),
        hash_ci generated always as (upper(hash)),
        key4_ci generated always as (upper(key4)),
        key3_ci generated always as (upper(key3)),
        key2_ci generated always as (upper(key2)),
        key1_ci generated always as (upper(key1)),
        uuid_ci generated always as (upper(uuid)),
        displayable_name_ci generated always as (upper(displayable_name)),
        extended3_ci generated always as (upper(extended3)),
        extended2_ci generated always as (upper(extended2)),
        extended1_ci generated always as (upper(extended1)),
        value_ci generated always as (upper(value)),
        attribute_ci generated always as (upper(attribute)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_managed_attr_inheritance (
       managedattribute varchar(32) not null,
        idx integer not null,
        inherits_from varchar(32) not null,
        primary key (managedattribute, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_managed_attr_perms (
       managedattribute varchar(32) not null,
        idx integer not null,
        target varchar(255),
        rights varchar(4000),
        annotation varchar(255),
        attributes clob(100000000),
        primary key (managedattribute, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_managed_attr_target_perms (
       managedattribute varchar(32) not null,
        idx integer not null,
        target varchar(255),
        rights varchar(4000),
        annotation varchar(255),
        attributes clob(100000000),
        primary key (managedattribute, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_message_template (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        description varchar(1024),
        text clob(100000),
        assigned_scope varchar(32),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_mining_config (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        description varchar(1024),
        arguments clob(100000000),
        app_constraints clob(100000000),
        assigned_scope varchar(32),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_mitigation_expiration (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        expiration bigint not null,
        mitigator varchar(32) not null,
        comments clob(8192),
        identity_id varchar(32),
        certification_link clob(100000000),
        certifiable_descriptor clob(100000000),
        action varchar(255),
        action_parameters clob(100000000),
        last_action_date bigint,
        role_name varchar(128),
        policy varchar(128),
        constraint_name varchar(2000),
        application varchar(128),
        instance varchar(128),
        native_identity varchar(322),
        account_display_name varchar(128),
        attribute_name varchar(450),
        attribute_value varchar(450),
        permission smallint,
        assigned_scope varchar(32),
        idx integer,
        attribute_value_ci generated always as (upper(attribute_value)),
        attribute_name_ci generated always as (upper(attribute_name)),
        native_identity_ci generated always as (upper(native_identity)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_module (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        name varchar(128) not null,
        description varchar(512),
        attributes clob(100000000),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_monitoring_statistic (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        display_name varchar(128),
        description varchar(1024),
        value varchar(4000),
        value_type varchar(128),
        type varchar(128),
        attributes clob(100000000),
        template smallint,
        assigned_scope varchar(32),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_monitoring_statistic_tags (
       statistic_id varchar(32) not null,
        elt varchar(32) not null
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
        old_native_identity_ci generated always as (upper(old_native_identity)),
        managed_attribute_id_ci generated always as (upper(managed_attribute_id)),
        link_id_ci generated always as (upper(link_id)),
        identity_id_ci generated always as (upper(identity_id)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_object_classification (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner_id varchar(32),
        owner_type varchar(128),
        source varchar(128),
        effective smallint,
        classification_id varchar(32) not null,
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_object_config (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        object_attributes clob(100000000),
        config_attributes clob(100000000),
        assigned_scope varchar(32),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_partition_result (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        stack clob(100000000),
        attributes clob(100000000),
        launcher varchar(255),
        host varchar(255),
        launched bigint,
        progress varchar(255),
        percent_complete integer,
        type varchar(255),
        messages clob(100000000),
        completed bigint,
        name varchar(255) not null,
        task_terminated smallint,
        completion_status varchar(255),
        assigned_scope varchar(32),
        task_result varchar(32),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_password_policy (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        name varchar(128) not null,
        description varchar(512),
        name_ci generated always as (upper(name)),
        password_constraints clob(100000000),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_password_policy_holder (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        policy varchar(32),
        selector clob(100000000),
        application varchar(32),
        idx integer,
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_persisted_file (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        name varchar(256),
        description varchar(1024),
        content_type varchar(128),
        content_length bigint,
        assigned_scope varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_plugin (
       id varchar(32) not null,
        name varchar(255),
        created bigint,
        modified bigint,
        install_date bigint,
        display_name varchar(255),
        version varchar(255),
        disabled smallint,
        right_required varchar(255),
        min_system_version varchar(255),
        max_system_version varchar(255),
        attributes clob(100000000),
        position integer,
        certification_level varchar(255),
        file_id varchar(32),
        display_name_ci generated always as (upper(display_name)),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_policy (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        template smallint,
        type varchar(255),
        type_key varchar(255),
        executor varchar(255),
        config_page varchar(255),
        certification_actions varchar(255),
        violation_owner_type varchar(255),
        violation_owner varchar(32),
        state varchar(255),
        arguments clob(100000000),
        signature clob(100000000),
        alert clob(100000000),
        assigned_scope varchar(32),
        violation_owner_rule varchar(32),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_policy_violation (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        name varchar(2000),
        description varchar(4000),
        identity_id varchar(32),
        renderer varchar(255),
        active smallint,
        policy_id varchar(255),
        policy_name varchar(255),
        constraint_id varchar(255),
        status varchar(255),
        constraint_name varchar(2000),
        left_bundles clob(8192),
        right_bundles clob(8192),
        activity_id varchar(255),
        bundles_marked_for_remediation clob(8192),
        entitlements_marked_for_remed clob(8192),
        mitigator varchar(255),
        arguments clob(100000000),
        assigned_scope varchar(32),
        pending_workflow varchar(32),
        primary key (id)
    ) IN identityiq_ts;

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

    create table identityiq.spt_process_log (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        process_name varchar(128),
        case_id varchar(128),
        workflow_case_name varchar(450),
        launcher varchar(128),
        case_status varchar(128),
        step_name varchar(128),
        approval_name varchar(128),
        owner_name varchar(128),
        start_time bigint,
        end_time bigint,
        step_duration integer,
        escalations integer,
        assigned_scope varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_profile (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        name varchar(128),
        description varchar(1024),
        bundle_id varchar(32),
        disabled smallint,
        account_type varchar(128),
        application varchar(32),
        attributes clob(100000000),
        assigned_scope varchar(32),
        idx integer,
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_profile_constraints (
       profile varchar(32) not null,
        idx integer not null,
        elt clob(100000000),
        primary key (profile, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_profile_permissions (
       profile varchar(32) not null,
        idx integer not null,
        target varchar(255),
        rights varchar(4000),
        attributes clob(100000000),
        primary key (profile, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_provisioning_request (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        identity_id varchar(32),
        target varchar(128),
        requester varchar(128),
        expiration bigint,
        provisioning_plan clob(100000000),
        assigned_scope varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_provisioning_transaction (
       id varchar(32) not null,
        name varchar(255),
        created bigint,
        modified bigint,
        operation varchar(255),
        source varchar(255),
        application_name varchar(255),
        identity_name varchar(255),
        identity_display_name varchar(255),
        native_identity varchar(322),
        account_display_name varchar(322),
        attributes clob(100000000),
        integration varchar(255),
        certification_id varchar(32),
        forced smallint,
        type varchar(255),
        status varchar(255),
        integration_ci generated always as (upper(integration)),
        account_display_name_ci generated always as (upper(account_display_name)),
        native_identity_ci generated always as (upper(native_identity)),
        identity_display_name_ci generated always as (upper(identity_display_name)),
        identity_name_ci generated always as (upper(identity_name)),
        application_name_ci generated always as (upper(application_name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_quick_link (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        message_key varchar(128),
        description varchar(1024),
        action varchar(128),
        css_class varchar(128),
        hidden smallint,
        category varchar(128),
        ordering integer,
        arguments clob(100000000),
        assigned_scope varchar(32),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_quick_link_options (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        allow_bulk smallint,
        allow_other smallint,
        allow_self smallint,
        options clob(100000000),
        dynamic_scope varchar(32) not null,
        quick_link varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_recommender_definition (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        name varchar(128) not null,
        attributes clob(100000000),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_remediation_item (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        description varchar(1024),
        remediation_entity_type varchar(255),
        work_item_id varchar(32),
        certification_item varchar(255),
        assignee varchar(32),
        remediation_identity varchar(255),
        remediation_details clob(100000000),
        completion_comments clob(8192),
        completion_date bigint,
        assimilated smallint,
        comments clob(100000000),
        attributes clob(100000000),
        assigned_scope varchar(32),
        idx integer,
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_remote_login_token (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        creator varchar(128) not null,
        remote_host varchar(128),
        expiration bigint,
        assigned_scope varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_request (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        stack clob(100000000),
        attributes clob(100000000),
        launcher varchar(255),
        host varchar(255),
        launched bigint,
        progress varchar(255),
        percent_complete integer,
        type varchar(255),
        messages clob(100000000),
        completed bigint,
        expiration bigint,
        name varchar(450),
        phase integer,
        dependent_phase integer,
        next_launch bigint,
        retry_count integer,
        retry_interval integer,
        string1 varchar(2048),
        live smallint,
        completion_status varchar(255),
        notification_needed smallint,
        assigned_scope varchar(32),
        definition varchar(32),
        task_result varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_request_arguments (
       signature varchar(32) not null,
        idx integer not null,
        name varchar(255),
        type varchar(255),
        filter_string varchar(255),
        description clob(8192),
        prompt clob(8192),
        multi smallint,
        required smallint,
        primary key (signature, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_request_definition (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        description varchar(4000),
        executor varchar(255),
        form_path varchar(128),
        template smallint,
        hidden smallint,
        result_expiration integer,
        progress_interval integer,
        sub_type varchar(128),
        type varchar(255),
        progress_mode varchar(255),
        arguments clob(100000000),
        retry_max integer,
        retry_interval integer,
        sig_description clob(8192),
        return_type varchar(255),
        assigned_scope varchar(32),
        parent varchar(32),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_request_definition_rights (
       request_definition_id varchar(32) not null,
        idx integer not null,
        right_id varchar(32) not null,
        primary key (request_definition_id, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_request_returns (
       signature varchar(32) not null,
        idx integer not null,
        name varchar(255),
        type varchar(255),
        filter_string varchar(255),
        description clob(8192),
        prompt clob(8192),
        multi smallint,
        primary key (signature, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_request_state (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        name varchar(450),
        attributes clob(100000000),
        request_id varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_resource_event (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        application varchar(32),
        provisioning_plan clob(100000000),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_right_config (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        rights clob(100000000),
        assigned_scope varchar(32),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_role_change_event (
       id varchar(32) not null,
        created bigint,
        bundle_id varchar(128),
        bundle_name varchar(128),
        provisioning_plan clob(100000000),
        bundle_deleted smallint,
        status varchar(255),
        skipped_identity_ids clob(100000000),
        failed_identity_ids clob(100000000),
        affected_identity_count integer,
        run_count integer,
        failed_attempts integer,
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_role_index (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        incomplete smallint,
        composite_score integer,
        attributes clob(100000000),
        items clob(100000000),
        bundle varchar(32),
        assigned_count integer,
        detected_count integer,
        associated_to_role smallint,
        last_certified_membership bigint,
        last_certified_composition bigint,
        last_assigned bigint,
        entitlement_count integer,
        entitlement_count_inheritance integer,
        assigned_scope varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_role_metadata (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        role varchar(32),
        name varchar(255),
        additional_entitlements smallint,
        missing_required smallint,
        assigned smallint,
        detected smallint,
        detected_exception smallint,
        assigned_scope varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_role_mining_result (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        name varchar(128),
        pending smallint,
        config clob(100000000),
        roles clob(100000000),
        assigned_scope varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_role_scorecard (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        role_id varchar(32),
        members integer,
        members_extra_ent integer,
        members_missing_req integer,
        detected integer,
        detected_exc integer,
        provisioned_ent integer,
        permitted_ent integer,
        assigned_scope varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_rule (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        description varchar(1024),
        language varchar(255),
        source clob(100000000),
        type varchar(255),
        attributes clob(100000000),
        sig_description clob(8192),
        return_type varchar(255),
        assigned_scope varchar(32),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_rule_registry_callouts (
       rule_registry_id varchar(32) not null,
        callout varchar(78) not null,
        rule_id varchar(32) not null,
        primary key (rule_registry_id, callout)
    ) IN identityiq_ts;

    create table identityiq.spt_rule_dependencies (
       rule_id varchar(32) not null,
        idx integer not null,
        dependency varchar(32) not null,
        primary key (rule_id, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_rule_registry (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        templates clob(100000000),
        assigned_scope varchar(32),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_rule_signature_arguments (
       signature varchar(32) not null,
        idx integer not null,
        name varchar(255),
        type varchar(255),
        filter_string varchar(255),
        description clob(8192),
        prompt clob(8192),
        multi smallint,
        primary key (signature, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_rule_signature_returns (
       signature varchar(32) not null,
        idx integer not null,
        name varchar(255),
        type varchar(255),
        filter_string varchar(255),
        description clob(8192),
        prompt clob(8192),
        multi smallint,
        primary key (signature, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_samltoken (
       id varchar(128) not null,
        expiration bigint,
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_schema_attributes (
       applicationschema varchar(32) not null,
        idx integer not null,
        name varchar(255),
        type varchar(255),
        description clob(8192),
        required smallint,
        entitlement smallint,
        is_group smallint,
        managed smallint,
        multi_valued smallint,
        minable smallint,
        indexed smallint,
        correlation_key integer,
        source varchar(255),
        internal_name varchar(255),
        default_value varchar(255),
        remed_mod_type varchar(255),
        schema_object_type varchar(255),
        object_mapping varchar(255),
        primary key (applicationschema, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_scope (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        display_name varchar(128),
        parent_id varchar(32),
        manually_created smallint,
        dormant smallint,
        path varchar(450),
        dirty smallint,
        assigned_scope varchar(32),
        idx integer,
        display_name_ci generated always as (upper(display_name)),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_scorecard (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope varchar(32),
        assigned_scope_path varchar(450),
        incomplete smallint,
        composite_score integer,
        attributes clob(100000000),
        items clob(100000000),
        business_role_score integer,
        raw_business_role_score integer,
        entitlement_score integer,
        raw_entitlement_score integer,
        policy_score integer,
        raw_policy_score integer,
        certification_score integer,
        total_violations integer,
        total_remediations integer,
        total_delegations integer,
        total_mitigations integer,
        total_approvals integer,
        identity_id varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_score_config (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope varchar(32),
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        maximum_score integer,
        maximum_number_of_bands integer,
        application_configs clob(100000000),
        identity_scores clob(100000000),
        application_scores clob(100000000),
        bands clob(100000000),
        right_config varchar(32),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_server (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        extended1 varchar(255),
        name varchar(128) not null,
        heartbeat bigint,
        inactive smallint,
        attributes clob(100000000),
        name_ci generated always as (upper(name)),
        extended1_ci generated always as (upper(extended1)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_server_statistic (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        name varchar(128) not null,
        snapshot_name varchar(128),
        value varchar(4000),
        value_type varchar(128),
        host varchar(32),
        attributes clob(100000000),
        target varchar(128),
        target_type varchar(128),
        monitoring_statistic varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_service_definition (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        name varchar(128) not null,
        description varchar(1024),
        executor varchar(255),
        exec_interval integer,
        hosts varchar(1024),
        iiqlock varchar(128),
        attributes clob(100000000),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_service_lock (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        host varchar(255),
        locker varchar(255),
        last_start bigint,
        last_execute bigint,
        service_definition varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_service_status (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        name varchar(128) not null,
        description varchar(1024),
        definition varchar(32),
        host varchar(255),
        last_start bigint,
        last_end bigint,
        attributes clob(100000000),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_sign_off_history (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope varchar(32),
        assigned_scope_path varchar(450),
        sign_date bigint,
        signer_id varchar(128),
        signer_name varchar(128),
        signer_display_name varchar(128),
        application varchar(128),
        account varchar(322),
        text clob(100000000),
        electronic_sign smallint,
        certification_id varchar(32),
        idx integer,
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_snapshot_permissions (
       snapshot varchar(32) not null,
        idx integer not null,
        target varchar(255),
        rights varchar(4000),
        attributes clob(100000000),
        primary key (snapshot, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_sodconstraint (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope varchar(32),
        assigned_scope_path varchar(450),
        name varchar(2000),
        description varchar(4000),
        policy varchar(32),
        violation_owner_type varchar(255),
        violation_owner varchar(32),
        violation_owner_rule varchar(32),
        compensating_control clob(100000000),
        disabled smallint,
        weight integer,
        remediation_advice clob(100000000),
        violation_summary clob(100000000),
        arguments clob(100000000),
        idx integer,
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_sodconstraint_left (
       sodconstraint varchar(32) not null,
        idx integer not null,
        businessrole varchar(32) not null,
        primary key (sodconstraint, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_sodconstraint_right (
       sodconstraint varchar(32) not null,
        idx integer not null,
        businessrole varchar(32) not null,
        primary key (sodconstraint, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_archived_cert_entity (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        entity clob(100000000),
        reason varchar(255),
        explanation clob(100000000),
        certification_id varchar(32),
        target_name varchar(255),
        identity_name varchar(450),
        account_group varchar(450),
        application varchar(255),
        native_identity varchar(322),
        reference_attribute varchar(255),
        schema_object_type varchar(255),
        target_id varchar(255),
        target_display_name varchar(255),
        owner varchar(32),
        assigned_scope varchar(32),
        account_group_ci generated always as (upper(account_group)),
        identity_name_ci generated always as (upper(identity_name)),
        target_name_ci generated always as (upper(target_name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_archived_cert_item (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        type varchar(255),
        sub_type varchar(255),
        item_id varchar(128),
        exception_application varchar(128),
        exception_attribute_name varchar(255),
        exception_attribute_value varchar(2048),
        exception_permission_target varchar(255),
        exception_permission_right varchar(255),
        exception_native_identity varchar(322),
        constraint_name varchar(2000),
        policy varchar(256),
        bundle varchar(255),
        violation_summary varchar(256),
        entitlements clob(100000000),
        parent_id varchar(32),
        target_display_name varchar(255),
        target_name varchar(255),
        target_id varchar(255),
        owner varchar(32),
        assigned_scope varchar(32),
        idx integer,
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_identity_req_item_attach (
       identity_request_item_id varchar(32) not null,
        idx integer not null,
        attachment_id varchar(32) not null,
        primary key (identity_request_item_id, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_pending_req_attach (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        item_id varchar(128) not null,
        attachment_id varchar(128),
        type varchar(128) not null,
        requester_id varchar(128) not null,
        target_id varchar(128),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_right (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        description varchar(1024),
        display_name varchar(128),
        owner varchar(32),
        assigned_scope varchar(32),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_sync_roles (
       config varchar(32) not null,
        idx integer not null,
        bundle varchar(32) not null,
        primary key (config, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_syslog_event (
       id varchar(32) not null,
        created bigint,
        quick_key varchar(12),
        event_level varchar(6),
        classname varchar(128),
        line_number varchar(6),
        message varchar(450),
        thread varchar(128),
        server varchar(128),
        username varchar(128),
        stacktrace clob(100000000),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_tag (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope varchar(32),
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_target (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope varchar(32),
        assigned_scope_path varchar(450),
        extended1 varchar(255),
        name varchar(512),
        native_owner_id varchar(128),
        application varchar(32),
        target_host varchar(1024),
        display_name varchar(400),
        full_path clob(8192),
        unique_name_hash varchar(128),
        attributes clob(100000000),
        native_object_id varchar(322),
        target_size bigint,
        last_aggregation bigint,
        target_source varchar(32),
        parent varchar(32),
        extended1_ci generated always as (upper(extended1)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_target_association (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope varchar(32),
        assigned_scope_path varchar(450),
        object_id varchar(32),
        type varchar(8),
        hierarchy varchar(512),
        flattened smallint,
        application_name varchar(128),
        target_type varchar(128),
        target_name varchar(255),
        target_id varchar(32),
        rights varchar(512),
        inherited smallint,
        effective integer,
        deny_permission smallint,
        last_aggregation bigint,
        attributes clob(100000000),
        target_name_ci generated always as (upper(target_name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_target_source (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope varchar(32),
        assigned_scope_path varchar(450),
        name varchar(128),
        description varchar(1024),
        collector varchar(255),
        last_refresh bigint,
        configuration clob(100000000),
        correlation_rule varchar(32),
        creation_rule varchar(32),
        refresh_rule varchar(32),
        transformation_rule varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_target_sources (
       application varchar(32) not null,
        idx integer not null,
        elt varchar(32) not null,
        primary key (application, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_task_definition (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope varchar(32),
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        description varchar(4000),
        executor varchar(255),
        form_path varchar(128),
        template smallint,
        hidden smallint,
        result_expiration integer,
        progress_interval integer,
        sub_type varchar(128),
        type varchar(255),
        progress_mode varchar(255),
        arguments clob(100000000),
        result_renderer varchar(255),
        concurrent smallint,
        deprecated smallint not null,
        result_action varchar(255),
        sig_description clob(8192),
        return_type varchar(255),
        parent varchar(32),
        signoff_config varchar(32),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_task_definition_rights (
       task_definition_id varchar(32) not null,
        idx integer not null,
        right_id varchar(32) not null,
        primary key (task_definition_id, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_task_event (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope varchar(32),
        assigned_scope_path varchar(450),
        phase varchar(128),
        rule_id varchar(32),
        attributes clob(100000000),
        task_result varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_task_result (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope varchar(32),
        assigned_scope_path varchar(450),
        stack clob(100000000),
        attributes clob(100000000),
        launcher varchar(255),
        host varchar(255),
        launched bigint,
        progress varchar(255),
        percent_complete integer,
        type varchar(255),
        messages clob(100000000),
        completed bigint,
        expiration bigint,
        verified bigint,
        name varchar(255) not null,
        definition varchar(32),
        schedule varchar(255),
        pending_signoffs integer,
        signoff clob(100000000),
        report varchar(32),
        target_class varchar(255),
        target_id varchar(255),
        target_name varchar(255),
        task_terminated smallint,
        partitioned smallint,
        live smallint,
        completion_status varchar(255),
        run_length integer,
        run_length_average integer,
        run_length_deviation integer,
        name_ci generated always as (upper(name)),
        target_name_ci generated always as (upper(target_name)),
        host_ci generated always as (upper(host)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_task_signature_arguments (
       signature varchar(32) not null,
        idx integer not null,
        name varchar(255),
        type varchar(255),
        filter_string varchar(255),
        help_key varchar(255),
        input_template varchar(255),
        description clob(8192),
        prompt clob(8192),
        multi smallint,
        required smallint,
        default_value varchar(255),
        primary key (signature, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_task_signature_returns (
       signature varchar(32) not null,
        idx integer not null,
        name varchar(255),
        type varchar(255),
        filter_string varchar(255),
        description clob(8192),
        prompt clob(8192),
        multi smallint,
        primary key (signature, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_time_period (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope varchar(32),
        assigned_scope_path varchar(450),
        name varchar(128),
        classifier varchar(255),
        init_parameters clob(100000000),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_uiconfig (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope varchar(32),
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        attributes clob(100000000),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_uipreferences (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        preferences clob(100000000),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_widget (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope varchar(32),
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        title varchar(128),
        selector clob(100000000),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_workflow (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope varchar(32),
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        description varchar(4000),
        type varchar(128),
        task_type varchar(255),
        template smallint,
        explicit_transitions smallint,
        monitored smallint,
        result_expiration integer,
        complete smallint,
        handler varchar(128),
        work_item_renderer varchar(128),
        variable_definitions clob(100000000),
        config_form varchar(128),
        steps clob(100000000),
        work_item_config clob(100000000),
        variables clob(100000000),
        libraries varchar(128),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_workflow_rule_libraries (
       rule_id varchar(32) not null,
        idx integer not null,
        dependency varchar(32) not null,
        primary key (rule_id, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_workflow_case (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope varchar(32),
        assigned_scope_path varchar(450),
        stack clob(100000000),
        attributes clob(100000000),
        launcher varchar(255),
        host varchar(255),
        launched bigint,
        progress varchar(255),
        percent_complete integer,
        type varchar(255),
        messages clob(100000000),
        completed bigint,
        name varchar(450),
        description varchar(1024),
        complete smallint,
        target_class varchar(255),
        target_id varchar(255),
        target_name varchar(255),
        workflow clob(100000000),
        iiqlock varchar(128),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_workflow_registry (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope varchar(32),
        assigned_scope_path varchar(450),
        name varchar(128) not null,
        types clob(100000000),
        templates clob(100000000),
        callables clob(100000000),
        attributes clob(100000000),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_workflow_target (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope varchar(32),
        assigned_scope_path varchar(450),
        name varchar(128),
        description varchar(1024),
        class_name varchar(255),
        object_id varchar(255),
        object_name varchar(255),
        workflow_case_id varchar(32) not null,
        idx integer,
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_workflow_test_suite (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        name varchar(128) not null,
        description varchar(4000),
        replicated smallint,
        case_name varchar(255),
        tests clob(100000000),
        responses clob(100000000),
        attributes clob(100000000),
        name_ci generated always as (upper(name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_work_item (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope varchar(32),
        assigned_scope_path varchar(450),
        name varchar(255),
        description varchar(1024),
        handler varchar(255),
        renderer varchar(255),
        target_class varchar(255),
        target_id varchar(255),
        target_name varchar(255),
        type varchar(255),
        state varchar(255),
        severity varchar(255),
        requester varchar(32),
        completion_comments clob(8192),
        notification bigint,
        expiration bigint,
        wake_up_date bigint,
        reminders integer,
        escalation_count integer,
        notification_config clob(100000000),
        workflow_case varchar(32),
        attributes clob(100000000),
        owner_history clob(100000000),
        certification varchar(255),
        certification_entity varchar(255),
        certification_item varchar(255),
        identity_request_id varchar(128),
        assignee varchar(32),
        iiqlock varchar(128),
        certification_ref_id varchar(32),
        idx integer,
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_work_item_comments (
       work_item varchar(32) not null,
        idx integer not null,
        author varchar(255),
        comments clob(8192),
        comment_date bigint,
        primary key (work_item, idx)
    ) IN identityiq_ts;

    create table identityiq.spt_work_item_archive (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope varchar(32),
        assigned_scope_path varchar(450),
        work_item_id varchar(128),
        name varchar(255),
        owner_name varchar(255),
        identity_request_id varchar(128),
        assignee varchar(255),
        requester varchar(255),
        description varchar(1024),
        handler varchar(255),
        renderer varchar(255),
        target_class varchar(255),
        target_id varchar(255),
        target_name varchar(255),
        archived bigint,
        type varchar(255),
        state varchar(255),
        severity varchar(255),
        attributes clob(100000000),
        system_attributes clob(100000000),
        immutable smallint,
        signed smallint,
        completer varchar(255),
        requester_ci generated always as (upper(requester)),
        assignee_ci generated always as (upper(assignee)),
        owner_name_ci generated always as (upper(owner_name)),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_work_item_config (
       id varchar(32) not null,
        created bigint,
        modified bigint,
        owner varchar(32),
        assigned_scope varchar(32),
        assigned_scope_path varchar(450),
        name varchar(128),
        description_template varchar(1024),
        disabled smallint,
        no_work_item smallint,
        owner_rule varchar(32),
        hours_till_escalation integer,
        hours_between_reminders integer,
        max_reminders integer,
        notification_email varchar(32),
        reminder_email varchar(32),
        escalation_email varchar(32),
        escalation_rule varchar(32),
        parent varchar(32),
        primary key (id)
    ) IN identityiq_ts;

    create table identityiq.spt_work_item_owners (
       config varchar(32) not null,
        idx integer not null,
        elt varchar(32) not null,
        primary key (config, idx)
    ) IN identityiq_ts;
create index identityiq.spt_actgroup_attr on identityiq.spt_account_group (reference_attribute);
create index identityiq.spt_actgroup_lastAggregation on identityiq.spt_account_group (last_target_aggregation);
create index identityiq.spt_alert_last_processed on identityiq.spt_alert (last_processed);
create index identityiq.spt_alert_name on identityiq.spt_alert (name);

    alter table identityiq.spt_alert_definition 
       add constraint UK_p9a15ie5pfscgm3hb745wwnsm unique (name);
create index identityiq.spt_app_proxied_name on identityiq.spt_application (proxied_name);
create index identityiq.spt_application_cluster on identityiq.spt_application (app_cluster);
create index identityiq.spt_application_authoritative on identityiq.spt_application (authoritative);
create index identityiq.spt_application_logical on identityiq.spt_application (logical);
create index identityiq.spt_application_provisioning on identityiq.spt_application (supports_provisioning);
create index identityiq.spt_application_authenticate on identityiq.spt_application (supports_authenticate);
create index identityiq.spt_application_acct_only on identityiq.spt_application (supports_account_only);
create index identityiq.spt_application_addt_acct on identityiq.spt_application (supports_additional_accounts);
create index identityiq.spt_application_no_agg on identityiq.spt_application (no_aggregation);
create index identityiq.spt_app_sync_provisioning on identityiq.spt_application (sync_provisioning);
create index identityiq.spt_application_mgd_apps on identityiq.spt_application (manages_other_apps);

    alter table identityiq.spt_application 
       add constraint UK_ol1192j17pnj5syamkr9ecb28 unique (name);
create index identityiq.app_scorecard_cscore on identityiq.spt_application_scorecard (composite_score);

    alter table identityiq.spt_audit_config 
       add constraint UK_g3dye1egpdn4t6ikmfqeohyfa unique (name);
create index identityiq.spt_bundle_disabled on identityiq.spt_bundle (disabled);
create index identityiq.spt_bundle_type on identityiq.spt_bundle (type);

    alter table identityiq.spt_bundle 
       add constraint UK_smf7ppq8j0o6ijtrhh7ga9ck3 unique (name);
create index identityiq.spt_bundle_archive_source on identityiq.spt_bundle_archive (source_id);
create index identityiq.spt_bpr_bundle_id_hash_code on identityiq.spt_bundle_profile_relation (bundle_id, hash_code);
create index identityiq.spt_bpr_type on identityiq.spt_bundle_profile_relation (type);
create index identityiq.spt_bpr_app_status on identityiq.spt_bundle_profile_relation (app_status);
create index identityiq.spt_bprs_bundle_id on identityiq.spt_bundle_profile_relation_step (bundle_id);

    alter table identityiq.spt_capability 
       add constraint UK_icigo0rpdnfxkqv03375j2mnv unique (name);

    alter table identityiq.spt_category 
       add constraint UK_r4nfd0896ly42tur7agn58fl6 unique (name);
create index identityiq.spt_certification_signed on identityiq.spt_certification (signed);
create index identityiq.spt_certification_finished on identityiq.spt_certification (finished);
create index identityiq.spt_cert_auto_close_date on identityiq.spt_certification (automatic_closing_date);
create index identityiq.spt_cert_percent_complete on identityiq.spt_certification (percent_complete);
create index identityiq.spt_cert_nxt_phs_tran on identityiq.spt_certification (next_phase_transition);
create index identityiq.spt_cert_nextRemediationScan on identityiq.spt_certification (next_remediation_scan);
create index identityiq.nxt_cert_req_scan on identityiq.spt_certification (next_cert_required_scan);
create index identityiq.nxt_overdue_scan on identityiq.spt_certification (next_overdue_scan);
create index identityiq.spt_cert_exclude_inactive on identityiq.spt_certification (exclude_inactive);
create index identityiq.spt_cert_electronic_signed on identityiq.spt_certification (electronically_signed);
create index identityiq.spt_item_ready_for_remed on identityiq.spt_certification_action (ready_for_remediation);
create index identityiq.spt_cert_archive_id on identityiq.spt_certification_archive (certification_id);
create index identityiq.spt_cert_archive_grp_id on identityiq.spt_certification_archive (certification_group_id);
create index identityiq.spt_cert_archive_creator on identityiq.spt_certification_archive (creator);

    alter table identityiq.spt_certification_definition 
       add constraint UK_kayn5nry9qy90kk9e9f2e2vut unique (name);
create index identityiq.spt_certification_entity_stat on identityiq.spt_certification_entity (summary_status);
create index identityiq.spt_certification_entity_state on identityiq.spt_certification_entity (continuous_state);
create index identityiq.spt_certification_entity_ld on identityiq.spt_certification_entity (last_decision);
create index identityiq.spt_certification_entity_nsc on identityiq.spt_certification_entity (next_continuous_state_change);
create index identityiq.spt_certification_entity_due on identityiq.spt_certification_entity (overdue_date);
create index identityiq.spt_certification_entity_diffs on identityiq.spt_certification_entity (has_differences);
create index identityiq.spt_certification_entity_tn on identityiq.spt_certification_entity (target_name);
create index identityiq.spt_cert_entity_identity on identityiq.spt_certification_entity (identity_id);
create index identityiq.spt_cert_entity_cscore on identityiq.spt_certification_entity (composite_score);
create index identityiq.spt_cert_entity_new_user on identityiq.spt_certification_entity (new_user);
create index identityiq.spt_cert_entity_pending on identityiq.spt_certification_entity (pending_certification);
create index identityiq.spt_cert_group_type on identityiq.spt_certification_group (type);
create index identityiq.spt_cert_group_status on identityiq.spt_certification_group (status);
create index identityiq.spt_cert_grp_perc_comp on identityiq.spt_certification_group (percent_complete);
create index identityiq.spt_certification_item_stat on identityiq.spt_certification_item (summary_status);
create index identityiq.spt_certification_item_state on identityiq.spt_certification_item (continuous_state);
create index identityiq.spt_certification_item_ld on identityiq.spt_certification_item (last_decision);
create index identityiq.spt_certification_item_nsc on identityiq.spt_certification_item (next_continuous_state_change);
create index identityiq.spt_certification_item_due on identityiq.spt_certification_item (overdue_date);
create index identityiq.spt_certification_item_diffs on identityiq.spt_certification_item (has_differences);
create index identityiq.spt_certification_item_tn on identityiq.spt_certification_item (target_name);
create index identityiq.spt_cert_item_bundle on identityiq.spt_certification_item (bundle);
create index identityiq.spt_cert_item_type on identityiq.spt_certification_item (type);
create index identityiq.spt_needs_refresh on identityiq.spt_certification_item (needs_refresh);
create index identityiq.spt_cert_item_exception_app on identityiq.spt_certification_item (exception_application);
create index identityiq.spt_cert_item_perm_target on identityiq.spt_certification_item (exception_permission_target);
create index identityiq.spt_cert_item_perm_right on identityiq.spt_certification_item (exception_permission_right);
create index identityiq.spt_cert_item_wk_up on identityiq.spt_certification_item (wake_up_date);
create index identityiq.spt_cert_item_phase on identityiq.spt_certification_item (phase);
create index identityiq.spt_cert_item_nxt_phs_tran on identityiq.spt_certification_item (next_phase_transition);

    alter table identityiq.spt_classification 
       add constraint UK_eqb3e1wxju8yopo50ljal8lpg unique (name);

    alter table identityiq.spt_cloud_access_group 
       add constraint UK_dfcupn1yjhukxrl4hs7rf4046 unique (name);

    alter table identityiq.spt_cloud_access_role 
       add constraint UK_ntejuomvc5awi8b6apshil7q3 unique (name);

    alter table identityiq.spt_cloud_access_scope 
       add constraint UK_rj2onrkbufpyxss96wu2i8nt8 unique (name);

    alter table identityiq.spt_configuration 
       add constraint UK_dkxlp7fgtfipuokv9qxaj735g unique (name);

    alter table identityiq.spt_correlation_config 
       add constraint UK_rwy1ty2x8aht5691cdygbjv3l unique (name);
create index identityiq.spt_delObj_lastRefresh on identityiq.spt_deleted_object (last_refresh);

    alter table identityiq.spt_dictionary_term 
       add constraint UK_js3ank2u9ao5bytbttnd249bj unique (value);

    alter table identityiq.spt_dynamic_scope 
       add constraint UK_jamxxk00xqxkiw6nsww52xr2f unique (name);

    alter table identityiq.spt_email_template 
       add constraint UK_op3ic1cyo2k1owya8j156itp0 unique (name);
create index identityiq.file_bucketNumber on identityiq.spt_file_bucket (file_index);

    alter table identityiq.spt_form 
       add constraint UK_8xrdket8a5q8r8c1ab5lmbarr unique (name);

    alter table identityiq.spt_full_text_index 
       add constraint UK_jc9qh3jumoqe46w0ibonmvipk unique (name);
create index identityiq.group_index_cscore on identityiq.spt_group_index (composite_score);
create index identityiq.spt_identity_needs_refresh on identityiq.spt_identity (needs_refresh);
create index identityiq.spt_identity_manager_status on identityiq.spt_identity (manager_status);
create index identityiq.spt_identity_inactive on identityiq.spt_identity (inactive);
create index identityiq.spt_identity_lastRefresh on identityiq.spt_identity (last_refresh);
create index identityiq.spt_identity_correlated on identityiq.spt_identity (correlated);
create index identityiq.spt_identity_isworkgroup on identityiq.spt_identity (workgroup);

    alter table identityiq.spt_identity 
       add constraint UK_afdtg40pi16y2smshwjgj2g6h unique (name);
create index identityiq.spt_identity_archive_source on identityiq.spt_identity_archive (source_id);
create index identityiq.spt_identity_ent_ag_state on identityiq.spt_identity_entitlement (aggregation_state);
create index identityiq.spt_identity_ent_assigned on identityiq.spt_identity_entitlement (assigned);
create index identityiq.spt_identity_ent_allowed on identityiq.spt_identity_entitlement (allowed);
create index identityiq.spt_identity_ent_role_granted on identityiq.spt_identity_entitlement (granted_by_role);
create index identityiq.spt_identity_ent_assgnid on identityiq.spt_identity_entitlement (assignment_id);
create index identityiq.spt_identity_ent_type on identityiq.spt_identity_entitlement (type);
create index identityiq.spt_id_hist_item_cert_type on identityiq.spt_identity_history_item (certification_type);
create index identityiq.spt_id_hist_item_status on identityiq.spt_identity_history_item (status);
create index identityiq.spt_id_hist_item_actor on identityiq.spt_identity_history_item (actor);
create index identityiq.spt_id_hist_item_entry_date on identityiq.spt_identity_history_item (entry_date);
create index identityiq.spt_id_hist_item_application on identityiq.spt_identity_history_item (application);
create index identityiq.spt_id_hist_item_instance on identityiq.spt_identity_history_item (instance);
create index identityiq.spt_id_hist_item_policy on identityiq.spt_identity_history_item (policy);
create index identityiq.spt_id_hist_item_role on identityiq.spt_identity_history_item (role);
create index identityiq.spt_idrequest_name on identityiq.spt_identity_request (name);
create index identityiq.spt_idrequest_state on identityiq.spt_identity_request (state);
create index identityiq.spt_idrequest_type on identityiq.spt_identity_request (type);
create index identityiq.spt_idrequest_target_id on identityiq.spt_identity_request (target_id);
create index identityiq.spt_idrequest_requestor_id on identityiq.spt_identity_request (requester_id);
create index identityiq.spt_idrequest_endDate on identityiq.spt_identity_request (end_date);
create index identityiq.spt_idrequest_verified on identityiq.spt_identity_request (verified);
create index identityiq.spt_idrequest_priority on identityiq.spt_identity_request (priority);
create index identityiq.spt_idrequest_compl_status on identityiq.spt_identity_request (completion_status);
create index identityiq.spt_idrequest_exec_status on identityiq.spt_identity_request (execution_status);
create index identityiq.spt_idrequest_has_messages on identityiq.spt_identity_request (has_messages);
create index identityiq.spt_reqitem_ownername on identityiq.spt_identity_request_item (owner_name);
create index identityiq.spt_reqitem_approvername on identityiq.spt_identity_request_item (approver_name);
create index identityiq.spt_reqitem_approval_state on identityiq.spt_identity_request_item (approval_state);
create index identityiq.spt_reqitem_provisioning_state on identityiq.spt_identity_request_item (provisioning_state);
create index identityiq.spt_reqitem_comp_status on identityiq.spt_identity_request_item (compilation_status);
create index identityiq.spt_reqitem_exp_cause on identityiq.spt_identity_request_item (expansion_cause);
create index identityiq.spt_identity_id on identityiq.spt_identity_snapshot (identity_id);
create index identityiq.spt_idsnap_id_name on identityiq.spt_identity_snapshot (identity_name);

    alter table identityiq.spt_integration_config 
       add constraint UK_ktnweagpbwlxvsst5icni3epm unique (name);
create index identityiq.bucketNumber on identityiq.spt_jasper_page_bucket (bucket_number);
create index identityiq.handlerId on identityiq.spt_jasper_page_bucket (handler_id);

    alter table identityiq.spt_jasper_template 
       add constraint UK_4sukasjpluq6bcpu1vybgn6o3 unique (name);
create index identityiq.spt_link_lastRefresh on identityiq.spt_link (last_refresh);
create index identityiq.spt_link_lastAggregation on identityiq.spt_link (last_target_aggregation);
create index identityiq.spt_link_entitlements on identityiq.spt_link (entitlements);
create index identityiq.spt_link_iiq_disabled on identityiq.spt_link (iiq_disabled);
create index identityiq.spt_link_iiq_locked on identityiq.spt_link (iiq_locked);
create index identityiq.spt_localized_attr_name on identityiq.spt_localized_attribute (name);
create index identityiq.spt_localized_attr_locale on identityiq.spt_localized_attribute (locale);
create index identityiq.spt_localized_attr_attr on identityiq.spt_localized_attribute (attribute);
create index identityiq.spt_localized_attr_targetname on identityiq.spt_localized_attribute (target_name);
create index identityiq.spt_localized_attr_targetid on identityiq.spt_localized_attribute (target_id);
create index identityiq.spt_managed_attr_type on identityiq.spt_managed_attribute (type);
create index identityiq.spt_managed_attr_aggregated on identityiq.spt_managed_attribute (aggregated);
create index identityiq.spt_managed_attr_requestable on identityiq.spt_managed_attribute (requestable);
create index identityiq.spt_managed_attr_last_tgt_agg on identityiq.spt_managed_attribute (last_target_aggregation);

    alter table identityiq.spt_managed_attribute 
       add constraint UK_prmbsvo2fb4pei4ff9a5m2kso unique (hash);

    alter table identityiq.spt_message_template 
       add constraint UK_husdj437loithtt5rgxwx3oqv unique (name);

    alter table identityiq.spt_mining_config 
       add constraint UK_t2qyp373evmrsowd6svdi6ljk unique (name);
create index identityiq.spt_mitigation_role on identityiq.spt_mitigation_expiration (role_name);
create index identityiq.spt_mitigation_policy on identityiq.spt_mitigation_expiration (policy);
create index identityiq.spt_mitigation_app on identityiq.spt_mitigation_expiration (application);
create index identityiq.spt_mitigation_instance on identityiq.spt_mitigation_expiration (instance);
create index identityiq.spt_mitigation_permission on identityiq.spt_mitigation_expiration (permission);

    alter table identityiq.spt_module 
       add constraint UK_bebq8nsflsucu90sph68pf43r unique (name);

    alter table identityiq.spt_monitoring_statistic 
       add constraint UK_k7skupvvbqf88k94pd6ukh49c unique (name);
create index identityiq.spt_classification_owner_id on identityiq.spt_object_classification (owner_id);
create index identityiq.spt_class_owner_type on identityiq.spt_object_classification (owner_type);

    alter table identityiq.spt_object_config 
       add constraint UK_thw4nv9d2kok4jrqbcg7ume8h unique (name);
create index identityiq.spt_partition_status on identityiq.spt_partition_result (completion_status);

    alter table identityiq.spt_partition_result 
       add constraint UK_9hkfjsotujyf84i2ilkevu3no unique (name);

    alter table identityiq.spt_password_policy 
       add constraint UK_ousim2j29ecrtdoppi5diwmxr unique (name);
create unique index UK_c7ccr73vpnee48igqv6w9spmp on identityiq.spt_plugin (file_id);

    alter table identityiq.spt_policy 
       add constraint UK_lgdxftlbfwbn2c2jtptk4tkt4 unique (name);
create index identityiq.spt_policy_violation_active on identityiq.spt_policy_violation (active);
create index identityiq.spt_process_log_process_name on identityiq.spt_process_log (process_name);
create index identityiq.spt_process_log_case_id on identityiq.spt_process_log (case_id);
create index identityiq.spt_process_log_wf_case_name on identityiq.spt_process_log (workflow_case_name);
create index identityiq.spt_process_log_case_status on identityiq.spt_process_log (case_status);
create index identityiq.spt_process_log_step_name on identityiq.spt_process_log (step_name);
create index identityiq.spt_process_log_approval_name on identityiq.spt_process_log (approval_name);
create index identityiq.spt_process_log_owner_name on identityiq.spt_process_log (owner_name);
create index identityiq.spt_provreq_expiration on identityiq.spt_provisioning_request (expiration);
create index identityiq.spt_prvtrans_name on identityiq.spt_provisioning_transaction (name);
create index identityiq.spt_prvtrans_created on identityiq.spt_provisioning_transaction (created);
create index identityiq.spt_prvtrans_op on identityiq.spt_provisioning_transaction (operation);
create index identityiq.spt_prvtrans_src on identityiq.spt_provisioning_transaction (source);
create index identityiq.spt_prvtrans_forced on identityiq.spt_provisioning_transaction (forced);
create index identityiq.spt_prvtrans_type on identityiq.spt_provisioning_transaction (type);
create index identityiq.spt_prvtrans_status on identityiq.spt_provisioning_transaction (status);

    alter table identityiq.spt_quick_link 
       add constraint UK_merms3cmmi5yrruxr338mbh7d unique (name);

    alter table identityiq.spt_recommender_definition 
       add constraint UK_ekuvq6a1uhwkxb7fofir077xv unique (name);
create index identityiq.spt_remote_login_expiration on identityiq.spt_remote_login_token (expiration);
create index identityiq.spt_request_expiration on identityiq.spt_request (expiration);
create index identityiq.spt_request_name on identityiq.spt_request (name);
create index identityiq.spt_request_phase on identityiq.spt_request (phase);
create index identityiq.spt_request_depPhase on identityiq.spt_request (dependent_phase);
create index identityiq.spt_request_nextLaunch on identityiq.spt_request (next_launch);
create index identityiq.spt_request_compl_status on identityiq.spt_request (completion_status);
create index identityiq.spt_request_notif_needed on identityiq.spt_request (notification_needed);

    alter table identityiq.spt_request_definition 
       add constraint UK_3nt4yuuvbl2byvkendp3j4agv unique (name);

    alter table identityiq.spt_right_config 
       add constraint UK_kcvm6fgx3ncfka1e91frbq594 unique (name);
create index identityiq.spt_rce_status on identityiq.spt_role_change_event (status);
create index identityiq.role_index_cscore on identityiq.spt_role_index (composite_score);

    alter table identityiq.spt_rule 
       add constraint UK_sy7p5bybnsqmi3odg5twi35al unique (name);

    alter table identityiq.spt_rule_registry 
       add constraint UK_rhm4bwwsb05g3kcpdyy0gajev unique (name);
create index identityiq.spt_app_attr_mod on identityiq.spt_schema_attributes (remed_mod_type);
create index identityiq.scope_path on identityiq.spt_scope (path);
create index identityiq.scope_dirty on identityiq.spt_scope (dirty);
create index identityiq.identity_scorecard_cscore on identityiq.spt_scorecard (composite_score);

    alter table identityiq.spt_score_config 
       add constraint UK_dmwfxhf88xip0d78xe5yebuuc unique (name);

    alter table identityiq.spt_server 
       add constraint UK_kf14wilyojkxlsph6yo46nhf8 unique (name);
create index identityiq.server_stat_snapshot on identityiq.spt_server_statistic (snapshot_name);

    alter table identityiq.spt_service_definition 
       add constraint UK_62qdarwripq8h3mmibl1pg8or unique (name);
create unique index UK_su52ugaros4i67n6s56beyyby on identityiq.spt_service_lock (service_definition);

    alter table identityiq.spt_service_status 
       add constraint UK_3xrmomphbxmv4wc27d9nyk654 unique (name);
create index identityiq.sign_off_history_signer_id on identityiq.spt_sign_off_history (signer_id);
create index identityiq.spt_sign_off_history_esig on identityiq.spt_sign_off_history (electronic_sign);
create index identityiq.spt_arch_entity_app on identityiq.spt_archived_cert_entity (application);
create index identityiq.spt_arch_entity_native_id on identityiq.spt_archived_cert_entity (native_identity);
create index identityiq.spt_arch_entity_ref_attr on identityiq.spt_archived_cert_entity (reference_attribute);
create index identityiq.spt_arch_entity_target_id on identityiq.spt_archived_cert_entity (target_id);
create index identityiq.spt_arch_entity_tgt_display on identityiq.spt_archived_cert_entity (target_display_name);
create index identityiq.spt_arch_cert_item_type on identityiq.spt_archived_cert_item (type);
create index identityiq.spt_arch_item_app on identityiq.spt_archived_cert_item (exception_application);
create index identityiq.spt_arch_item_native_id on identityiq.spt_archived_cert_item (exception_native_identity);
create index identityiq.spt_arch_item_policy on identityiq.spt_archived_cert_item (policy);
create index identityiq.spt_arch_item_bundle on identityiq.spt_archived_cert_item (bundle);
create index identityiq.spt_arch_cert_item_tdisplay on identityiq.spt_archived_cert_item (target_display_name);
create index identityiq.spt_arch_cert_item_tname on identityiq.spt_archived_cert_item (target_name);
create index identityiq.spt_pend_attach_item on identityiq.spt_pending_req_attach (item_id);
create index identityiq.spt_pend_attach_req on identityiq.spt_pending_req_attach (requester_id);

    alter table identityiq.spt_right 
       add constraint UK_jral3yg4vxqqx5cd3ef43p2pl unique (name);
create index identityiq.spt_syslog_created on identityiq.spt_syslog_event (created);
create index identityiq.spt_syslog_quickKey on identityiq.spt_syslog_event (quick_key);
create index identityiq.spt_syslog_event_level on identityiq.spt_syslog_event (event_level);
create index identityiq.spt_syslog_classname on identityiq.spt_syslog_event (classname);
create index identityiq.spt_syslog_message on identityiq.spt_syslog_event (message);
create index identityiq.spt_syslog_server on identityiq.spt_syslog_event (server);
create index identityiq.spt_syslog_username on identityiq.spt_syslog_event (username);

    alter table identityiq.spt_tag 
       add constraint UK_ky9sm7nb1boucsf89s7a854p8 unique (name);
create index identityiq.spt_target_unique_name_hash on identityiq.spt_target (unique_name_hash);
create index identityiq.spt_target_native_obj_id on identityiq.spt_target (native_object_id);
create index identityiq.spt_target_last_agg on identityiq.spt_target (last_aggregation);
create index identityiq.spt_target_assoc_id on identityiq.spt_target_association (object_id);
create index identityiq.spt_target_assoc_last_agg on identityiq.spt_target_association (last_aggregation);
create index identityiq.spt_task_deprecated on identityiq.spt_task_definition (deprecated);

    alter table identityiq.spt_task_definition 
       add constraint UK_ngpdc5e2vfx0bgg3onr5wwi8h unique (name);
create index identityiq.spt_task_event_phase on identityiq.spt_task_event (phase);
create index identityiq.spt_taskres_completed on identityiq.spt_task_result (completed);
create index identityiq.spt_taskres_expiration on identityiq.spt_task_result (expiration);
create index identityiq.spt_taskres_verified on identityiq.spt_task_result (verified);
create index identityiq.spt_taskresult_schedule on identityiq.spt_task_result (schedule);
create index identityiq.spt_taskresult_target on identityiq.spt_task_result (target_id);
create index identityiq.spt_task_compl_status on identityiq.spt_task_result (completion_status);

    alter table identityiq.spt_task_result 
       add constraint UK_6p0er3vv16g3lmh9xw3iysskw unique (name);

    alter table identityiq.spt_uiconfig 
       add constraint UK_k68d5hs1pn9mtga8t5ff62j2b unique (name);

    alter table identityiq.spt_widget 
       add constraint UK_4by84g4xwhbk5n949cqe1f4p7 unique (name);

    alter table identityiq.spt_workflow 
       add constraint UK_1364j5ejd8rifs8f4shf0avak unique (name);
create index identityiq.spt_workflowcase_target on identityiq.spt_workflow_case (target_id);

    alter table identityiq.spt_workflow_registry 
       add constraint UK_f4aqigwy74tvdfhs90l2e8mmf unique (name);

    alter table identityiq.spt_workflow_test_suite 
       add constraint UK_9db88vtedq9ehu425aarf6jxt unique (name);
create index identityiq.spt_work_item_name on identityiq.spt_work_item (name);
create index identityiq.spt_work_item_target on identityiq.spt_work_item (target_id);
create index identityiq.spt_work_item_type on identityiq.spt_work_item (type);
create index identityiq.spt_work_item_ident_req_id on identityiq.spt_work_item (identity_request_id);
create index identityiq.spt_item_archive_workItemId on identityiq.spt_work_item_archive (work_item_id);
create index identityiq.spt_item_archive_name on identityiq.spt_work_item_archive (name);
create index identityiq.spt_item_archive_ident_req on identityiq.spt_work_item_archive (identity_request_id);
create index identityiq.spt_item_archive_target on identityiq.spt_work_item_archive (target_id);
create index identityiq.spt_item_archive_type on identityiq.spt_work_item_archive (type);
create index identityiq.spt_item_archive_severity on identityiq.spt_work_item_archive (severity);
create index identityiq.spt_item_archive_completer on identityiq.spt_work_item_archive (completer);

    alter table identityiq.spt_account_group 
       add constraint FK81npondqko61p2jbiurtiyjjh 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK81npondqko61p2jbiurtiyjjh on identityiq.spt_account_group (owner);

    alter table identityiq.spt_account_group 
       add constraint FK34oc5rgrwidh1xfn80u7hw6ty 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK34oc5rgrwidh1xfn80u7hw6ty on identityiq.spt_account_group (assigned_scope);

    alter table identityiq.spt_account_group 
       add constraint FKr2yvl55h4eygmk9g025u7knhg 
       foreign key (application) 
       references identityiq.spt_application;

    create index identityiq.FKr2yvl55h4eygmk9g025u7knhg on identityiq.spt_account_group (application);

    alter table identityiq.spt_account_group_inheritance 
       add constraint FK37nc4s7oaae0og1ks6qawxw5v 
       foreign key (inherits_from) 
       references identityiq.spt_account_group;

    create index identityiq.FK37nc4s7oaae0og1ks6qawxw5v on identityiq.spt_account_group_inheritance (inherits_from);

    alter table identityiq.spt_account_group_inheritance 
       add constraint FKmapn2o892qhdmaa1r4lemvgax 
       foreign key (account_group) 
       references identityiq.spt_account_group;

    create index identityiq.FKmapn2o892qhdmaa1r4lemvgax on identityiq.spt_account_group_inheritance (account_group);

    alter table identityiq.spt_account_group_perms 
       add constraint FKiapqdfk3kcuq5jv68yxi5x7tx 
       foreign key (accountgroup) 
       references identityiq.spt_account_group;

    create index identityiq.FKiapqdfk3kcuq5jv68yxi5x7tx on identityiq.spt_account_group_perms (accountgroup);

    alter table identityiq.spt_account_group_target_perms 
       add constraint FK13f1jdxrqvk98rjhyw2nsywcj 
       foreign key (accountgroup) 
       references identityiq.spt_account_group;

    create index identityiq.FK13f1jdxrqvk98rjhyw2nsywcj on identityiq.spt_account_group_target_perms (accountgroup);

    alter table identityiq.spt_activity_constraint 
       add constraint FKh07lkkaqonsf23oaqaiiowgxa 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKh07lkkaqonsf23oaqaiiowgxa on identityiq.spt_activity_constraint (owner);

    alter table identityiq.spt_activity_constraint 
       add constraint FK84atg8et8jhm2q2xrbc8y3mmg 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK84atg8et8jhm2q2xrbc8y3mmg on identityiq.spt_activity_constraint (assigned_scope);

    alter table identityiq.spt_activity_constraint 
       add constraint FK54edcjc3jxlcm0n4x49vwmqbr 
       foreign key (policy) 
       references identityiq.spt_policy;

    create index identityiq.FK54edcjc3jxlcm0n4x49vwmqbr on identityiq.spt_activity_constraint (policy);

    alter table identityiq.spt_activity_constraint 
       add constraint FKi1i3q8kvh4ed7e734iwrmbkqp 
       foreign key (violation_owner) 
       references identityiq.spt_identity;

    create index identityiq.FKi1i3q8kvh4ed7e734iwrmbkqp on identityiq.spt_activity_constraint (violation_owner);

    alter table identityiq.spt_activity_constraint 
       add constraint FKe1iukekxihoxdeji16gk4540c 
       foreign key (violation_owner_rule) 
       references identityiq.spt_rule;

    create index identityiq.FKe1iukekxihoxdeji16gk4540c on identityiq.spt_activity_constraint (violation_owner_rule);

    alter table identityiq.spt_activity_data_source 
       add constraint FK4nyoyf6fj2n0iqv4x6hy3p5a0 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK4nyoyf6fj2n0iqv4x6hy3p5a0 on identityiq.spt_activity_data_source (owner);

    alter table identityiq.spt_activity_data_source 
       add constraint FK9xs1b8n9mbigik443n155ils7 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK9xs1b8n9mbigik443n155ils7 on identityiq.spt_activity_data_source (assigned_scope);

    alter table identityiq.spt_activity_data_source 
       add constraint FKa7oof6hhnyj73cgy991qj4159 
       foreign key (correlation_rule) 
       references identityiq.spt_rule;

    create index identityiq.FKa7oof6hhnyj73cgy991qj4159 on identityiq.spt_activity_data_source (correlation_rule);

    alter table identityiq.spt_activity_data_source 
       add constraint FK4t11m9gcjjxe4uhtlkab3mkh4 
       foreign key (transformation_rule) 
       references identityiq.spt_rule;

    create index identityiq.FK4t11m9gcjjxe4uhtlkab3mkh4 on identityiq.spt_activity_data_source (transformation_rule);

    alter table identityiq.spt_activity_data_source 
       add constraint FKqh1mk9ywu09wfephle51xm9j 
       foreign key (application) 
       references identityiq.spt_application;

    create index identityiq.FKqh1mk9ywu09wfephle51xm9j on identityiq.spt_activity_data_source (application);

    alter table identityiq.spt_activity_time_periods 
       add constraint FKdf7oxva0h2xktfgb8ro54gd5 
       foreign key (time_period) 
       references identityiq.spt_time_period;

    create index identityiq.FKdf7oxva0h2xktfgb8ro54gd5 on identityiq.spt_activity_time_periods (time_period);

    alter table identityiq.spt_activity_time_periods 
       add constraint FKbxg0qs6lvogays6vb2niyqgjk 
       foreign key (application_activity) 
       references identityiq.spt_application_activity;

    create index identityiq.FKbxg0qs6lvogays6vb2niyqgjk on identityiq.spt_activity_time_periods (application_activity);

    alter table identityiq.spt_alert 
       add constraint FKjpmc8vdbv8mso3deakv8qi5dd 
       foreign key (source) 
       references identityiq.spt_application;

    create index identityiq.FKjpmc8vdbv8mso3deakv8qi5dd on identityiq.spt_alert (source);

    alter table identityiq.spt_alert_action 
       add constraint FK4kt6nnjdocmdkgcv3wgdfvfyg 
       foreign key (alert) 
       references identityiq.spt_alert;

    create index identityiq.FK4kt6nnjdocmdkgcv3wgdfvfyg on identityiq.spt_alert_action (alert);

    alter table identityiq.spt_alert_definition 
       add constraint FKm2f36vhlf1u9vnf5w1rm21i0q 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKm2f36vhlf1u9vnf5w1rm21i0q on identityiq.spt_alert_definition (owner);

    alter table identityiq.spt_alert_definition 
       add constraint FK7nrecpxk2mr7mwgli5tk5kiq9 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK7nrecpxk2mr7mwgli5tk5kiq9 on identityiq.spt_alert_definition (assigned_scope);

    alter table identityiq.spt_app_dependencies 
       add constraint FKg99wvor3c1wxfmvd1j1vekrk1 
       foreign key (dependency) 
       references identityiq.spt_application;

    create index identityiq.FKg99wvor3c1wxfmvd1j1vekrk1 on identityiq.spt_app_dependencies (dependency);

    alter table identityiq.spt_app_dependencies 
       add constraint FKfimmxii9xcyjfmgd0489d2q61 
       foreign key (application) 
       references identityiq.spt_application;

    create index identityiq.FKfimmxii9xcyjfmgd0489d2q61 on identityiq.spt_app_dependencies (application);

    alter table identityiq.spt_application 
       add constraint FKo50q3ykyumpddcaaokonvivah 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKo50q3ykyumpddcaaokonvivah on identityiq.spt_application (owner);

    alter table identityiq.spt_application 
       add constraint FKjrqhmrsoaxkmetjcd0y3vo09r 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKjrqhmrsoaxkmetjcd0y3vo09r on identityiq.spt_application (assigned_scope);

    alter table identityiq.spt_application 
       add constraint FKr6orbi6gkpkds9hrhowsym3yy 
       foreign key (proxy) 
       references identityiq.spt_application;

    create index identityiq.FKr6orbi6gkpkds9hrhowsym3yy on identityiq.spt_application (proxy);

    alter table identityiq.spt_application 
       add constraint FKo2741mu93ute68xlirxg7ysja 
       foreign key (correlation_rule) 
       references identityiq.spt_rule;

    create index identityiq.FKo2741mu93ute68xlirxg7ysja on identityiq.spt_application (correlation_rule);

    alter table identityiq.spt_application 
       add constraint FKam9m6cw3jgye54ltd2xrnk818 
       foreign key (creation_rule) 
       references identityiq.spt_rule;

    create index identityiq.FKam9m6cw3jgye54ltd2xrnk818 on identityiq.spt_application (creation_rule);

    alter table identityiq.spt_application 
       add constraint FK27agl8inv18vxa370rnhbss30 
       foreign key (manager_correlation_rule) 
       references identityiq.spt_rule;

    create index identityiq.FK27agl8inv18vxa370rnhbss30 on identityiq.spt_application (manager_correlation_rule);

    alter table identityiq.spt_application 
       add constraint FKntlbgo69p5yhm3litlje9798g 
       foreign key (customization_rule) 
       references identityiq.spt_rule;

    create index identityiq.FKntlbgo69p5yhm3litlje9798g on identityiq.spt_application (customization_rule);

    alter table identityiq.spt_application 
       add constraint FKinlcagndni6i9xdctdivcl2ne 
       foreign key (managed_attr_customize_rule) 
       references identityiq.spt_rule;

    create index identityiq.FKinlcagndni6i9xdctdivcl2ne on identityiq.spt_application (managed_attr_customize_rule);

    alter table identityiq.spt_application 
       add constraint FKhwhrrykvnnguijemwxxd5sn8t 
       foreign key (account_correlation_config) 
       references identityiq.spt_correlation_config;

    create index identityiq.FKhwhrrykvnnguijemwxxd5sn8t on identityiq.spt_application (account_correlation_config);

    alter table identityiq.spt_application 
       add constraint FKpen32pdmnkn8icwjkusye7uul 
       foreign key (scorecard) 
       references identityiq.spt_application_scorecard;

    create index identityiq.FKpen32pdmnkn8icwjkusye7uul on identityiq.spt_application (scorecard);

    alter table identityiq.spt_application 
       add constraint FKbdx986tnctokxdrqw8q77s5rm 
       foreign key (target_source) 
       references identityiq.spt_target_source;

    create index identityiq.FKbdx986tnctokxdrqw8q77s5rm on identityiq.spt_application (target_source);

    alter table identityiq.spt_application_remediators 
       add constraint FK362oq0bg8kyjh8a8x6b870jkx 
       foreign key (elt) 
       references identityiq.spt_identity;

    create index identityiq.FK362oq0bg8kyjh8a8x6b870jkx on identityiq.spt_application_remediators (elt);

    alter table identityiq.spt_application_remediators 
       add constraint FK8csqgw7ff1rb2f1y0gtl4nbcc 
       foreign key (application) 
       references identityiq.spt_application;

    create index identityiq.FK8csqgw7ff1rb2f1y0gtl4nbcc on identityiq.spt_application_remediators (application);

    alter table identityiq.spt_application_activity 
       add constraint FKp0r4scrot0prnyokpjxt2649j 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKp0r4scrot0prnyokpjxt2649j on identityiq.spt_application_activity (assigned_scope);

    alter table identityiq.spt_application_schema 
       add constraint FKkd8l977v65omox0wln8f6j20u 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKkd8l977v65omox0wln8f6j20u on identityiq.spt_application_schema (owner);

    alter table identityiq.spt_application_schema 
       add constraint FKl0g1ud8tainvo5qqgw0vsyum6 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKl0g1ud8tainvo5qqgw0vsyum6 on identityiq.spt_application_schema (assigned_scope);

    alter table identityiq.spt_application_schema 
       add constraint FK4sj1w1c5l3xn6dl2mbfmcgq95 
       foreign key (creation_rule) 
       references identityiq.spt_rule;

    create index identityiq.FK4sj1w1c5l3xn6dl2mbfmcgq95 on identityiq.spt_application_schema (creation_rule);

    alter table identityiq.spt_application_schema 
       add constraint FKcm5n6jy4gyawyrrv3ge1e7fqc 
       foreign key (customization_rule) 
       references identityiq.spt_rule;

    create index identityiq.FKcm5n6jy4gyawyrrv3ge1e7fqc on identityiq.spt_application_schema (customization_rule);

    alter table identityiq.spt_application_schema 
       add constraint FKov3msut61m895vk42fljyh68i 
       foreign key (correlation_rule) 
       references identityiq.spt_rule;

    create index identityiq.FKov3msut61m895vk42fljyh68i on identityiq.spt_application_schema (correlation_rule);

    alter table identityiq.spt_application_schema 
       add constraint FK78hblkspg3qrgy9uy4yh6amt2 
       foreign key (refresh_rule) 
       references identityiq.spt_rule;

    create index identityiq.FK78hblkspg3qrgy9uy4yh6amt2 on identityiq.spt_application_schema (refresh_rule);

    alter table identityiq.spt_application_schema 
       add constraint FKd3sov5jd5q1tvg43bervh4isw 
       foreign key (application) 
       references identityiq.spt_application;

    create index identityiq.FKd3sov5jd5q1tvg43bervh4isw on identityiq.spt_application_schema (application);

    alter table identityiq.spt_application_scorecard 
       add constraint FKgq6j2537q2t6enu2ots2gwlug 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKgq6j2537q2t6enu2ots2gwlug on identityiq.spt_application_scorecard (owner);

    alter table identityiq.spt_application_scorecard 
       add constraint FKd25itmjnbgivvbvknkbs4dko2 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKd25itmjnbgivvbvknkbs4dko2 on identityiq.spt_application_scorecard (assigned_scope);

    alter table identityiq.spt_application_scorecard 
       add constraint FKncvny5il4loprlf8ed4vkkm5o 
       foreign key (application_id) 
       references identityiq.spt_application;

    create index identityiq.FKncvny5il4loprlf8ed4vkkm5o on identityiq.spt_application_scorecard (application_id);

    alter table identityiq.spt_app_secondary_owners 
       add constraint FKre2f8vro021ipil4lgflrrx9p 
       foreign key (elt) 
       references identityiq.spt_identity;

    create index identityiq.FKre2f8vro021ipil4lgflrrx9p on identityiq.spt_app_secondary_owners (elt);

    alter table identityiq.spt_app_secondary_owners 
       add constraint FK5paly2u3hu7s3cnlx9er1tcfg 
       foreign key (application) 
       references identityiq.spt_application;

    create index identityiq.FK5paly2u3hu7s3cnlx9er1tcfg on identityiq.spt_app_secondary_owners (application);

    alter table identityiq.spt_arch_cert_item_apps 
       add constraint FKjsbh6q9006l09jd5qso3kyn33 
       foreign key (arch_cert_item_id) 
       references identityiq.spt_archived_cert_item;

    create index identityiq.FKjsbh6q9006l09jd5qso3kyn33 on identityiq.spt_arch_cert_item_apps (arch_cert_item_id);

    alter table identityiq.spt_attachment 
       add constraint FKbyb94bn214vosuh3a9cr6ydi3 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKbyb94bn214vosuh3a9cr6ydi3 on identityiq.spt_attachment (owner);

    alter table identityiq.spt_attachment 
       add constraint FKn1iv5d2bgun4hh7gmnyqyl0u7 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKn1iv5d2bgun4hh7gmnyqyl0u7 on identityiq.spt_attachment (assigned_scope);

    alter table identityiq.spt_audit_config 
       add constraint FKn99ngjtt90uu0e6osp4ben0k0 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKn99ngjtt90uu0e6osp4ben0k0 on identityiq.spt_audit_config (owner);

    alter table identityiq.spt_audit_config 
       add constraint FKnbd331q7w6aqq9xs5d2wmi63u 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKnbd331q7w6aqq9xs5d2wmi63u on identityiq.spt_audit_config (assigned_scope);

    alter table identityiq.spt_audit_event 
       add constraint FKhhxtrj41bo44qrvg1d0m5ytsy 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKhhxtrj41bo44qrvg1d0m5ytsy on identityiq.spt_audit_event (owner);

    alter table identityiq.spt_audit_event 
       add constraint FK98m5i7uik1q162vtvklx4uwxy 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK98m5i7uik1q162vtvklx4uwxy on identityiq.spt_audit_event (assigned_scope);

    alter table identityiq.spt_authentication_answer 
       add constraint FKg7ahr1e8ce0qnpwy5ukybfdlc 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKg7ahr1e8ce0qnpwy5ukybfdlc on identityiq.spt_authentication_answer (owner);

    alter table identityiq.spt_authentication_answer 
       add constraint FKeadtkbftr4xwev6djc6bt0crh 
       foreign key (identity_id) 
       references identityiq.spt_identity;

    create index identityiq.FKeadtkbftr4xwev6djc6bt0crh on identityiq.spt_authentication_answer (identity_id);

    alter table identityiq.spt_authentication_answer 
       add constraint FKt1ogpk91rvbm8w1e532nocdif 
       foreign key (question_id) 
       references identityiq.spt_authentication_question;

    create index identityiq.FKt1ogpk91rvbm8w1e532nocdif on identityiq.spt_authentication_answer (question_id);

    alter table identityiq.spt_authentication_question 
       add constraint FKo1do8f67g11idf1a7147kjvvi 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKo1do8f67g11idf1a7147kjvvi on identityiq.spt_authentication_question (owner);

    alter table identityiq.spt_authentication_question 
       add constraint FKhwy7jvglm1yvvhjej8npruff2 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKhwy7jvglm1yvvhjej8npruff2 on identityiq.spt_authentication_question (assigned_scope);

    alter table identityiq.spt_batch_request 
       add constraint FKkv0v31yspj4ga5o9x6pigtmbk 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKkv0v31yspj4ga5o9x6pigtmbk on identityiq.spt_batch_request (owner);

    alter table identityiq.spt_batch_request 
       add constraint FKmi63tgq6kqghkrypoin7pqh5a 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKmi63tgq6kqghkrypoin7pqh5a on identityiq.spt_batch_request (assigned_scope);

    alter table identityiq.spt_batch_request_item 
       add constraint FK4uxgxj681uaiqpw0qku9fu49p 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK4uxgxj681uaiqpw0qku9fu49p on identityiq.spt_batch_request_item (owner);

    alter table identityiq.spt_batch_request_item 
       add constraint FK8utyq880cffo95ui7mxr5tok8 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK8utyq880cffo95ui7mxr5tok8 on identityiq.spt_batch_request_item (assigned_scope);

    alter table identityiq.spt_batch_request_item 
       add constraint FKocx3j2y8pqextntj6l74qvlcj 
       foreign key (batch_request_id) 
       references identityiq.spt_batch_request;

    create index identityiq.FKocx3j2y8pqextntj6l74qvlcj on identityiq.spt_batch_request_item (batch_request_id);

    alter table identityiq.spt_bundle 
       add constraint FKo1g4dgf57gojmopj8cmavgxjk 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKo1g4dgf57gojmopj8cmavgxjk on identityiq.spt_bundle (owner);

    alter table identityiq.spt_bundle 
       add constraint FKbke0asxsp6fxyv9i8ax4dfis0 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKbke0asxsp6fxyv9i8ax4dfis0 on identityiq.spt_bundle (assigned_scope);

    alter table identityiq.spt_bundle 
       add constraint FKimfl4xyw45yyv2wvsq9ymploe 
       foreign key (join_rule) 
       references identityiq.spt_rule;

    create index identityiq.FKimfl4xyw45yyv2wvsq9ymploe on identityiq.spt_bundle (join_rule);

    alter table identityiq.spt_bundle 
       add constraint FKg6aah205ahbj6cdnu067npuqn 
       foreign key (pending_workflow) 
       references identityiq.spt_workflow_case;

    create index identityiq.FKg6aah205ahbj6cdnu067npuqn on identityiq.spt_bundle (pending_workflow);

    alter table identityiq.spt_bundle 
       add constraint FKouwy1vyabs54byfgq0md6xg98 
       foreign key (role_index) 
       references identityiq.spt_role_index;

    create index identityiq.FKouwy1vyabs54byfgq0md6xg98 on identityiq.spt_bundle (role_index);

    alter table identityiq.spt_bundle 
       add constraint FK8q7rqxa31n8e4byky2su1aul7 
       foreign key (scorecard) 
       references identityiq.spt_role_scorecard;

    create index identityiq.FK8q7rqxa31n8e4byky2su1aul7 on identityiq.spt_bundle (scorecard);

    alter table identityiq.spt_bundle_archive 
       add constraint FK9ikprcio0wk332m95ja8i99nm 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK9ikprcio0wk332m95ja8i99nm on identityiq.spt_bundle_archive (owner);

    alter table identityiq.spt_bundle_archive 
       add constraint FKsoj8lev1leryowpm7imnqq2g1 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKsoj8lev1leryowpm7imnqq2g1 on identityiq.spt_bundle_archive (assigned_scope);

    alter table identityiq.spt_bundle_children 
       add constraint FKb47g0894bupcgkm3ram9lepgi 
       foreign key (child) 
       references identityiq.spt_bundle;

    create index identityiq.FKb47g0894bupcgkm3ram9lepgi on identityiq.spt_bundle_children (child);

    alter table identityiq.spt_bundle_children 
       add constraint FKsislghstl6iawguwrnvx76rpk 
       foreign key (bundle) 
       references identityiq.spt_bundle;

    create index identityiq.FKsislghstl6iawguwrnvx76rpk on identityiq.spt_bundle_children (bundle);

    alter table identityiq.spt_bundle_permits 
       add constraint FKi5wtu493fivl2kxblg9ei0f51 
       foreign key (child) 
       references identityiq.spt_bundle;

    create index identityiq.FKi5wtu493fivl2kxblg9ei0f51 on identityiq.spt_bundle_permits (child);

    alter table identityiq.spt_bundle_permits 
       add constraint FKcclfiby5ny4jprvjkhd2wyy14 
       foreign key (bundle) 
       references identityiq.spt_bundle;

    create index identityiq.FKcclfiby5ny4jprvjkhd2wyy14 on identityiq.spt_bundle_permits (bundle);

    alter table identityiq.spt_bundle_profile_relation 
       add constraint FKmagmq7lgmic1artsln48lpcaw 
       foreign key (source_application) 
       references identityiq.spt_application;

    create index identityiq.FKmagmq7lgmic1artsln48lpcaw on identityiq.spt_bundle_profile_relation (source_application);

    alter table identityiq.spt_bundle_profile_relation_step 
       add constraint FK9ge6smvhp8n0fcl408e86tvia 
       foreign key (bundle_profile_relation_id) 
       references identityiq.spt_bundle_profile_relation;

    create index identityiq.FK9ge6smvhp8n0fcl408e86tvia on identityiq.spt_bundle_profile_relation_step (bundle_profile_relation_id);

    alter table identityiq.spt_bundle_requirements 
       add constraint FKf5ff4s6ac2kr4tdan3hoxpogn 
       foreign key (child) 
       references identityiq.spt_bundle;

    create index identityiq.FKf5ff4s6ac2kr4tdan3hoxpogn on identityiq.spt_bundle_requirements (child);

    alter table identityiq.spt_bundle_requirements 
       add constraint FKmwhuhsy3pxr2qfitnua7s12rf 
       foreign key (bundle) 
       references identityiq.spt_bundle;

    create index identityiq.FKmwhuhsy3pxr2qfitnua7s12rf on identityiq.spt_bundle_requirements (bundle);

    alter table identityiq.spt_capability 
       add constraint FKfc37j2eq2ue3bkwjujokswgwv 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKfc37j2eq2ue3bkwjujokswgwv on identityiq.spt_capability (owner);

    alter table identityiq.spt_capability 
       add constraint FKhw853kl2ued70sd1fofo2fo2f 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKhw853kl2ued70sd1fofo2fo2f on identityiq.spt_capability (assigned_scope);

    alter table identityiq.spt_capability_children 
       add constraint FKcustr3gvq1r7v2dsv0635gyal 
       foreign key (child_id) 
       references identityiq.spt_capability;

    create index identityiq.FKcustr3gvq1r7v2dsv0635gyal on identityiq.spt_capability_children (child_id);

    alter table identityiq.spt_capability_children 
       add constraint FKj5rdhd8hf7vrwg06pvvnewevy 
       foreign key (capability_id) 
       references identityiq.spt_capability;

    create index identityiq.FKj5rdhd8hf7vrwg06pvvnewevy on identityiq.spt_capability_children (capability_id);

    alter table identityiq.spt_capability_rights 
       add constraint FK2ly05h392vp6y87sw157to4if 
       foreign key (right_id) 
       references identityiq.spt_right;

    create index identityiq.FK2ly05h392vp6y87sw157to4if on identityiq.spt_capability_rights (right_id);

    alter table identityiq.spt_capability_rights 
       add constraint FK5hked97sfwstl920p4xpbj7d9 
       foreign key (capability_id) 
       references identityiq.spt_capability;

    create index identityiq.FK5hked97sfwstl920p4xpbj7d9 on identityiq.spt_capability_rights (capability_id);

    alter table identityiq.spt_category 
       add constraint FK6ly2lvlw1x3co3kllh32w9it 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK6ly2lvlw1x3co3kllh32w9it on identityiq.spt_category (owner);

    alter table identityiq.spt_category 
       add constraint FKh9mqo4to3wcj85auwfd1v0vuq 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKh9mqo4to3wcj85auwfd1v0vuq on identityiq.spt_category (assigned_scope);

    alter table identityiq.spt_cert_action_assoc 
       add constraint FK7lf26b9a79fiq8ra40n6c9jox 
       foreign key (child_id) 
       references identityiq.spt_certification_action;

    create index identityiq.FK7lf26b9a79fiq8ra40n6c9jox on identityiq.spt_cert_action_assoc (child_id);

    alter table identityiq.spt_cert_action_assoc 
       add constraint FKimetcxjfnxeb3uxisl0re6h7c 
       foreign key (parent_id) 
       references identityiq.spt_certification_action;

    create index identityiq.FKimetcxjfnxeb3uxisl0re6h7c on identityiq.spt_cert_action_assoc (parent_id);

    alter table identityiq.spt_certification 
       add constraint FKkam40wtg536xdls5oxfov4o42 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKkam40wtg536xdls5oxfov4o42 on identityiq.spt_certification (owner);

    alter table identityiq.spt_certification 
       add constraint FKnqhv931l5n1bu20lpcqwplr6x 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKnqhv931l5n1bu20lpcqwplr6x on identityiq.spt_certification (assigned_scope);

    alter table identityiq.spt_certification 
       add constraint FKawqph0q6n3ikiqhhytcm8dnbe 
       foreign key (parent) 
       references identityiq.spt_certification;

    create index identityiq.FKawqph0q6n3ikiqhhytcm8dnbe on identityiq.spt_certification (parent);

    alter table identityiq.spt_certification_def_tags 
       add constraint FKiqp17o6qbtywuq5xa0i7ftbdq 
       foreign key (elt) 
       references identityiq.spt_tag;

    create index identityiq.FKiqp17o6qbtywuq5xa0i7ftbdq on identityiq.spt_certification_def_tags (elt);

    alter table identityiq.spt_certification_def_tags 
       add constraint FK874kcq4p7hyw2ai9h2ctm1olh 
       foreign key (cert_def_id) 
       references identityiq.spt_certification_definition;

    create index identityiq.FK874kcq4p7hyw2ai9h2ctm1olh on identityiq.spt_certification_def_tags (cert_def_id);

    alter table identityiq.spt_certification_groups 
       add constraint FKex7xpxslou4ye7adrputklihy 
       foreign key (group_id) 
       references identityiq.spt_certification_group;

    create index identityiq.FKex7xpxslou4ye7adrputklihy on identityiq.spt_certification_groups (group_id);

    alter table identityiq.spt_certification_groups 
       add constraint FKil0cc1sbmueu7oiptxr3j62px 
       foreign key (certification_id) 
       references identityiq.spt_certification;

    create index identityiq.FKil0cc1sbmueu7oiptxr3j62px on identityiq.spt_certification_groups (certification_id);

    alter table identityiq.spt_certification_tags 
       add constraint FK841eyy68p6495npv6dwpi04j0 
       foreign key (elt) 
       references identityiq.spt_tag;

    create index identityiq.FK841eyy68p6495npv6dwpi04j0 on identityiq.spt_certification_tags (elt);

    alter table identityiq.spt_certification_tags 
       add constraint FKgpbsjaoc1wocq3euppijv9p15 
       foreign key (certification_id) 
       references identityiq.spt_certification;

    create index identityiq.FKgpbsjaoc1wocq3euppijv9p15 on identityiq.spt_certification_tags (certification_id);

    alter table identityiq.spt_certification_action 
       add constraint FKi48dvgroqefpxtfa7pweh6o8b 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKi48dvgroqefpxtfa7pweh6o8b on identityiq.spt_certification_action (owner);

    alter table identityiq.spt_certification_action 
       add constraint FK6vi46tjqxbjj146o4o2g4nyfs 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK6vi46tjqxbjj146o4o2g4nyfs on identityiq.spt_certification_action (assigned_scope);

    alter table identityiq.spt_certification_action 
       add constraint FKqfesh5gjixog7vmn3smfijoij 
       foreign key (source_action) 
       references identityiq.spt_certification_action;

    create index identityiq.FKqfesh5gjixog7vmn3smfijoij on identityiq.spt_certification_action (source_action);

    alter table identityiq.spt_certification_archive 
       add constraint FK1hkx6vis9eb73wy7c4pc1b8vf 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK1hkx6vis9eb73wy7c4pc1b8vf on identityiq.spt_certification_archive (owner);

    alter table identityiq.spt_certification_archive 
       add constraint FK7mfm8h2b8nn9atr7qh5qly4l5 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK7mfm8h2b8nn9atr7qh5qly4l5 on identityiq.spt_certification_archive (assigned_scope);

    alter table identityiq.spt_certification_challenge 
       add constraint FKf7hyeykya823607fv2qvgdloe 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKf7hyeykya823607fv2qvgdloe on identityiq.spt_certification_challenge (owner);

    alter table identityiq.spt_certification_challenge 
       add constraint FK22gq5pf504r23jw4knwce7xs5 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK22gq5pf504r23jw4knwce7xs5 on identityiq.spt_certification_challenge (assigned_scope);

    alter table identityiq.spt_certification_definition 
       add constraint FKcr18syune0mkqk7ixr4jth5le 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKcr18syune0mkqk7ixr4jth5le on identityiq.spt_certification_definition (owner);

    alter table identityiq.spt_certification_definition 
       add constraint FKgd080tua8dkp274bq1wapbb1a 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKgd080tua8dkp274bq1wapbb1a on identityiq.spt_certification_definition (assigned_scope);

    alter table identityiq.spt_certification_delegation 
       add constraint FK23qqsi30cp25uv1am5yurcq0j 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK23qqsi30cp25uv1am5yurcq0j on identityiq.spt_certification_delegation (owner);

    alter table identityiq.spt_certification_delegation 
       add constraint FKgxejqcvofo95foucj5vg4u3qs 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKgxejqcvofo95foucj5vg4u3qs on identityiq.spt_certification_delegation (assigned_scope);

    alter table identityiq.spt_certification_entity 
       add constraint FKip367cn9lac3qe96fw0ccljd1 
       foreign key (certification_id) 
       references identityiq.spt_certification;

    create index identityiq.FKip367cn9lac3qe96fw0ccljd1 on identityiq.spt_certification_entity (certification_id);

    alter table identityiq.spt_certification_entity 
       add constraint FK_8ldyhh9o0vcq3n294rbfjs415 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK_8ldyhh9o0vcq3n294rbfjs415 on identityiq.spt_certification_entity (owner);

    alter table identityiq.spt_certification_entity 
       add constraint FK_94kwlqdf1rlbuj6l25e71dg6c 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK_94kwlqdf1rlbuj6l25e71dg6c on identityiq.spt_certification_entity (assigned_scope);

    alter table identityiq.spt_certification_entity 
       add constraint FK_4kgyc7xxjq27248f3cpe2hhu 
       foreign key (action) 
       references identityiq.spt_certification_action;

    create index identityiq.FK_4kgyc7xxjq27248f3cpe2hhu on identityiq.spt_certification_entity (action);

    alter table identityiq.spt_certification_entity 
       add constraint FK_hyixy5s22roljj5pk6ir6xd2p 
       foreign key (delegation) 
       references identityiq.spt_certification_delegation;

    create index identityiq.FK_hyixy5s22roljj5pk6ir6xd2p on identityiq.spt_certification_entity (delegation);

    alter table identityiq.spt_certification_group 
       add constraint FKlhja2iwhg5a62sq6f1buj2axo 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKlhja2iwhg5a62sq6f1buj2axo on identityiq.spt_certification_group (owner);

    alter table identityiq.spt_certification_group 
       add constraint FKqkcuv3m20nm9bgj5lp1f0pvae 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKqkcuv3m20nm9bgj5lp1f0pvae on identityiq.spt_certification_group (assigned_scope);

    alter table identityiq.spt_certification_group 
       add constraint FKkekr0ucddvo7a8l6gcrccuudg 
       foreign key (certification_definition) 
       references identityiq.spt_certification_definition;

    create index identityiq.FKkekr0ucddvo7a8l6gcrccuudg on identityiq.spt_certification_group (certification_definition);

    alter table identityiq.spt_certification_item 
       add constraint FKlge6i5dbsbcsnxg6elephhq18 
       foreign key (certification_entity_id) 
       references identityiq.spt_certification_entity;

    create index identityiq.FKlge6i5dbsbcsnxg6elephhq18 on identityiq.spt_certification_item (certification_entity_id);

    alter table identityiq.spt_certification_item 
       add constraint FKnwb5vj6hwftfgtl9f283rvsfg 
       foreign key (exception_entitlements) 
       references identityiq.spt_entitlement_snapshot;

    create index identityiq.FKnwb5vj6hwftfgtl9f283rvsfg on identityiq.spt_certification_item (exception_entitlements);

    alter table identityiq.spt_certification_item 
       add constraint FKns942qq8bd2upr6b66wbaiekj 
       foreign key (challenge) 
       references identityiq.spt_certification_challenge;

    create index identityiq.FKns942qq8bd2upr6b66wbaiekj on identityiq.spt_certification_item (challenge);

    alter table identityiq.spt_certification_item 
       add constraint FK_2bwhd2rbxp1nvs39jxf4dothm 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK_2bwhd2rbxp1nvs39jxf4dothm on identityiq.spt_certification_item (owner);

    alter table identityiq.spt_certification_item 
       add constraint FK_183ktprgvdwfefivf1699hd02 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK_183ktprgvdwfefivf1699hd02 on identityiq.spt_certification_item (assigned_scope);

    alter table identityiq.spt_certification_item 
       add constraint FK_sqwuid379j4nfp6ykmbacjrk 
       foreign key (action) 
       references identityiq.spt_certification_action;

    create index identityiq.FK_sqwuid379j4nfp6ykmbacjrk on identityiq.spt_certification_item (action);

    alter table identityiq.spt_certification_item 
       add constraint FK_1w71laay1l62qeujievv5l3gg 
       foreign key (delegation) 
       references identityiq.spt_certification_delegation;

    create index identityiq.FK_1w71laay1l62qeujievv5l3gg on identityiq.spt_certification_item (delegation);

    alter table identityiq.spt_certifiers 
       add constraint FKq2kybcv1awb6cte2q45gkupei 
       foreign key (certification_id) 
       references identityiq.spt_certification;

    create index identityiq.FKq2kybcv1awb6cte2q45gkupei on identityiq.spt_certifiers (certification_id);

    alter table identityiq.spt_cert_item_applications 
       add constraint FKmgki0koeep17cgfpir44de6mj 
       foreign key (certification_item_id) 
       references identityiq.spt_certification_item;

    create index identityiq.FKmgki0koeep17cgfpir44de6mj on identityiq.spt_cert_item_applications (certification_item_id);

    alter table identityiq.spt_cert_item_classifications 
       add constraint FK9dehgtst8bbi31palx2ygp8hi 
       foreign key (certification_item) 
       references identityiq.spt_certification_item;

    create index identityiq.FK9dehgtst8bbi31palx2ygp8hi on identityiq.spt_cert_item_classifications (certification_item);

    alter table identityiq.spt_child_certification_ids 
       add constraint FK9syrav59593wgi39hrnt8kgk5 
       foreign key (certification_archive_id) 
       references identityiq.spt_certification_archive;

    create index identityiq.FK9syrav59593wgi39hrnt8kgk5 on identityiq.spt_child_certification_ids (certification_archive_id);

    alter table identityiq.spt_cloud_access3way 
       add constraint FK25ss4xxt4e2nvwcd8ne1iw3b4 
       foreign key (cloud_access_group) 
       references identityiq.spt_cloud_access_group;

    create index identityiq.FK25ss4xxt4e2nvwcd8ne1iw3b4 on identityiq.spt_cloud_access3way (cloud_access_group);

    alter table identityiq.spt_cloud_access3way 
       add constraint FK6o7a9k31y9pc0xy7bd24uoqu5 
       foreign key (cloud_access_role) 
       references identityiq.spt_cloud_access_role;

    create index identityiq.FK6o7a9k31y9pc0xy7bd24uoqu5 on identityiq.spt_cloud_access3way (cloud_access_role);

    alter table identityiq.spt_cloud_access3way 
       add constraint FKe65krw4kpvcduwmsp1mggynbg 
       foreign key (cloud_access_scope) 
       references identityiq.spt_cloud_access_scope;

    create index identityiq.FKe65krw4kpvcduwmsp1mggynbg on identityiq.spt_cloud_access3way (cloud_access_scope);

    alter table identityiq.spt_configuration 
       add constraint FKhjkwvbp3m63yllk6lbo4bqro7 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKhjkwvbp3m63yllk6lbo4bqro7 on identityiq.spt_configuration (owner);

    alter table identityiq.spt_configuration 
       add constraint FKp90cf11ijtygd9hxlgyo0psaa 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKp90cf11ijtygd9hxlgyo0psaa on identityiq.spt_configuration (assigned_scope);

    alter table identityiq.spt_correlation_config 
       add constraint FK8e7jfdj8slsjmmtl9saxefuep 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK8e7jfdj8slsjmmtl9saxefuep on identityiq.spt_correlation_config (owner);

    alter table identityiq.spt_correlation_config 
       add constraint FKrguogs2r8ljaxdto8u4h3e9tk 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKrguogs2r8ljaxdto8u4h3e9tk on identityiq.spt_correlation_config (assigned_scope);

    alter table identityiq.spt_custom 
       add constraint FKn2tjdgfk4rvy3vosf1v3kac2t 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKn2tjdgfk4rvy3vosf1v3kac2t on identityiq.spt_custom (owner);

    alter table identityiq.spt_custom 
       add constraint FKlkx2x8fdy1rwhtnntacydwmek 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKlkx2x8fdy1rwhtnntacydwmek on identityiq.spt_custom (assigned_scope);

    alter table identityiq.spt_deleted_object 
       add constraint FK18xcbn9moxo06bcfyg6l7ggcy 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK18xcbn9moxo06bcfyg6l7ggcy on identityiq.spt_deleted_object (owner);

    alter table identityiq.spt_deleted_object 
       add constraint FK187408eyxdoomujowu44neqde 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK187408eyxdoomujowu44neqde on identityiq.spt_deleted_object (assigned_scope);

    alter table identityiq.spt_deleted_object 
       add constraint FKe7dmgcmhkb13omi8dkh2ig89f 
       foreign key (application) 
       references identityiq.spt_application;

    create index identityiq.FKe7dmgcmhkb13omi8dkh2ig89f on identityiq.spt_deleted_object (application);

    alter table identityiq.spt_dictionary 
       add constraint FKauca1novn79fd19aug3bjsqya 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKauca1novn79fd19aug3bjsqya on identityiq.spt_dictionary (owner);

    alter table identityiq.spt_dictionary 
       add constraint FK7kdy9g1knlowpv3v4rtn7w1py 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK7kdy9g1knlowpv3v4rtn7w1py on identityiq.spt_dictionary (assigned_scope);

    alter table identityiq.spt_dictionary_term 
       add constraint FKcyplq38o2e3ajj515xs3vfrf3 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKcyplq38o2e3ajj515xs3vfrf3 on identityiq.spt_dictionary_term (owner);

    alter table identityiq.spt_dictionary_term 
       add constraint FK1lnmjjwf7i80cupehvm066hdf 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK1lnmjjwf7i80cupehvm066hdf on identityiq.spt_dictionary_term (assigned_scope);

    alter table identityiq.spt_dictionary_term 
       add constraint FKrtfr7u5wa0hngye2pixfgfjtq 
       foreign key (dictionary_id) 
       references identityiq.spt_dictionary;

    create index identityiq.FKrtfr7u5wa0hngye2pixfgfjtq on identityiq.spt_dictionary_term (dictionary_id);

    alter table identityiq.spt_dynamic_scope 
       add constraint FKibw7yhehyvo75yf2gqp4nj5iq 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKibw7yhehyvo75yf2gqp4nj5iq on identityiq.spt_dynamic_scope (owner);

    alter table identityiq.spt_dynamic_scope 
       add constraint FKpygxoi3poo3klc46c5o72qe48 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKpygxoi3poo3klc46c5o72qe48 on identityiq.spt_dynamic_scope (assigned_scope);

    alter table identityiq.spt_dynamic_scope 
       add constraint FK1v3xd4m55jijgosuof9e6glj8 
       foreign key (role_request_control) 
       references identityiq.spt_rule;

    create index identityiq.FK1v3xd4m55jijgosuof9e6glj8 on identityiq.spt_dynamic_scope (role_request_control);

    alter table identityiq.spt_dynamic_scope 
       add constraint FKcv5id4r7gnsso13xjubxaqnkp 
       foreign key (application_request_control) 
       references identityiq.spt_rule;

    create index identityiq.FKcv5id4r7gnsso13xjubxaqnkp on identityiq.spt_dynamic_scope (application_request_control);

    alter table identityiq.spt_dynamic_scope 
       add constraint FKktwyfv8gvs56q5ilfuguki5l5 
       foreign key (managed_attr_request_control) 
       references identityiq.spt_rule;

    create index identityiq.FKktwyfv8gvs56q5ilfuguki5l5 on identityiq.spt_dynamic_scope (managed_attr_request_control);

    alter table identityiq.spt_dynamic_scope 
       add constraint FKtktdhh12wn2ah31yrges9oiu1 
       foreign key (role_remove_control) 
       references identityiq.spt_rule;

    create index identityiq.FKtktdhh12wn2ah31yrges9oiu1 on identityiq.spt_dynamic_scope (role_remove_control);

    alter table identityiq.spt_dynamic_scope 
       add constraint FKexhlawv29rux6bct75f19h91v 
       foreign key (application_remove_control) 
       references identityiq.spt_rule;

    create index identityiq.FKexhlawv29rux6bct75f19h91v on identityiq.spt_dynamic_scope (application_remove_control);

    alter table identityiq.spt_dynamic_scope 
       add constraint FK5qib64c7xdiovhut2k81054iu 
       foreign key (managed_attr_remove_control) 
       references identityiq.spt_rule;

    create index identityiq.FK5qib64c7xdiovhut2k81054iu on identityiq.spt_dynamic_scope (managed_attr_remove_control);

    alter table identityiq.spt_dynamic_scope_exclusions 
       add constraint FKrmu2wy5qkgpggwyvtlssi5ehk 
       foreign key (identity_id) 
       references identityiq.spt_identity;

    create index identityiq.FKrmu2wy5qkgpggwyvtlssi5ehk on identityiq.spt_dynamic_scope_exclusions (identity_id);

    alter table identityiq.spt_dynamic_scope_exclusions 
       add constraint FK6y9ox5g2qxpgjp2jp69qqsj1g 
       foreign key (dynamic_scope_id) 
       references identityiq.spt_dynamic_scope;

    create index identityiq.FK6y9ox5g2qxpgjp2jp69qqsj1g on identityiq.spt_dynamic_scope_exclusions (dynamic_scope_id);

    alter table identityiq.spt_dynamic_scope_inclusions 
       add constraint FK3ggbccvk2ambqjdw8iynyt965 
       foreign key (identity_id) 
       references identityiq.spt_identity;

    create index identityiq.FK3ggbccvk2ambqjdw8iynyt965 on identityiq.spt_dynamic_scope_inclusions (identity_id);

    alter table identityiq.spt_dynamic_scope_inclusions 
       add constraint FKol4cq5u3jcqik19amte10slgr 
       foreign key (dynamic_scope_id) 
       references identityiq.spt_dynamic_scope;

    create index identityiq.FKol4cq5u3jcqik19amte10slgr on identityiq.spt_dynamic_scope_inclusions (dynamic_scope_id);

    alter table identityiq.spt_email_template 
       add constraint FKbgbd2hiyxohe6mp0wks9w7i6m 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKbgbd2hiyxohe6mp0wks9w7i6m on identityiq.spt_email_template (owner);

    alter table identityiq.spt_email_template 
       add constraint FKnn3hbn1pd7e492186rskdwd3c 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKnn3hbn1pd7e492186rskdwd3c on identityiq.spt_email_template (assigned_scope);

    alter table identityiq.spt_email_template_properties 
       add constraint emailtemplateproperties 
       foreign key (id) 
       references identityiq.spt_email_template;

    alter table identityiq.spt_entitlement_group 
       add constraint FKhejppx2y8jb7gn2f5kow3rd4s 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKhejppx2y8jb7gn2f5kow3rd4s on identityiq.spt_entitlement_group (owner);

    alter table identityiq.spt_entitlement_group 
       add constraint FKtckmuosehsos4esc6e7aw96x2 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKtckmuosehsos4esc6e7aw96x2 on identityiq.spt_entitlement_group (assigned_scope);

    alter table identityiq.spt_entitlement_group 
       add constraint FKkgvp9pnx75witsnhfhmi2j3e 
       foreign key (application) 
       references identityiq.spt_application;

    create index identityiq.FKkgvp9pnx75witsnhfhmi2j3e on identityiq.spt_entitlement_group (application);

    alter table identityiq.spt_entitlement_group 
       add constraint FK2r4pe9yr6ieul6o7j3gbh4ek4 
       foreign key (identity_id) 
       references identityiq.spt_identity;

    create index identityiq.FK2r4pe9yr6ieul6o7j3gbh4ek4 on identityiq.spt_entitlement_group (identity_id);

    alter table identityiq.spt_entitlement_snapshot 
       add constraint FKg28gich6xc717ufitfs9b7ho8 
       foreign key (certification_item_id) 
       references identityiq.spt_certification_item;

    create index identityiq.FKg28gich6xc717ufitfs9b7ho8 on identityiq.spt_entitlement_snapshot (certification_item_id);

    alter table identityiq.spt_file_bucket 
       add constraint FK4j1imfpmt238fhglhfh95rrs8 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK4j1imfpmt238fhglhfh95rrs8 on identityiq.spt_file_bucket (owner);

    alter table identityiq.spt_file_bucket 
       add constraint FKaw7g3a6la8gky8coehtta2u32 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKaw7g3a6la8gky8coehtta2u32 on identityiq.spt_file_bucket (assigned_scope);

    alter table identityiq.spt_file_bucket 
       add constraint FK59ymu1g5ld3l6j97mx7uq0jfb 
       foreign key (parent_id) 
       references identityiq.spt_persisted_file;

    create index identityiq.FK59ymu1g5ld3l6j97mx7uq0jfb on identityiq.spt_file_bucket (parent_id);

    alter table identityiq.spt_form 
       add constraint FKblc1wv6n85ie3ajioskbhtb87 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKblc1wv6n85ie3ajioskbhtb87 on identityiq.spt_form (owner);

    alter table identityiq.spt_form 
       add constraint FK7j84f82idyeb2pu1giatg6b00 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK7j84f82idyeb2pu1giatg6b00 on identityiq.spt_form (assigned_scope);

    alter table identityiq.spt_form 
       add constraint FKrwbs6jyeoe0f24q9u878kktna 
       foreign key (application) 
       references identityiq.spt_application;

    create index identityiq.FKrwbs6jyeoe0f24q9u878kktna on identityiq.spt_form (application);

    alter table identityiq.spt_generic_constraint 
       add constraint FK2vhfe3qafdd3ok28mm1h90om9 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK2vhfe3qafdd3ok28mm1h90om9 on identityiq.spt_generic_constraint (owner);

    alter table identityiq.spt_generic_constraint 
       add constraint FKi7nk6nu4vkvasene3f14mnykm 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKi7nk6nu4vkvasene3f14mnykm on identityiq.spt_generic_constraint (assigned_scope);

    alter table identityiq.spt_generic_constraint 
       add constraint FKkthxi9af57y8xjm6pps9h8lr4 
       foreign key (policy) 
       references identityiq.spt_policy;

    create index identityiq.FKkthxi9af57y8xjm6pps9h8lr4 on identityiq.spt_generic_constraint (policy);

    alter table identityiq.spt_generic_constraint 
       add constraint FKedawydx5t9h0xmnps51w6krpb 
       foreign key (violation_owner) 
       references identityiq.spt_identity;

    create index identityiq.FKedawydx5t9h0xmnps51w6krpb on identityiq.spt_generic_constraint (violation_owner);

    alter table identityiq.spt_generic_constraint 
       add constraint FK6oqb9qqui7wajajasxflcfcnb 
       foreign key (violation_owner_rule) 
       references identityiq.spt_rule;

    create index identityiq.FK6oqb9qqui7wajajasxflcfcnb on identityiq.spt_generic_constraint (violation_owner_rule);

    alter table identityiq.spt_group_definition 
       add constraint FKku7t8vcce9maxmpgh025h8rpm 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKku7t8vcce9maxmpgh025h8rpm on identityiq.spt_group_definition (owner);

    alter table identityiq.spt_group_definition 
       add constraint FKgpkyterj8orw9ue1ecnaxcxac 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKgpkyterj8orw9ue1ecnaxcxac on identityiq.spt_group_definition (assigned_scope);

    alter table identityiq.spt_group_definition 
       add constraint FKsswaiwl9wgq1x7x66w7dw73sr 
       foreign key (factory) 
       references identityiq.spt_group_factory;

    create index identityiq.FKsswaiwl9wgq1x7x66w7dw73sr on identityiq.spt_group_definition (factory);

    alter table identityiq.spt_group_definition 
       add constraint FKhxm0nnx7gf472ykocqgl9yxne 
       foreign key (group_index) 
       references identityiq.spt_group_index;

    create index identityiq.FKhxm0nnx7gf472ykocqgl9yxne on identityiq.spt_group_definition (group_index);

    alter table identityiq.spt_group_factory 
       add constraint FKh274opn41khwnbi0yj2n37ftm 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKh274opn41khwnbi0yj2n37ftm on identityiq.spt_group_factory (owner);

    alter table identityiq.spt_group_factory 
       add constraint FK4l56xl5r807s9o9clecfa83sp 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK4l56xl5r807s9o9clecfa83sp on identityiq.spt_group_factory (assigned_scope);

    alter table identityiq.spt_group_factory 
       add constraint FKhbdh4oyxsx9mqfsnvk57vqotk 
       foreign key (group_owner_rule) 
       references identityiq.spt_rule;

    create index identityiq.FKhbdh4oyxsx9mqfsnvk57vqotk on identityiq.spt_group_factory (group_owner_rule);

    alter table identityiq.spt_group_index 
       add constraint FKf94ksv2vpcmefy7dtedsr4d8i 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKf94ksv2vpcmefy7dtedsr4d8i on identityiq.spt_group_index (owner);

    alter table identityiq.spt_group_index 
       add constraint FKqvs2uruibvlbl9he3319jiy67 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKqvs2uruibvlbl9he3319jiy67 on identityiq.spt_group_index (assigned_scope);

    alter table identityiq.spt_group_index 
       add constraint FKk8c1wd9ht5mtgdkgr6w2pwx07 
       foreign key (definition) 
       references identityiq.spt_group_definition;

    create index identityiq.FKk8c1wd9ht5mtgdkgr6w2pwx07 on identityiq.spt_group_index (definition);

    alter table identityiq.spt_group_permissions 
       add constraint FKcratih77tg9y9028xrpsiy0x5 
       foreign key (entitlement_group_id) 
       references identityiq.spt_entitlement_group;

    create index identityiq.FKcratih77tg9y9028xrpsiy0x5 on identityiq.spt_group_permissions (entitlement_group_id);

    alter table identityiq.spt_identity 
       add constraint FKdco8at7cn3mnhjf6xaahalooj 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKdco8at7cn3mnhjf6xaahalooj on identityiq.spt_identity (owner);

    alter table identityiq.spt_identity 
       add constraint FKikbm1x7vdijclac4vu15u5ovv 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKikbm1x7vdijclac4vu15u5ovv on identityiq.spt_identity (assigned_scope);

    alter table identityiq.spt_identity 
       add constraint FKoq0aevty64ohgu1m3y5n2odfb 
       foreign key (extended_identity1) 
       references identityiq.spt_identity;

    create index identityiq.FKoq0aevty64ohgu1m3y5n2odfb on identityiq.spt_identity (extended_identity1);

    alter table identityiq.spt_identity 
       add constraint FKkpuohy1m4u7hhicokkoixnh3v 
       foreign key (extended_identity2) 
       references identityiq.spt_identity;

    create index identityiq.FKkpuohy1m4u7hhicokkoixnh3v on identityiq.spt_identity (extended_identity2);

    alter table identityiq.spt_identity 
       add constraint FK6yjqfgtb1teavu30xemwke50h 
       foreign key (extended_identity3) 
       references identityiq.spt_identity;

    create index identityiq.FK6yjqfgtb1teavu30xemwke50h on identityiq.spt_identity (extended_identity3);

    alter table identityiq.spt_identity 
       add constraint FK996is5ceoc7ssc7n0cfgavp1n 
       foreign key (extended_identity4) 
       references identityiq.spt_identity;

    create index identityiq.FK996is5ceoc7ssc7n0cfgavp1n on identityiq.spt_identity (extended_identity4);

    alter table identityiq.spt_identity 
       add constraint FKl62tfosnxhkn8al4i5m098g6l 
       foreign key (extended_identity5) 
       references identityiq.spt_identity;

    create index identityiq.FKl62tfosnxhkn8al4i5m098g6l on identityiq.spt_identity (extended_identity5);

    alter table identityiq.spt_identity 
       add constraint FK7l1j3c1e9yne2d7ercls5w169 
       foreign key (manager) 
       references identityiq.spt_identity;

    create index identityiq.FK7l1j3c1e9yne2d7ercls5w169 on identityiq.spt_identity (manager);

    alter table identityiq.spt_identity 
       add constraint FK6erec9yefdkhc6gj4g6wpufv9 
       foreign key (administrator) 
       references identityiq.spt_identity;

    create index identityiq.FK6erec9yefdkhc6gj4g6wpufv9 on identityiq.spt_identity (administrator);

    alter table identityiq.spt_identity 
       add constraint FK8ro3qhcvypwaofa3yrnal3fsi 
       foreign key (scorecard) 
       references identityiq.spt_scorecard;

    create index identityiq.FK8ro3qhcvypwaofa3yrnal3fsi on identityiq.spt_identity (scorecard);

    alter table identityiq.spt_identity 
       add constraint FKaw4ye4m198dibbj2atxjg85m7 
       foreign key (uipreferences) 
       references identityiq.spt_uipreferences;

    create index identityiq.FKaw4ye4m198dibbj2atxjg85m7 on identityiq.spt_identity (uipreferences);

    alter table identityiq.spt_identity_archive 
       add constraint FKp8j75f2pk9xvqyimweu32w6f8 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKp8j75f2pk9xvqyimweu32w6f8 on identityiq.spt_identity_archive (owner);

    alter table identityiq.spt_identity_archive 
       add constraint FKmridtwmjtph1265lllya9w2mn 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKmridtwmjtph1265lllya9w2mn on identityiq.spt_identity_archive (assigned_scope);

    alter table identityiq.spt_identity_assigned_roles 
       add constraint FKheohgr0xuxklx9sfhjde58ig9 
       foreign key (bundle) 
       references identityiq.spt_bundle;

    create index identityiq.FKheohgr0xuxklx9sfhjde58ig9 on identityiq.spt_identity_assigned_roles (bundle);

    alter table identityiq.spt_identity_assigned_roles 
       add constraint FKf367abg77497pwgtr61co5mc 
       foreign key (identity_id) 
       references identityiq.spt_identity;

    create index identityiq.FKf367abg77497pwgtr61co5mc on identityiq.spt_identity_assigned_roles (identity_id);

    alter table identityiq.spt_identity_bundles 
       add constraint FKmr5pwrd4ysq4uiy970s0gpija 
       foreign key (bundle) 
       references identityiq.spt_bundle;

    create index identityiq.FKmr5pwrd4ysq4uiy970s0gpija on identityiq.spt_identity_bundles (bundle);

    alter table identityiq.spt_identity_bundles 
       add constraint FKcuq8yi3rh1dxbbr7nt33io0h4 
       foreign key (identity_id) 
       references identityiq.spt_identity;

    create index identityiq.FKcuq8yi3rh1dxbbr7nt33io0h4 on identityiq.spt_identity_bundles (identity_id);

    alter table identityiq.spt_identity_capabilities 
       add constraint FK8rvftn57xdt7vtg3oe2i3bn7i 
       foreign key (capability_id) 
       references identityiq.spt_capability;

    create index identityiq.FK8rvftn57xdt7vtg3oe2i3bn7i on identityiq.spt_identity_capabilities (capability_id);

    alter table identityiq.spt_identity_capabilities 
       add constraint FKe9bo37xbckkaq2k85omvmo9ld 
       foreign key (identity_id) 
       references identityiq.spt_identity;

    create index identityiq.FKe9bo37xbckkaq2k85omvmo9ld on identityiq.spt_identity_capabilities (identity_id);

    alter table identityiq.spt_identity_controlled_scopes 
       add constraint FKoahj6hw5kk9163bfes49lvasv 
       foreign key (scope_id) 
       references identityiq.spt_scope;

    create index identityiq.FKoahj6hw5kk9163bfes49lvasv on identityiq.spt_identity_controlled_scopes (scope_id);

    alter table identityiq.spt_identity_controlled_scopes 
       add constraint FKqjnmhlsld4pvlix9kbrvlmsb1 
       foreign key (identity_id) 
       references identityiq.spt_identity;

    create index identityiq.FKqjnmhlsld4pvlix9kbrvlmsb1 on identityiq.spt_identity_controlled_scopes (identity_id);

    alter table identityiq.spt_identity_entitlement 
       add constraint FKlnoli5e2k3cofry0kh5lqwvk2 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKlnoli5e2k3cofry0kh5lqwvk2 on identityiq.spt_identity_entitlement (owner);

    alter table identityiq.spt_identity_entitlement 
       add constraint FKqy3hyiptyuoo0ik8nfewymdio 
       foreign key (application) 
       references identityiq.spt_application;

    create index identityiq.FKqy3hyiptyuoo0ik8nfewymdio on identityiq.spt_identity_entitlement (application);

    alter table identityiq.spt_identity_entitlement 
       add constraint FKjief1jwgixlilqiqsvkpx0k9e 
       foreign key (identity_id) 
       references identityiq.spt_identity;

    create index identityiq.FKjief1jwgixlilqiqsvkpx0k9e on identityiq.spt_identity_entitlement (identity_id);

    alter table identityiq.spt_identity_entitlement 
       add constraint FK9p3id5o2as2stlq47md58fm3b 
       foreign key (request_item) 
       references identityiq.spt_identity_request_item;

    create index identityiq.FK9p3id5o2as2stlq47md58fm3b on identityiq.spt_identity_entitlement (request_item);

    alter table identityiq.spt_identity_entitlement 
       add constraint FKcn0l4kl1lpjkg7usf4okua4d8 
       foreign key (pending_request_item) 
       references identityiq.spt_identity_request_item;

    create index identityiq.FKcn0l4kl1lpjkg7usf4okua4d8 on identityiq.spt_identity_entitlement (pending_request_item);

    alter table identityiq.spt_identity_entitlement 
       add constraint FKbpm8wgk9stf16g8w9ujx10qw3 
       foreign key (certification_item) 
       references identityiq.spt_certification_item;

    create index identityiq.FKbpm8wgk9stf16g8w9ujx10qw3 on identityiq.spt_identity_entitlement (certification_item);

    alter table identityiq.spt_identity_entitlement 
       add constraint FK6cwcsuwgv6ydwqpnm6jto062q 
       foreign key (pending_certification_item) 
       references identityiq.spt_certification_item;

    create index identityiq.FK6cwcsuwgv6ydwqpnm6jto062q on identityiq.spt_identity_entitlement (pending_certification_item);

    alter table identityiq.spt_identity_history_item 
       add constraint FKji55d6komkmaodbat8ykt27ut 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKji55d6komkmaodbat8ykt27ut on identityiq.spt_identity_history_item (owner);

    alter table identityiq.spt_identity_history_item 
       add constraint FKa9cu5shr2oefnkrrew96b98nc 
       foreign key (identity_id) 
       references identityiq.spt_identity;

    create index identityiq.FKa9cu5shr2oefnkrrew96b98nc on identityiq.spt_identity_history_item (identity_id);

    alter table identityiq.spt_identity_request 
       add constraint FKrnecq87gn8rjrj2vbn9koxwc1 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKrnecq87gn8rjrj2vbn9koxwc1 on identityiq.spt_identity_request (owner);

    alter table identityiq.spt_identity_request 
       add constraint FKpstoy7u3dse9pl2h5ryub6h0w 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKpstoy7u3dse9pl2h5ryub6h0w on identityiq.spt_identity_request (assigned_scope);

    alter table identityiq.spt_identity_request_item 
       add constraint FKdrgm0omo927u9hkgtx0m4rbmb 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKdrgm0omo927u9hkgtx0m4rbmb on identityiq.spt_identity_request_item (owner);

    alter table identityiq.spt_identity_request_item 
       add constraint FKfax65ddwd2dwvkt9rsdqthshd 
       foreign key (identity_request_id) 
       references identityiq.spt_identity_request;

    create index identityiq.FKfax65ddwd2dwvkt9rsdqthshd on identityiq.spt_identity_request_item (identity_request_id);

    alter table identityiq.spt_identity_role_metadata 
       add constraint FKlbwupgie8o3gpjt857djjipg9 
       foreign key (role_metadata_id) 
       references identityiq.spt_role_metadata;

    create index identityiq.FKlbwupgie8o3gpjt857djjipg9 on identityiq.spt_identity_role_metadata (role_metadata_id);

    alter table identityiq.spt_identity_role_metadata 
       add constraint FKptvypo1q0ekqnlnt7tkl1u2na 
       foreign key (identity_id) 
       references identityiq.spt_identity;

    create index identityiq.FKptvypo1q0ekqnlnt7tkl1u2na on identityiq.spt_identity_role_metadata (identity_id);

    alter table identityiq.spt_identity_snapshot 
       add constraint FKh03yxqsq7ebvwlwcthihtym07 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKh03yxqsq7ebvwlwcthihtym07 on identityiq.spt_identity_snapshot (owner);

    alter table identityiq.spt_identity_snapshot 
       add constraint FKj24y3i8my2r0c3il58dlww3fa 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKj24y3i8my2r0c3il58dlww3fa on identityiq.spt_identity_snapshot (assigned_scope);

    alter table identityiq.spt_identity_trigger 
       add constraint FKaoupv62m0yus73314iwn0fclq 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKaoupv62m0yus73314iwn0fclq on identityiq.spt_identity_trigger (owner);

    alter table identityiq.spt_identity_trigger 
       add constraint FK6est6a8xpuhjgqv7b0d8yvmal 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK6est6a8xpuhjgqv7b0d8yvmal on identityiq.spt_identity_trigger (assigned_scope);

    alter table identityiq.spt_identity_trigger 
       add constraint FK4yqufhetuoj6wig3t5n5rw7xh 
       foreign key (rule_id) 
       references identityiq.spt_rule;

    create index identityiq.FK4yqufhetuoj6wig3t5n5rw7xh on identityiq.spt_identity_trigger (rule_id);

    alter table identityiq.spt_identity_workgroups 
       add constraint FKew5309x0hinshtjed2o9p4lu8 
       foreign key (workgroup) 
       references identityiq.spt_identity;

    create index identityiq.FKew5309x0hinshtjed2o9p4lu8 on identityiq.spt_identity_workgroups (workgroup);

    alter table identityiq.spt_identity_workgroups 
       add constraint FKdubcl4txlwq72y89p09vsokp3 
       foreign key (identity_id) 
       references identityiq.spt_identity;

    create index identityiq.FKdubcl4txlwq72y89p09vsokp3 on identityiq.spt_identity_workgroups (identity_id);

    alter table identityiq.spt_integration_config 
       add constraint FK9i40hwin9s24k40gf9jbcjmyg 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK9i40hwin9s24k40gf9jbcjmyg on identityiq.spt_integration_config (owner);

    alter table identityiq.spt_integration_config 
       add constraint FKkra0w53mfbawmb7tun0thw07j 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKkra0w53mfbawmb7tun0thw07j on identityiq.spt_integration_config (assigned_scope);

    alter table identityiq.spt_integration_config 
       add constraint FK4m8ag5j3ca0w07n396xv4ovlx 
       foreign key (plan_initializer) 
       references identityiq.spt_rule;

    create index identityiq.FK4m8ag5j3ca0w07n396xv4ovlx on identityiq.spt_integration_config (plan_initializer);

    alter table identityiq.spt_integration_config 
       add constraint FKnn9f0lgf5ewip65a8t2mhi97u 
       foreign key (application_id) 
       references identityiq.spt_application;

    create index identityiq.FKnn9f0lgf5ewip65a8t2mhi97u on identityiq.spt_integration_config (application_id);

    alter table identityiq.spt_integration_config 
       add constraint FK7dcjq7gk21x6gl2w55r9rgnnq 
       foreign key (container_id) 
       references identityiq.spt_bundle;

    create index identityiq.FK7dcjq7gk21x6gl2w55r9rgnnq on identityiq.spt_integration_config (container_id);

    alter table identityiq.spt_jasper_files 
       add constraint FKarvo68602qubbljqm974ejrao 
       foreign key (elt) 
       references identityiq.spt_persisted_file;

    create index identityiq.FKarvo68602qubbljqm974ejrao on identityiq.spt_jasper_files (elt);

    alter table identityiq.spt_jasper_files 
       add constraint FK38q00anepn1enkf14vh5kt0p0 
       foreign key (result) 
       references identityiq.spt_jasper_result;

    create index identityiq.FK38q00anepn1enkf14vh5kt0p0 on identityiq.spt_jasper_files (result);

    alter table identityiq.spt_jasper_page_bucket 
       add constraint FK7ajqlhkio1lj6deitro8rufr4 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK7ajqlhkio1lj6deitro8rufr4 on identityiq.spt_jasper_page_bucket (owner);

    alter table identityiq.spt_jasper_page_bucket 
       add constraint FKebcpjeggovthx5rfslffvm06l 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKebcpjeggovthx5rfslffvm06l on identityiq.spt_jasper_page_bucket (assigned_scope);

    alter table identityiq.spt_jasper_result 
       add constraint FKaov2d8748uea72k8riblr9iw 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKaov2d8748uea72k8riblr9iw on identityiq.spt_jasper_result (owner);

    alter table identityiq.spt_jasper_result 
       add constraint FK48lfhuwg00rdb7lu24q8iqemj 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK48lfhuwg00rdb7lu24q8iqemj on identityiq.spt_jasper_result (assigned_scope);

    alter table identityiq.spt_jasper_template 
       add constraint FK9gqhh1f6h8uvb0ijwd2x8d3xd 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK9gqhh1f6h8uvb0ijwd2x8d3xd on identityiq.spt_jasper_template (owner);

    alter table identityiq.spt_jasper_template 
       add constraint FKd7fy4u4sv1o5q0oen7ip2trng 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKd7fy4u4sv1o5q0oen7ip2trng on identityiq.spt_jasper_template (assigned_scope);

    alter table identityiq.spt_link 
       add constraint FKlt4unsy5cp7psyl716sjq527e 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKlt4unsy5cp7psyl716sjq527e on identityiq.spt_link (owner);

    alter table identityiq.spt_link 
       add constraint FKg0l571s3kkovl1l5q24wsn5h2 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKg0l571s3kkovl1l5q24wsn5h2 on identityiq.spt_link (assigned_scope);

    alter table identityiq.spt_link 
       add constraint FK7do4oyl8j399aynq34dosvk6o 
       foreign key (identity_id) 
       references identityiq.spt_identity;

    create index identityiq.FK7do4oyl8j399aynq34dosvk6o on identityiq.spt_link (identity_id);

    alter table identityiq.spt_link 
       add constraint FKsc0du71d7t0p5jx4sqbwlrtc7 
       foreign key (application) 
       references identityiq.spt_application;

    create index identityiq.FKsc0du71d7t0p5jx4sqbwlrtc7 on identityiq.spt_link (application);

    alter table identityiq.spt_localized_attribute 
       add constraint FK4ahm8gyl5gwhj8d4qgbwyynv 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK4ahm8gyl5gwhj8d4qgbwyynv on identityiq.spt_localized_attribute (owner);

    alter table identityiq.spt_managed_attribute 
       add constraint FK3gb72xtjki5mp7uosqt8y4pvn 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK3gb72xtjki5mp7uosqt8y4pvn on identityiq.spt_managed_attribute (owner);

    alter table identityiq.spt_managed_attribute 
       add constraint FKp22ur089e238refu7d4ey3vad 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKp22ur089e238refu7d4ey3vad on identityiq.spt_managed_attribute (assigned_scope);

    alter table identityiq.spt_managed_attribute 
       add constraint FKh34qiq4aglfffr9xwpik781vj 
       foreign key (application) 
       references identityiq.spt_application;

    create index identityiq.FKh34qiq4aglfffr9xwpik781vj on identityiq.spt_managed_attribute (application);

    alter table identityiq.spt_managed_attr_inheritance 
       add constraint FK4ioitymnwqibnmecupdfuo3ri 
       foreign key (inherits_from) 
       references identityiq.spt_managed_attribute;

    create index identityiq.FK4ioitymnwqibnmecupdfuo3ri on identityiq.spt_managed_attr_inheritance (inherits_from);

    alter table identityiq.spt_managed_attr_inheritance 
       add constraint FK5w1va2uar8ndocw86uxw22fyx 
       foreign key (managedattribute) 
       references identityiq.spt_managed_attribute;

    create index identityiq.FK5w1va2uar8ndocw86uxw22fyx on identityiq.spt_managed_attr_inheritance (managedattribute);

    alter table identityiq.spt_managed_attr_perms 
       add constraint FKgb5h5u8b3v7q8thhsyw3a3x2d 
       foreign key (managedattribute) 
       references identityiq.spt_managed_attribute;

    create index identityiq.FKgb5h5u8b3v7q8thhsyw3a3x2d on identityiq.spt_managed_attr_perms (managedattribute);

    alter table identityiq.spt_managed_attr_target_perms 
       add constraint FKgxeh9kjs3fstpnq4tp0cch0h7 
       foreign key (managedattribute) 
       references identityiq.spt_managed_attribute;

    create index identityiq.FKgxeh9kjs3fstpnq4tp0cch0h7 on identityiq.spt_managed_attr_target_perms (managedattribute);

    alter table identityiq.spt_message_template 
       add constraint FKbhf643rsydyey69y4clalwes3 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKbhf643rsydyey69y4clalwes3 on identityiq.spt_message_template (owner);

    alter table identityiq.spt_message_template 
       add constraint FK93cucj6fysk1u4s1mggidhsjw 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK93cucj6fysk1u4s1mggidhsjw on identityiq.spt_message_template (assigned_scope);

    alter table identityiq.spt_mining_config 
       add constraint FKe2p3b82e1gpt5n75cfkj19573 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKe2p3b82e1gpt5n75cfkj19573 on identityiq.spt_mining_config (owner);

    alter table identityiq.spt_mining_config 
       add constraint FKo5ji502vpitlcnl4ie54trv3a 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKo5ji502vpitlcnl4ie54trv3a on identityiq.spt_mining_config (assigned_scope);

    alter table identityiq.spt_mitigation_expiration 
       add constraint FKpym4olxxt5hvtw2h6h5qehsg5 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKpym4olxxt5hvtw2h6h5qehsg5 on identityiq.spt_mitigation_expiration (owner);

    alter table identityiq.spt_mitigation_expiration 
       add constraint FKnq1a0dvm762fk9tcucs5ro4h3 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKnq1a0dvm762fk9tcucs5ro4h3 on identityiq.spt_mitigation_expiration (assigned_scope);

    alter table identityiq.spt_mitigation_expiration 
       add constraint FKrp62md93f75jd1i1hof0pdr01 
       foreign key (mitigator) 
       references identityiq.spt_identity;

    create index identityiq.FKrp62md93f75jd1i1hof0pdr01 on identityiq.spt_mitigation_expiration (mitigator);

    alter table identityiq.spt_mitigation_expiration 
       add constraint FKdk2mv4vumkj87erjys2ecjjqy 
       foreign key (identity_id) 
       references identityiq.spt_identity;

    create index identityiq.FKdk2mv4vumkj87erjys2ecjjqy on identityiq.spt_mitigation_expiration (identity_id);

    alter table identityiq.spt_monitoring_statistic 
       add constraint FK1oylxmpnab6ukcexs91d4d3ps 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK1oylxmpnab6ukcexs91d4d3ps on identityiq.spt_monitoring_statistic (owner);

    alter table identityiq.spt_monitoring_statistic 
       add constraint FK66fxpvt139gb5aghd369t0q1s 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK66fxpvt139gb5aghd369t0q1s on identityiq.spt_monitoring_statistic (assigned_scope);

    alter table identityiq.spt_monitoring_statistic_tags 
       add constraint FKa6efhhukixvrd4fucp8n3hrlm 
       foreign key (elt) 
       references identityiq.spt_tag;

    create index identityiq.FKa6efhhukixvrd4fucp8n3hrlm on identityiq.spt_monitoring_statistic_tags (elt);

    alter table identityiq.spt_monitoring_statistic_tags 
       add constraint FKk900lsdj83sd0cp9o59evn9nj 
       foreign key (statistic_id) 
       references identityiq.spt_monitoring_statistic;

    create index identityiq.FKk900lsdj83sd0cp9o59evn9nj on identityiq.spt_monitoring_statistic_tags (statistic_id);

    alter table identityiq.spt_object_classification 
       add constraint FK4hfvqf5hc3a6rl944f4h171tn 
       foreign key (classification_id) 
       references identityiq.spt_classification;

    create index identityiq.FK4hfvqf5hc3a6rl944f4h171tn on identityiq.spt_object_classification (classification_id);

    alter table identityiq.spt_object_config 
       add constraint FKtcjesncjqdcd4inr41kpgpwaj 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKtcjesncjqdcd4inr41kpgpwaj on identityiq.spt_object_config (owner);

    alter table identityiq.spt_object_config 
       add constraint FK1w6x1owivjjlgw0ojfk6aatm5 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK1w6x1owivjjlgw0ojfk6aatm5 on identityiq.spt_object_config (assigned_scope);

    alter table identityiq.spt_partition_result 
       add constraint FK9fa80qf6up4eunpumew96wmxr 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK9fa80qf6up4eunpumew96wmxr on identityiq.spt_partition_result (owner);

    alter table identityiq.spt_partition_result 
       add constraint FKguaao9nkvy8wtshwdjls9qe17 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKguaao9nkvy8wtshwdjls9qe17 on identityiq.spt_partition_result (assigned_scope);

    alter table identityiq.spt_partition_result 
       add constraint FK9svig87lf8npttavcvalbuipb 
       foreign key (task_result) 
       references identityiq.spt_task_result;

    create index identityiq.FK9svig87lf8npttavcvalbuipb on identityiq.spt_partition_result (task_result);

    alter table identityiq.spt_password_policy 
       add constraint FK15k2353b0bf4swvqkteyjutb8 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK15k2353b0bf4swvqkteyjutb8 on identityiq.spt_password_policy (owner);

    alter table identityiq.spt_password_policy_holder 
       add constraint FK47skxwy6vwmh6qdkoo76gao8c 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK47skxwy6vwmh6qdkoo76gao8c on identityiq.spt_password_policy_holder (owner);

    alter table identityiq.spt_password_policy_holder 
       add constraint FK4flfb6aud9uvwfhrdt228g7b7 
       foreign key (policy) 
       references identityiq.spt_password_policy;

    create index identityiq.FK4flfb6aud9uvwfhrdt228g7b7 on identityiq.spt_password_policy_holder (policy);

    alter table identityiq.spt_password_policy_holder 
       add constraint FKsa0togid3d2ers5l0u8p0xxcp 
       foreign key (application) 
       references identityiq.spt_application;

    create index identityiq.FKsa0togid3d2ers5l0u8p0xxcp on identityiq.spt_password_policy_holder (application);

    alter table identityiq.spt_persisted_file 
       add constraint FKay7i45q2li8p1lnvdybls0t3t 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKay7i45q2li8p1lnvdybls0t3t on identityiq.spt_persisted_file (owner);

    alter table identityiq.spt_persisted_file 
       add constraint FKlj0anhv8hg741lmn738bahrek 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKlj0anhv8hg741lmn738bahrek on identityiq.spt_persisted_file (assigned_scope);

    alter table identityiq.spt_plugin 
       add constraint FKr3gksq71itxj5f837unefrg31 
       foreign key (file_id) 
       references identityiq.spt_persisted_file;

    alter table identityiq.spt_policy 
       add constraint FKij2xlldhccmq534sl8n6587od 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKij2xlldhccmq534sl8n6587od on identityiq.spt_policy (owner);

    alter table identityiq.spt_policy 
       add constraint FKoebw2yqhc4j26mx83v49qyw1n 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKoebw2yqhc4j26mx83v49qyw1n on identityiq.spt_policy (assigned_scope);

    alter table identityiq.spt_policy 
       add constraint FK3cfyso96b28h21yaml8hbc3xi 
       foreign key (violation_owner) 
       references identityiq.spt_identity;

    create index identityiq.FK3cfyso96b28h21yaml8hbc3xi on identityiq.spt_policy (violation_owner);

    alter table identityiq.spt_policy 
       add constraint FKgsvi652nk5hayfr8kc7p5ydy 
       foreign key (violation_owner_rule) 
       references identityiq.spt_rule;

    create index identityiq.FKgsvi652nk5hayfr8kc7p5ydy on identityiq.spt_policy (violation_owner_rule);

    alter table identityiq.spt_policy_violation 
       add constraint FKgxlmr2yos1bq05bqb3kxjyhdy 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKgxlmr2yos1bq05bqb3kxjyhdy on identityiq.spt_policy_violation (owner);

    alter table identityiq.spt_policy_violation 
       add constraint FKlfnu8q3fgqq6w8l9t0v15gsjb 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKlfnu8q3fgqq6w8l9t0v15gsjb on identityiq.spt_policy_violation (assigned_scope);

    alter table identityiq.spt_policy_violation 
       add constraint FKphiamrjv42wu7uw5tcsbexjyw 
       foreign key (identity_id) 
       references identityiq.spt_identity;

    create index identityiq.FKphiamrjv42wu7uw5tcsbexjyw on identityiq.spt_policy_violation (identity_id);

    alter table identityiq.spt_policy_violation 
       add constraint FKcfjl95jng7hghpw478qqgajyn 
       foreign key (pending_workflow) 
       references identityiq.spt_workflow_case;

    create index identityiq.FKcfjl95jng7hghpw478qqgajyn on identityiq.spt_policy_violation (pending_workflow);

    alter table identityiq.spt_process_log 
       add constraint FK7ll5fatw1p90l1quxoovyijej 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK7ll5fatw1p90l1quxoovyijej on identityiq.spt_process_log (owner);

    alter table identityiq.spt_process_log 
       add constraint FKtgm6rfk5nrdbjswf140ad6jir 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKtgm6rfk5nrdbjswf140ad6jir on identityiq.spt_process_log (assigned_scope);

    alter table identityiq.spt_profile 
       add constraint FKm77hrlacp3ynlthagggqmq8mn 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKm77hrlacp3ynlthagggqmq8mn on identityiq.spt_profile (owner);

    alter table identityiq.spt_profile 
       add constraint FKdpexklt6enpa3qq3tg34t2i72 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKdpexklt6enpa3qq3tg34t2i72 on identityiq.spt_profile (assigned_scope);

    alter table identityiq.spt_profile 
       add constraint FKb6xsupwlh8e9b6sxrsojaq107 
       foreign key (bundle_id) 
       references identityiq.spt_bundle;

    create index identityiq.FKb6xsupwlh8e9b6sxrsojaq107 on identityiq.spt_profile (bundle_id);

    alter table identityiq.spt_profile 
       add constraint FKh7gmx9te7hdnjh138f0ys70bb 
       foreign key (application) 
       references identityiq.spt_application;

    create index identityiq.FKh7gmx9te7hdnjh138f0ys70bb on identityiq.spt_profile (application);

    alter table identityiq.spt_profile_constraints 
       add constraint FKfnwocslrb1d7i22e0eyyonvu6 
       foreign key (profile) 
       references identityiq.spt_profile;

    create index identityiq.FKfnwocslrb1d7i22e0eyyonvu6 on identityiq.spt_profile_constraints (profile);

    alter table identityiq.spt_profile_permissions 
       add constraint FK9wkru2lsxssnhaus718md3f2o 
       foreign key (profile) 
       references identityiq.spt_profile;

    create index identityiq.FK9wkru2lsxssnhaus718md3f2o on identityiq.spt_profile_permissions (profile);

    alter table identityiq.spt_provisioning_request 
       add constraint FKb0jveyf9sv2e042bjarn190pq 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKb0jveyf9sv2e042bjarn190pq on identityiq.spt_provisioning_request (owner);

    alter table identityiq.spt_provisioning_request 
       add constraint FKgtk4uysamt32hwwqxrdnceodg 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKgtk4uysamt32hwwqxrdnceodg on identityiq.spt_provisioning_request (assigned_scope);

    alter table identityiq.spt_provisioning_request 
       add constraint FKe06usqanbltc3jw079m568c9d 
       foreign key (identity_id) 
       references identityiq.spt_identity;

    create index identityiq.FKe06usqanbltc3jw079m568c9d on identityiq.spt_provisioning_request (identity_id);

    alter table identityiq.spt_quick_link 
       add constraint FKr34ji3ugpva0sp95usrgaooih 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKr34ji3ugpva0sp95usrgaooih on identityiq.spt_quick_link (owner);

    alter table identityiq.spt_quick_link 
       add constraint FK8ircuuuw7sidwf8xmatked859 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK8ircuuuw7sidwf8xmatked859 on identityiq.spt_quick_link (assigned_scope);

    alter table identityiq.spt_quick_link_options 
       add constraint FKr2janfsixof6pqahju9ab112u 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKr2janfsixof6pqahju9ab112u on identityiq.spt_quick_link_options (owner);

    alter table identityiq.spt_quick_link_options 
       add constraint FK159pqn1fd0ubpapm62cy37akd 
       foreign key (dynamic_scope) 
       references identityiq.spt_dynamic_scope;

    create index identityiq.FK159pqn1fd0ubpapm62cy37akd on identityiq.spt_quick_link_options (dynamic_scope);

    alter table identityiq.spt_quick_link_options 
       add constraint FKihngfm8iqb21en8gyeebmpj7h 
       foreign key (quick_link) 
       references identityiq.spt_quick_link;

    create index identityiq.FKihngfm8iqb21en8gyeebmpj7h on identityiq.spt_quick_link_options (quick_link);

    alter table identityiq.spt_remediation_item 
       add constraint FKfd9yg9q55msovcqueyjodr6ui 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKfd9yg9q55msovcqueyjodr6ui on identityiq.spt_remediation_item (owner);

    alter table identityiq.spt_remediation_item 
       add constraint FKhlirh9cempdr7546c4oegeska 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKhlirh9cempdr7546c4oegeska on identityiq.spt_remediation_item (assigned_scope);

    alter table identityiq.spt_remediation_item 
       add constraint FK6bb5fufbeok63cycwmdv1h0b3 
       foreign key (work_item_id) 
       references identityiq.spt_work_item;

    create index identityiq.FK6bb5fufbeok63cycwmdv1h0b3 on identityiq.spt_remediation_item (work_item_id);

    alter table identityiq.spt_remediation_item 
       add constraint FK1vhqs5ybkgm91lv51hdyj68va 
       foreign key (assignee) 
       references identityiq.spt_identity;

    create index identityiq.FK1vhqs5ybkgm91lv51hdyj68va on identityiq.spt_remediation_item (assignee);

    alter table identityiq.spt_remote_login_token 
       add constraint FKe2ofoif1sjdi94r0rhwsc6aqg 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKe2ofoif1sjdi94r0rhwsc6aqg on identityiq.spt_remote_login_token (owner);

    alter table identityiq.spt_remote_login_token 
       add constraint FK57qeahvi3aybfwrgf2mft28b0 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK57qeahvi3aybfwrgf2mft28b0 on identityiq.spt_remote_login_token (assigned_scope);

    alter table identityiq.spt_request 
       add constraint FK4wuia2w4ylm95aja22jnw6upf 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK4wuia2w4ylm95aja22jnw6upf on identityiq.spt_request (owner);

    alter table identityiq.spt_request 
       add constraint FK1st2f3b62703t2anet5iykocf 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK1st2f3b62703t2anet5iykocf on identityiq.spt_request (assigned_scope);

    alter table identityiq.spt_request 
       add constraint FK2oj2nqukawo2p60yiloa72li9 
       foreign key (definition) 
       references identityiq.spt_request_definition;

    create index identityiq.FK2oj2nqukawo2p60yiloa72li9 on identityiq.spt_request (definition);

    alter table identityiq.spt_request 
       add constraint FKgwavtgcmunyt6bx3fvka2a5t2 
       foreign key (task_result) 
       references identityiq.spt_task_result;

    create index identityiq.FKgwavtgcmunyt6bx3fvka2a5t2 on identityiq.spt_request (task_result);

    alter table identityiq.spt_request_arguments 
       add constraint FK113ggg7785j6vdwb9xham03dc 
       foreign key (signature) 
       references identityiq.spt_request_definition;

    create index identityiq.FK113ggg7785j6vdwb9xham03dc on identityiq.spt_request_arguments (signature);

    alter table identityiq.spt_request_definition 
       add constraint FKgao87b86v1y7mrylu96ow04en 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKgao87b86v1y7mrylu96ow04en on identityiq.spt_request_definition (owner);

    alter table identityiq.spt_request_definition 
       add constraint FKhe297ysa9fn4dmdljoq54njbs 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKhe297ysa9fn4dmdljoq54njbs on identityiq.spt_request_definition (assigned_scope);

    alter table identityiq.spt_request_definition 
       add constraint FK2ttetyvbubn1jvp2n9urb6m5v 
       foreign key (parent) 
       references identityiq.spt_request_definition;

    create index identityiq.FK2ttetyvbubn1jvp2n9urb6m5v on identityiq.spt_request_definition (parent);

    alter table identityiq.spt_request_definition_rights 
       add constraint FKp94t40blskwg0fuh854lfml1s 
       foreign key (right_id) 
       references identityiq.spt_right;

    create index identityiq.FKp94t40blskwg0fuh854lfml1s on identityiq.spt_request_definition_rights (right_id);

    alter table identityiq.spt_request_definition_rights 
       add constraint FK3drvcyrlgw6waricqagimmd8e 
       foreign key (request_definition_id) 
       references identityiq.spt_request_definition;

    create index identityiq.FK3drvcyrlgw6waricqagimmd8e on identityiq.spt_request_definition_rights (request_definition_id);

    alter table identityiq.spt_request_returns 
       add constraint FKpbhfh39gtywh48gc1hlfgngox 
       foreign key (signature) 
       references identityiq.spt_request_definition;

    create index identityiq.FKpbhfh39gtywh48gc1hlfgngox on identityiq.spt_request_returns (signature);

    alter table identityiq.spt_request_state 
       add constraint FKqqjbvp3qvso1sb1ca6ombgter 
       foreign key (request_id) 
       references identityiq.spt_request;

    create index identityiq.FKqqjbvp3qvso1sb1ca6ombgter on identityiq.spt_request_state (request_id);

    alter table identityiq.spt_resource_event 
       add constraint FKt1snjotqsqvmoubnwv5vtpri6 
       foreign key (application) 
       references identityiq.spt_application;

    create index identityiq.FKt1snjotqsqvmoubnwv5vtpri6 on identityiq.spt_resource_event (application);

    alter table identityiq.spt_right_config 
       add constraint FKt1r57dhmuc884wt2ymu101hde 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKt1r57dhmuc884wt2ymu101hde on identityiq.spt_right_config (owner);

    alter table identityiq.spt_right_config 
       add constraint FKdx0b0oat38fxsye0jgg5ulu9k 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKdx0b0oat38fxsye0jgg5ulu9k on identityiq.spt_right_config (assigned_scope);

    alter table identityiq.spt_role_index 
       add constraint FKo7ho4tlthd9rr80looh1ooito 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKo7ho4tlthd9rr80looh1ooito on identityiq.spt_role_index (owner);

    alter table identityiq.spt_role_index 
       add constraint FKf0j6gmnubunnb5h7kfe33awf9 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKf0j6gmnubunnb5h7kfe33awf9 on identityiq.spt_role_index (assigned_scope);

    alter table identityiq.spt_role_index 
       add constraint FKl988ko9bkq0epm8ktn25tqpru 
       foreign key (bundle) 
       references identityiq.spt_bundle;

    create index identityiq.FKl988ko9bkq0epm8ktn25tqpru on identityiq.spt_role_index (bundle);

    alter table identityiq.spt_role_metadata 
       add constraint FKaa82j55vly3sm9ftky9obxd38 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKaa82j55vly3sm9ftky9obxd38 on identityiq.spt_role_metadata (owner);

    alter table identityiq.spt_role_metadata 
       add constraint FKt5qt571k5ftna1xswfi723tat 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKt5qt571k5ftna1xswfi723tat on identityiq.spt_role_metadata (assigned_scope);

    alter table identityiq.spt_role_metadata 
       add constraint FK78iwr88o7i8dt8ibvi3vusjq8 
       foreign key (role) 
       references identityiq.spt_bundle;

    create index identityiq.FK78iwr88o7i8dt8ibvi3vusjq8 on identityiq.spt_role_metadata (role);

    alter table identityiq.spt_role_mining_result 
       add constraint FKjpslqep9tigfo52crhjg3hf5v 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKjpslqep9tigfo52crhjg3hf5v on identityiq.spt_role_mining_result (owner);

    alter table identityiq.spt_role_mining_result 
       add constraint FKtok5e8qk7b61q9h76g7h7pr86 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKtok5e8qk7b61q9h76g7h7pr86 on identityiq.spt_role_mining_result (assigned_scope);

    alter table identityiq.spt_role_scorecard 
       add constraint FKt6yfcgq98ed4bfi5ky81wjwdf 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKt6yfcgq98ed4bfi5ky81wjwdf on identityiq.spt_role_scorecard (owner);

    alter table identityiq.spt_role_scorecard 
       add constraint FKqrtue6hcnlf6qyr5qm0vfpwfn 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKqrtue6hcnlf6qyr5qm0vfpwfn on identityiq.spt_role_scorecard (assigned_scope);

    alter table identityiq.spt_role_scorecard 
       add constraint FK4uodpdnn6r77dbqqa4ifdqja3 
       foreign key (role_id) 
       references identityiq.spt_bundle;

    create index identityiq.FK4uodpdnn6r77dbqqa4ifdqja3 on identityiq.spt_role_scorecard (role_id);

    alter table identityiq.spt_rule 
       add constraint FKebikrnbibarckvm36915k8dc7 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKebikrnbibarckvm36915k8dc7 on identityiq.spt_rule (owner);

    alter table identityiq.spt_rule 
       add constraint FKe7tgffr3v5sd2q739bndc72wr 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKe7tgffr3v5sd2q739bndc72wr on identityiq.spt_rule (assigned_scope);

    alter table identityiq.spt_rule_registry_callouts 
       add constraint FKiescqm7tqapb2r71sgdcy20jk 
       foreign key (rule_id) 
       references identityiq.spt_rule;

    create index identityiq.FKiescqm7tqapb2r71sgdcy20jk on identityiq.spt_rule_registry_callouts (rule_id);

    alter table identityiq.spt_rule_registry_callouts 
       add constraint FK8csco7epf6euipthxuj0awqjp 
       foreign key (rule_registry_id) 
       references identityiq.spt_rule_registry;

    create index identityiq.FK8csco7epf6euipthxuj0awqjp on identityiq.spt_rule_registry_callouts (rule_registry_id);

    alter table identityiq.spt_rule_dependencies 
       add constraint FKbju0wunboll2jdihl7c4xa0no 
       foreign key (dependency) 
       references identityiq.spt_rule;

    create index identityiq.FKbju0wunboll2jdihl7c4xa0no on identityiq.spt_rule_dependencies (dependency);

    alter table identityiq.spt_rule_dependencies 
       add constraint FKgvxim0ew7xui4cfpk0gibucxa 
       foreign key (rule_id) 
       references identityiq.spt_rule;

    create index identityiq.FKgvxim0ew7xui4cfpk0gibucxa on identityiq.spt_rule_dependencies (rule_id);

    alter table identityiq.spt_rule_registry 
       add constraint FKlswclannoqopuaet63sct4p74 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKlswclannoqopuaet63sct4p74 on identityiq.spt_rule_registry (owner);

    alter table identityiq.spt_rule_registry 
       add constraint FKthpyc5ikucmt8mbhdcr980ucg 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKthpyc5ikucmt8mbhdcr980ucg on identityiq.spt_rule_registry (assigned_scope);

    alter table identityiq.spt_rule_signature_arguments 
       add constraint FKdys6el89un39n7cyqey0sbdtt 
       foreign key (signature) 
       references identityiq.spt_rule;

    create index identityiq.FKdys6el89un39n7cyqey0sbdtt on identityiq.spt_rule_signature_arguments (signature);

    alter table identityiq.spt_rule_signature_returns 
       add constraint FKrbsto8otv99kfe9kgyij37iml 
       foreign key (signature) 
       references identityiq.spt_rule;

    create index identityiq.FKrbsto8otv99kfe9kgyij37iml on identityiq.spt_rule_signature_returns (signature);

    alter table identityiq.spt_schema_attributes 
       add constraint FKhl9i3n7y97lpqq98etsp4urds 
       foreign key (applicationschema) 
       references identityiq.spt_application_schema;

    create index identityiq.FKhl9i3n7y97lpqq98etsp4urds on identityiq.spt_schema_attributes (applicationschema);

    alter table identityiq.spt_scope 
       add constraint FKht5d7wfgqvify7p0nag6egr2 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKht5d7wfgqvify7p0nag6egr2 on identityiq.spt_scope (owner);

    alter table identityiq.spt_scope 
       add constraint FK984w9lkkhtcrm8ib3y6b2qj8 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK984w9lkkhtcrm8ib3y6b2qj8 on identityiq.spt_scope (assigned_scope);

    alter table identityiq.spt_scope 
       add constraint FKpmmdhx9itj086j9dnu8ydh6gx 
       foreign key (parent_id) 
       references identityiq.spt_scope;

    create index identityiq.FKpmmdhx9itj086j9dnu8ydh6gx on identityiq.spt_scope (parent_id);

    alter table identityiq.spt_scorecard 
       add constraint FK4cgtntcjhmqgrb6fcgion7psd 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK4cgtntcjhmqgrb6fcgion7psd on identityiq.spt_scorecard (owner);

    alter table identityiq.spt_scorecard 
       add constraint FKjlaay4af9d847oiooq03nwrkb 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKjlaay4af9d847oiooq03nwrkb on identityiq.spt_scorecard (assigned_scope);

    alter table identityiq.spt_scorecard 
       add constraint FKhwgs2272xcw9kr4uobastkiqj 
       foreign key (identity_id) 
       references identityiq.spt_identity;

    create index identityiq.FKhwgs2272xcw9kr4uobastkiqj on identityiq.spt_scorecard (identity_id);

    alter table identityiq.spt_score_config 
       add constraint FK58s5g8wnl1pd9ckev17xhlfif 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK58s5g8wnl1pd9ckev17xhlfif on identityiq.spt_score_config (owner);

    alter table identityiq.spt_score_config 
       add constraint FKj2ff5smsk1haaiyo1w7q7pj99 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKj2ff5smsk1haaiyo1w7q7pj99 on identityiq.spt_score_config (assigned_scope);

    alter table identityiq.spt_score_config 
       add constraint FKdct987qb7na0fe12fov9gtp90 
       foreign key (right_config) 
       references identityiq.spt_right_config;

    create index identityiq.FKdct987qb7na0fe12fov9gtp90 on identityiq.spt_score_config (right_config);

    alter table identityiq.spt_server_statistic 
       add constraint FKo4ubx9xkjeqxgnsil2kq8863b 
       foreign key (host) 
       references identityiq.spt_server;

    create index identityiq.FKo4ubx9xkjeqxgnsil2kq8863b on identityiq.spt_server_statistic (host);

    alter table identityiq.spt_server_statistic 
       add constraint FK5q7ultbynm7wn0wki1a0vhse7 
       foreign key (monitoring_statistic) 
       references identityiq.spt_monitoring_statistic;

    create index identityiq.FK5q7ultbynm7wn0wki1a0vhse7 on identityiq.spt_server_statistic (monitoring_statistic);

    alter table identityiq.spt_service_lock 
       add constraint FKiq6v3rrxwrku71j0ghepn66p5 
       foreign key (service_definition) 
       references identityiq.spt_service_definition;

    alter table identityiq.spt_service_status 
       add constraint FKanvkx3ughno0yc6s33p8px5cu 
       foreign key (definition) 
       references identityiq.spt_service_definition;

    create index identityiq.FKanvkx3ughno0yc6s33p8px5cu on identityiq.spt_service_status (definition);

    alter table identityiq.spt_sign_off_history 
       add constraint FKgltduyt883x1og6dkgpt9n0uj 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKgltduyt883x1og6dkgpt9n0uj on identityiq.spt_sign_off_history (owner);

    alter table identityiq.spt_sign_off_history 
       add constraint FK2ipk68cdtj3e4p6u5cp3y3ojc 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK2ipk68cdtj3e4p6u5cp3y3ojc on identityiq.spt_sign_off_history (assigned_scope);

    alter table identityiq.spt_sign_off_history 
       add constraint FKoqlo63ls25h06ufiwokvd8l9g 
       foreign key (certification_id) 
       references identityiq.spt_certification;

    create index identityiq.FKoqlo63ls25h06ufiwokvd8l9g on identityiq.spt_sign_off_history (certification_id);

    alter table identityiq.spt_snapshot_permissions 
       add constraint FKd1pddppbj51lje4diqtw7ycs0 
       foreign key (snapshot) 
       references identityiq.spt_entitlement_snapshot;

    create index identityiq.FKd1pddppbj51lje4diqtw7ycs0 on identityiq.spt_snapshot_permissions (snapshot);

    alter table identityiq.spt_sodconstraint 
       add constraint FKl4mjpujrolswau1wcu0mhn5yr 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKl4mjpujrolswau1wcu0mhn5yr on identityiq.spt_sodconstraint (owner);

    alter table identityiq.spt_sodconstraint 
       add constraint FKkdcp13gq48ggdtye8pas782pb 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKkdcp13gq48ggdtye8pas782pb on identityiq.spt_sodconstraint (assigned_scope);

    alter table identityiq.spt_sodconstraint 
       add constraint FKaoh6dc5hnbdth3l5s5el0ysg1 
       foreign key (policy) 
       references identityiq.spt_policy;

    create index identityiq.FKaoh6dc5hnbdth3l5s5el0ysg1 on identityiq.spt_sodconstraint (policy);

    alter table identityiq.spt_sodconstraint 
       add constraint FK4o50l0rmgaju9n8exvb3pdf5b 
       foreign key (violation_owner) 
       references identityiq.spt_identity;

    create index identityiq.FK4o50l0rmgaju9n8exvb3pdf5b on identityiq.spt_sodconstraint (violation_owner);

    alter table identityiq.spt_sodconstraint 
       add constraint FKsb73wu7qhwhp6dsypgpor8dsi 
       foreign key (violation_owner_rule) 
       references identityiq.spt_rule;

    create index identityiq.FKsb73wu7qhwhp6dsypgpor8dsi on identityiq.spt_sodconstraint (violation_owner_rule);

    alter table identityiq.spt_sodconstraint_left 
       add constraint FKiaye28ptj6gmsp4tflo13r0qy 
       foreign key (businessrole) 
       references identityiq.spt_bundle;

    create index identityiq.FKiaye28ptj6gmsp4tflo13r0qy on identityiq.spt_sodconstraint_left (businessrole);

    alter table identityiq.spt_sodconstraint_left 
       add constraint FKihnxab3mjkx483ftgngk6g0h1 
       foreign key (sodconstraint) 
       references identityiq.spt_sodconstraint;

    create index identityiq.FKihnxab3mjkx483ftgngk6g0h1 on identityiq.spt_sodconstraint_left (sodconstraint);

    alter table identityiq.spt_sodconstraint_right 
       add constraint FK1k33mlfft6ir3ao0scmod2y0i 
       foreign key (businessrole) 
       references identityiq.spt_bundle;

    create index identityiq.FK1k33mlfft6ir3ao0scmod2y0i on identityiq.spt_sodconstraint_right (businessrole);

    alter table identityiq.spt_sodconstraint_right 
       add constraint FKi4p81605xg3ojoycpm4lyfa85 
       foreign key (sodconstraint) 
       references identityiq.spt_sodconstraint;

    create index identityiq.FKi4p81605xg3ojoycpm4lyfa85 on identityiq.spt_sodconstraint_right (sodconstraint);

    alter table identityiq.spt_archived_cert_entity 
       add constraint FKt3lg6vlrrdfqy5xo76lb5p06x 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKt3lg6vlrrdfqy5xo76lb5p06x on identityiq.spt_archived_cert_entity (owner);

    alter table identityiq.spt_archived_cert_entity 
       add constraint FKo4mknf6x4lxygjwvgyoxu3me3 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKo4mknf6x4lxygjwvgyoxu3me3 on identityiq.spt_archived_cert_entity (assigned_scope);

    alter table identityiq.spt_archived_cert_entity 
       add constraint FK8salwd54pmcixneotwbg1e8t1 
       foreign key (certification_id) 
       references identityiq.spt_certification;

    create index identityiq.FK8salwd54pmcixneotwbg1e8t1 on identityiq.spt_archived_cert_entity (certification_id);

    alter table identityiq.spt_archived_cert_item 
       add constraint FK877k5d95c04j14sdw91fyrnth 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK877k5d95c04j14sdw91fyrnth on identityiq.spt_archived_cert_item (owner);

    alter table identityiq.spt_archived_cert_item 
       add constraint FKhoc03daa5guh1iq2isa67wnrg 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKhoc03daa5guh1iq2isa67wnrg on identityiq.spt_archived_cert_item (assigned_scope);

    alter table identityiq.spt_archived_cert_item 
       add constraint FKhsl975h3fmcssmrsnav0xp0be 
       foreign key (parent_id) 
       references identityiq.spt_archived_cert_entity;

    create index identityiq.FKhsl975h3fmcssmrsnav0xp0be on identityiq.spt_archived_cert_item (parent_id);

    alter table identityiq.spt_identity_req_item_attach 
       add constraint FK9j07eg4emep4vaseaa779fatl 
       foreign key (attachment_id) 
       references identityiq.spt_attachment;

    create index identityiq.FK9j07eg4emep4vaseaa779fatl on identityiq.spt_identity_req_item_attach (attachment_id);

    alter table identityiq.spt_identity_req_item_attach 
       add constraint FK32c6p6xsumvu31gciybgj93f8 
       foreign key (identity_request_item_id) 
       references identityiq.spt_identity_request_item;

    create index identityiq.FK32c6p6xsumvu31gciybgj93f8 on identityiq.spt_identity_req_item_attach (identity_request_item_id);

    alter table identityiq.spt_right 
       add constraint FKloubwfokw065ojaeb71h1oa3t 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKloubwfokw065ojaeb71h1oa3t on identityiq.spt_right (owner);

    alter table identityiq.spt_right 
       add constraint FK7xk9w0l2a9p6c0nk9vfdlgyty 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK7xk9w0l2a9p6c0nk9vfdlgyty on identityiq.spt_right (assigned_scope);

    alter table identityiq.spt_sync_roles 
       add constraint FKh7gqwjigw9iepfoix8tu2u0s1 
       foreign key (bundle) 
       references identityiq.spt_bundle;

    create index identityiq.FKh7gqwjigw9iepfoix8tu2u0s1 on identityiq.spt_sync_roles (bundle);

    alter table identityiq.spt_sync_roles 
       add constraint FKda7requ6nyli1ya6k205cvd9o 
       foreign key (config) 
       references identityiq.spt_integration_config;

    create index identityiq.FKda7requ6nyli1ya6k205cvd9o on identityiq.spt_sync_roles (config);

    alter table identityiq.spt_tag 
       add constraint FKmgrthcu01wv36q32tftwjeqhl 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKmgrthcu01wv36q32tftwjeqhl on identityiq.spt_tag (owner);

    alter table identityiq.spt_tag 
       add constraint FK12ckbtpjb7t24wtg5p8mfjcks 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK12ckbtpjb7t24wtg5p8mfjcks on identityiq.spt_tag (assigned_scope);

    alter table identityiq.spt_target 
       add constraint FKey1ldelkwgfnih0bfqsxdy54w 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKey1ldelkwgfnih0bfqsxdy54w on identityiq.spt_target (owner);

    alter table identityiq.spt_target 
       add constraint FKpod5pba81d9huchum3nsgmpta 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKpod5pba81d9huchum3nsgmpta on identityiq.spt_target (assigned_scope);

    alter table identityiq.spt_target 
       add constraint FKai0hmu3219oowiyrjm6ejvh9n 
       foreign key (target_source) 
       references identityiq.spt_target_source;

    create index identityiq.FKai0hmu3219oowiyrjm6ejvh9n on identityiq.spt_target (target_source);

    alter table identityiq.spt_target 
       add constraint FKb3tg6yji6uf5blcn269udqlc7 
       foreign key (application) 
       references identityiq.spt_application;

    create index identityiq.FKb3tg6yji6uf5blcn269udqlc7 on identityiq.spt_target (application);

    alter table identityiq.spt_target 
       add constraint FKn6mv8xwf0vmk1boohfqq13gyy 
       foreign key (parent) 
       references identityiq.spt_target;

    create index identityiq.FKn6mv8xwf0vmk1boohfqq13gyy on identityiq.spt_target (parent);

    alter table identityiq.spt_target_association 
       add constraint FKqxsb4h4ti40gf0t8ljtscryya 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKqxsb4h4ti40gf0t8ljtscryya on identityiq.spt_target_association (owner);

    alter table identityiq.spt_target_association 
       add constraint FKacuykan45qff45db9sj11osbl 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKacuykan45qff45db9sj11osbl on identityiq.spt_target_association (assigned_scope);

    alter table identityiq.spt_target_association 
       add constraint FKhb5il4oxcsn64hbdebuinih52 
       foreign key (target_id) 
       references identityiq.spt_target;

    create index identityiq.FKhb5il4oxcsn64hbdebuinih52 on identityiq.spt_target_association (target_id);

    alter table identityiq.spt_target_source 
       add constraint FKj89r4te5s353ptcfnd2d7q5u8 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKj89r4te5s353ptcfnd2d7q5u8 on identityiq.spt_target_source (owner);

    alter table identityiq.spt_target_source 
       add constraint FKrnt6pd9p8kkfv61w0330xhib6 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKrnt6pd9p8kkfv61w0330xhib6 on identityiq.spt_target_source (assigned_scope);

    alter table identityiq.spt_target_source 
       add constraint FK2j9mi5mcplk3qdb3j0fs4id0t 
       foreign key (correlation_rule) 
       references identityiq.spt_rule;

    create index identityiq.FK2j9mi5mcplk3qdb3j0fs4id0t on identityiq.spt_target_source (correlation_rule);

    alter table identityiq.spt_target_source 
       add constraint FKiu2mtbwoueit24pmdr3lhjrk6 
       foreign key (creation_rule) 
       references identityiq.spt_rule;

    create index identityiq.FKiu2mtbwoueit24pmdr3lhjrk6 on identityiq.spt_target_source (creation_rule);

    alter table identityiq.spt_target_source 
       add constraint FK777oa2vyijp2mq02nuosr81rj 
       foreign key (refresh_rule) 
       references identityiq.spt_rule;

    create index identityiq.FK777oa2vyijp2mq02nuosr81rj on identityiq.spt_target_source (refresh_rule);

    alter table identityiq.spt_target_source 
       add constraint FKrtx5xfiieasobegbhbn9i6f2q 
       foreign key (transformation_rule) 
       references identityiq.spt_rule;

    create index identityiq.FKrtx5xfiieasobegbhbn9i6f2q on identityiq.spt_target_source (transformation_rule);

    alter table identityiq.spt_target_sources 
       add constraint FKeoqgr9sni7dx3wv0jo0kurppy 
       foreign key (elt) 
       references identityiq.spt_target_source;

    create index identityiq.FKeoqgr9sni7dx3wv0jo0kurppy on identityiq.spt_target_sources (elt);

    alter table identityiq.spt_target_sources 
       add constraint FK40hwxe8hphgbyoudtsmolx954 
       foreign key (application) 
       references identityiq.spt_application;

    create index identityiq.FK40hwxe8hphgbyoudtsmolx954 on identityiq.spt_target_sources (application);

    alter table identityiq.spt_task_definition 
       add constraint FKj73ffat8whj2sjle6vcnmit5s 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKj73ffat8whj2sjle6vcnmit5s on identityiq.spt_task_definition (owner);

    alter table identityiq.spt_task_definition 
       add constraint FKijib486kukyyjtf2i4jl4r8x7 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKijib486kukyyjtf2i4jl4r8x7 on identityiq.spt_task_definition (assigned_scope);

    alter table identityiq.spt_task_definition 
       add constraint FK186b24jneods52l19ovut3k25 
       foreign key (parent) 
       references identityiq.spt_task_definition;

    create index identityiq.FK186b24jneods52l19ovut3k25 on identityiq.spt_task_definition (parent);

    alter table identityiq.spt_task_definition 
       add constraint FKq967ll6qee151kju0h7uwn0sj 
       foreign key (signoff_config) 
       references identityiq.spt_work_item_config;

    create index identityiq.FKq967ll6qee151kju0h7uwn0sj on identityiq.spt_task_definition (signoff_config);

    alter table identityiq.spt_task_definition_rights 
       add constraint FK9ah4pq0yle4556apcis8agx3w 
       foreign key (right_id) 
       references identityiq.spt_right;

    create index identityiq.FK9ah4pq0yle4556apcis8agx3w on identityiq.spt_task_definition_rights (right_id);

    alter table identityiq.spt_task_definition_rights 
       add constraint FKf7c9o0fl64otsf323bw9lmq3l 
       foreign key (task_definition_id) 
       references identityiq.spt_task_definition;

    create index identityiq.FKf7c9o0fl64otsf323bw9lmq3l on identityiq.spt_task_definition_rights (task_definition_id);

    alter table identityiq.spt_task_event 
       add constraint FKdr9qfdwq639526kr0s8sn7bsv 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKdr9qfdwq639526kr0s8sn7bsv on identityiq.spt_task_event (owner);

    alter table identityiq.spt_task_event 
       add constraint FK37pe16gm4jk5rq0iqhoxu1flp 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK37pe16gm4jk5rq0iqhoxu1flp on identityiq.spt_task_event (assigned_scope);

    alter table identityiq.spt_task_event 
       add constraint FKjbek8dno75kki81omnix1vn8e 
       foreign key (task_result) 
       references identityiq.spt_task_result;

    create index identityiq.FKjbek8dno75kki81omnix1vn8e on identityiq.spt_task_event (task_result);

    alter table identityiq.spt_task_event 
       add constraint FKsvucgoph5pot9sayepcakum3t 
       foreign key (rule_id) 
       references identityiq.spt_rule;

    create index identityiq.FKsvucgoph5pot9sayepcakum3t on identityiq.spt_task_event (rule_id);

    alter table identityiq.spt_task_result 
       add constraint FK92o7l61ctqgwtb3hnpk8m6nsi 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK92o7l61ctqgwtb3hnpk8m6nsi on identityiq.spt_task_result (owner);

    alter table identityiq.spt_task_result 
       add constraint FKc3i98bcpobratwtdvynrb0d8p 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKc3i98bcpobratwtdvynrb0d8p on identityiq.spt_task_result (assigned_scope);

    alter table identityiq.spt_task_result 
       add constraint FKgv5931h4qht8l60ds42fhay5n 
       foreign key (definition) 
       references identityiq.spt_task_definition;

    create index identityiq.FKgv5931h4qht8l60ds42fhay5n on identityiq.spt_task_result (definition);

    alter table identityiq.spt_task_result 
       add constraint FKhmia6kghdf1stidg0tjawwrqh 
       foreign key (report) 
       references identityiq.spt_jasper_result;

    create index identityiq.FKhmia6kghdf1stidg0tjawwrqh on identityiq.spt_task_result (report);

    alter table identityiq.spt_task_signature_arguments 
       add constraint FK6lxnqcijv324bs8sgqjaclh84 
       foreign key (signature) 
       references identityiq.spt_task_definition;

    create index identityiq.FK6lxnqcijv324bs8sgqjaclh84 on identityiq.spt_task_signature_arguments (signature);

    alter table identityiq.spt_task_signature_returns 
       add constraint FKo0dpi7g348h1boy75cfec0khg 
       foreign key (signature) 
       references identityiq.spt_task_definition;

    create index identityiq.FKo0dpi7g348h1boy75cfec0khg on identityiq.spt_task_signature_returns (signature);

    alter table identityiq.spt_time_period 
       add constraint FKm868jhewgm53i6bl4y59nbefl 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKm868jhewgm53i6bl4y59nbefl on identityiq.spt_time_period (owner);

    alter table identityiq.spt_time_period 
       add constraint FKgrcbpbx476sf3yc5jq81wh0se 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKgrcbpbx476sf3yc5jq81wh0se on identityiq.spt_time_period (assigned_scope);

    alter table identityiq.spt_uiconfig 
       add constraint FK16y8ue1ela4vu4nww3kswhtji 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK16y8ue1ela4vu4nww3kswhtji on identityiq.spt_uiconfig (owner);

    alter table identityiq.spt_uiconfig 
       add constraint FKqj3gj76e5girakxi3nejkch3s 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKqj3gj76e5girakxi3nejkch3s on identityiq.spt_uiconfig (assigned_scope);

    alter table identityiq.spt_uipreferences 
       add constraint FK5rj3vu68py43jjx519hqwnh3t 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK5rj3vu68py43jjx519hqwnh3t on identityiq.spt_uipreferences (owner);

    alter table identityiq.spt_widget 
       add constraint FKi51uo1quso8fdclqgeoj1q5hq 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKi51uo1quso8fdclqgeoj1q5hq on identityiq.spt_widget (owner);

    alter table identityiq.spt_widget 
       add constraint FK7tc8b6i3k86o36mru85lyhw3p 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK7tc8b6i3k86o36mru85lyhw3p on identityiq.spt_widget (assigned_scope);

    alter table identityiq.spt_workflow 
       add constraint FKyvogiw1fu3oegof5fxs2vku8 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKyvogiw1fu3oegof5fxs2vku8 on identityiq.spt_workflow (owner);

    alter table identityiq.spt_workflow 
       add constraint FK1i4qorrnciecvgdvblwrp125e 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FK1i4qorrnciecvgdvblwrp125e on identityiq.spt_workflow (assigned_scope);

    alter table identityiq.spt_workflow_rule_libraries 
       add constraint FKc3ft08r09xw4cwx2tqqnevcxp 
       foreign key (dependency) 
       references identityiq.spt_rule;

    create index identityiq.FKc3ft08r09xw4cwx2tqqnevcxp on identityiq.spt_workflow_rule_libraries (dependency);

    alter table identityiq.spt_workflow_rule_libraries 
       add constraint FKec9mwyk8lv87b7fknm22ax1by 
       foreign key (rule_id) 
       references identityiq.spt_workflow;

    create index identityiq.FKec9mwyk8lv87b7fknm22ax1by on identityiq.spt_workflow_rule_libraries (rule_id);

    alter table identityiq.spt_workflow_case 
       add constraint FK3u37v00ff74e4vm5plubtlqx1 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK3u37v00ff74e4vm5plubtlqx1 on identityiq.spt_workflow_case (owner);

    alter table identityiq.spt_workflow_case 
       add constraint FKklde6fd36kr42tbcep5f16dj9 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKklde6fd36kr42tbcep5f16dj9 on identityiq.spt_workflow_case (assigned_scope);

    alter table identityiq.spt_workflow_registry 
       add constraint FK46n0i40i7596wrm4r19mkf95o 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK46n0i40i7596wrm4r19mkf95o on identityiq.spt_workflow_registry (owner);

    alter table identityiq.spt_workflow_registry 
       add constraint FKg1y46rf6jkacnl8vtiie6wp5i 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKg1y46rf6jkacnl8vtiie6wp5i on identityiq.spt_workflow_registry (assigned_scope);

    alter table identityiq.spt_workflow_target 
       add constraint FKnhcve6g96fyukhtjqu5utjf16 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKnhcve6g96fyukhtjqu5utjf16 on identityiq.spt_workflow_target (owner);

    alter table identityiq.spt_workflow_target 
       add constraint FKjngjkgjmpbwwn9utpq60r7lid 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKjngjkgjmpbwwn9utpq60r7lid on identityiq.spt_workflow_target (assigned_scope);

    alter table identityiq.spt_workflow_target 
       add constraint FKj7uvhprilx2f9fb2u5bcoixwj 
       foreign key (workflow_case_id) 
       references identityiq.spt_workflow_case;

    create index identityiq.FKj7uvhprilx2f9fb2u5bcoixwj on identityiq.spt_workflow_target (workflow_case_id);

    alter table identityiq.spt_work_item 
       add constraint FK2arasbenw5pc3vrsnwvxqmc1n 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FK2arasbenw5pc3vrsnwvxqmc1n on identityiq.spt_work_item (owner);

    alter table identityiq.spt_work_item 
       add constraint FKaqhklr6jna0canhsmjv6q3ttv 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKaqhklr6jna0canhsmjv6q3ttv on identityiq.spt_work_item (assigned_scope);

    alter table identityiq.spt_work_item 
       add constraint FKgkr4i2su940s244kebgc1f4ak 
       foreign key (requester) 
       references identityiq.spt_identity;

    create index identityiq.FKgkr4i2su940s244kebgc1f4ak on identityiq.spt_work_item (requester);

    alter table identityiq.spt_work_item 
       add constraint FKb5kty2abf9yebckhbo6vqjv2l 
       foreign key (workflow_case) 
       references identityiq.spt_workflow_case;

    create index identityiq.FKb5kty2abf9yebckhbo6vqjv2l on identityiq.spt_work_item (workflow_case);

    alter table identityiq.spt_work_item 
       add constraint FKnq8ngnioi09kpss4md9jkr4dq 
       foreign key (assignee) 
       references identityiq.spt_identity;

    create index identityiq.FKnq8ngnioi09kpss4md9jkr4dq on identityiq.spt_work_item (assignee);

    alter table identityiq.spt_work_item 
       add constraint FK77ut3s987e5m9gcoj1yi7ifvo 
       foreign key (certification_ref_id) 
       references identityiq.spt_certification;

    create index identityiq.FK77ut3s987e5m9gcoj1yi7ifvo on identityiq.spt_work_item (certification_ref_id);

    alter table identityiq.spt_work_item_comments 
       add constraint FKrcoqbshrurwy6exnqljnk9147 
       foreign key (work_item) 
       references identityiq.spt_work_item;

    create index identityiq.FKrcoqbshrurwy6exnqljnk9147 on identityiq.spt_work_item_comments (work_item);

    alter table identityiq.spt_work_item_archive 
       add constraint FKi7l692hi3ind4q445liu4vnjt 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKi7l692hi3ind4q445liu4vnjt on identityiq.spt_work_item_archive (owner);

    alter table identityiq.spt_work_item_archive 
       add constraint FKr1av5cjgksel3fq0cop2449dm 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKr1av5cjgksel3fq0cop2449dm on identityiq.spt_work_item_archive (assigned_scope);

    alter table identityiq.spt_work_item_config 
       add constraint FKsaklnun9f7m1ur66reimsj0uh 
       foreign key (owner) 
       references identityiq.spt_identity;

    create index identityiq.FKsaklnun9f7m1ur66reimsj0uh on identityiq.spt_work_item_config (owner);

    alter table identityiq.spt_work_item_config 
       add constraint FKainfds5d2eyh6kt0nudndtjhq 
       foreign key (assigned_scope) 
       references identityiq.spt_scope;

    create index identityiq.FKainfds5d2eyh6kt0nudndtjhq on identityiq.spt_work_item_config (assigned_scope);

    alter table identityiq.spt_work_item_config 
       add constraint FK9fsd71n6x6rgg14g3ipecbei7 
       foreign key (parent) 
       references identityiq.spt_work_item_config;

    create index identityiq.FK9fsd71n6x6rgg14g3ipecbei7 on identityiq.spt_work_item_config (parent);

    alter table identityiq.spt_work_item_config 
       add constraint FKml61l0hu4ipdc0uyusn0u0s4q 
       foreign key (owner_rule) 
       references identityiq.spt_rule;

    create index identityiq.FKml61l0hu4ipdc0uyusn0u0s4q on identityiq.spt_work_item_config (owner_rule);

    alter table identityiq.spt_work_item_config 
       add constraint FKlmrrs1xltdogce59jno83xvqv 
       foreign key (notification_email) 
       references identityiq.spt_email_template;

    create index identityiq.FKlmrrs1xltdogce59jno83xvqv on identityiq.spt_work_item_config (notification_email);

    alter table identityiq.spt_work_item_config 
       add constraint FK2p700iypxpxmrijecptg3bfc9 
       foreign key (reminder_email) 
       references identityiq.spt_email_template;

    create index identityiq.FK2p700iypxpxmrijecptg3bfc9 on identityiq.spt_work_item_config (reminder_email);

    alter table identityiq.spt_work_item_config 
       add constraint FKobeui00a317gyix189atb3dt8 
       foreign key (escalation_email) 
       references identityiq.spt_email_template;

    create index identityiq.FKobeui00a317gyix189atb3dt8 on identityiq.spt_work_item_config (escalation_email);

    alter table identityiq.spt_work_item_config 
       add constraint FK8ya24kn74wr4rmd8ukl7vuv9d 
       foreign key (escalation_rule) 
       references identityiq.spt_rule;

    create index identityiq.FK8ya24kn74wr4rmd8ukl7vuv9d on identityiq.spt_work_item_config (escalation_rule);

    alter table identityiq.spt_work_item_owners 
       add constraint FK4m6v8uagrglqptlephg9ecbm5 
       foreign key (elt) 
       references identityiq.spt_identity;

    create index identityiq.FK4m6v8uagrglqptlephg9ecbm5 on identityiq.spt_work_item_owners (elt);

    alter table identityiq.spt_work_item_owners 
       add constraint FKjpvcxuqhodero8m8cyucavel9 
       foreign key (config) 
       references identityiq.spt_work_item_config;

    create index identityiq.FKjpvcxuqhodero8m8cyucavel9 on identityiq.spt_work_item_owners (config);

    create index identityiq.spt_managed_modified on identityiq.spt_managed_attribute (modified);

    create index identityiq.spt_managed_created on identityiq.spt_managed_attribute (created);

    create index identityiq.spt_managed_comp on identityiq.spt_managed_attribute (application, type, attribute_ci, value_ci);

    create index identityiq.spt_application_created on identityiq.spt_application (created);

    create index identityiq.spt_application_modified on identityiq.spt_application (modified);

    create index identityiq.spt_request_completed on identityiq.spt_request (completed);

    create index identityiq.spt_request_host on identityiq.spt_request (host);

    create index identityiq.spt_request_launched on identityiq.spt_request (launched);

    create index identityiq.spt_request_id_composite on identityiq.spt_request (completed, next_launch, launched);

    create index identityiq.spt_workitem_owner_type on identityiq.spt_work_item (owner, type);

    create index identityiq.spt_role_change_event_created on identityiq.spt_role_change_event (created);

    create index identityiq.spt_audit_event_created on identityiq.spt_audit_event (created);

    create index identityiq.spt_audit_event_targ_act_comp on identityiq.spt_audit_event (target_ci, action_ci);

    create index identityiq.spt_ident_entit_comp_name on identityiq.spt_identity_entitlement (identity_id, name_ci);

    create index identityiq.spt_identity_entitlement_comp on identityiq.spt_identity_entitlement (identity_id, application, native_identity_ci, instance_ci);

    create index identityiq.spt_idrequest_created on identityiq.spt_identity_request (created);

    create index identityiq.spt_arch_cert_item_apps_name on identityiq.spt_arch_cert_item_apps (application_name);

    create index identityiq.spt_appidcomposite on identityiq.spt_link (application, native_identity_ci);

    create index identityiq.spt_uuidcomposite on identityiq.spt_link (application, uuid_ci);

    create index identityiq.spt_task_result_host on identityiq.spt_task_result (host_ci);

    create index identityiq.spt_task_result_launcher on identityiq.spt_task_result (launcher);

    create index identityiq.spt_task_result_created on identityiq.spt_task_result (created);

    create index identityiq.spt_cert_item_apps_name on identityiq.spt_cert_item_applications (application_name);

    create index identityiq.spt_cert_item_att_name_ci on identityiq.spt_certification_item (exception_attribute_name_ci);

    create index identityiq.spt_certification_item_tdn_ci on identityiq.spt_certification_item (target_display_name_ci);

    create index identityiq.spt_appidcompositedelobj on identityiq.spt_deleted_object (application, native_identity_ci);

    create index identityiq.spt_uuidcompositedelobj on identityiq.spt_deleted_object (application, uuid_ci);

    create index identityiq.spt_cert_entity_tdn_ci on identityiq.spt_certification_entity (target_display_name_ci);

    create index identityiq.spt_integration_conf_modified on identityiq.spt_integration_config (modified);

    create index identityiq.spt_integration_conf_created on identityiq.spt_integration_config (created);

    create index identityiq.spt_bundle_modified on identityiq.spt_bundle (modified);

    create index identityiq.spt_bundle_created on identityiq.spt_bundle (created);

    create index identityiq.SPT_IDXE5D0EE5E14FE3C13 on identityiq.spt_certification_archive (created);

    create index identityiq.spt_identity_snapshot_created on identityiq.spt_identity_snapshot (created);

    create index identityiq.spt_certification_certifiers on identityiq.spt_certifiers (certifier);

    create index identityiq.spt_identity_modified on identityiq.spt_identity (modified);

    create index identityiq.spt_identity_created on identityiq.spt_identity (created);

    create index identityiq.spt_externaloidnamecomposite on identityiq.spt_identity_external_attr (object_id, attribute_name_ci);

    create index identityiq.SPT_IDX5B44307DE376B265 on identityiq.spt_link_external_attr (object_id, attribute_name_ci);

    create index identityiq.spt_externalobjectid on identityiq.spt_identity_external_attr (object_id);

    create index identityiq.SPT_IDX1CE9A5A5A51C278D on identityiq.spt_link_external_attr (object_id);

    create index identityiq.spt_externalnamevalcomposite on identityiq.spt_identity_external_attr (attribute_name_ci, value_ci);

    create index identityiq.SPT_IDX6810487CF042CA64 on identityiq.spt_link_external_attr (attribute_name_ci, value_ci);

    create index identityiq.SPT_IDXC8BAE6DCF83839CC on identityiq.spt_jasper_template (assigned_scope_path);

    create index identityiq.spt_custom_assignedscopepath on identityiq.spt_custom (assigned_scope_path);

    create index identityiq.SPT_IDX52403791F605046 on identityiq.spt_generic_constraint (assigned_scope_path);

    create index identityiq.SPT_IDX352BB37529C8F73E on identityiq.spt_identity_archive (assigned_scope_path);

    create index identityiq.SPT_IDXD9728B9EEB248FD0 on identityiq.spt_certification_group (assigned_scope_path);

    create index identityiq.SPT_IDXECB4C9F64AB87280 on identityiq.spt_group_index (assigned_scope_path);

    create index identityiq.spt_category_assignedscopepath on identityiq.spt_category (assigned_scope_path);

    create index identityiq.SPT_IDXCA5C5C012C739356 on identityiq.spt_certification_delegation (assigned_scope_path);

    create index identityiq.SPT_IDX892D67C7AB213062 on identityiq.spt_group_definition (assigned_scope_path);

    create index identityiq.spt_right_assignedscopepath on identityiq.spt_right (assigned_scope_path);

    create index identityiq.SPT_IDX6B29BC60611AFDD4 on identityiq.spt_managed_attribute (assigned_scope_path);

    create index identityiq.SPT_IDXA6D194B42059DB7C on identityiq.spt_application (assigned_scope_path);

    create index identityiq.SPT_IDXE2B6FD83726D2C4 on identityiq.spt_process_log (assigned_scope_path);

    create index identityiq.spt_request_assignedscopepath on identityiq.spt_request (assigned_scope_path);

    create index identityiq.SPT_IDX6BA77F433361865A on identityiq.spt_score_config (assigned_scope_path);

    create index identityiq.SPT_IDX1647668E11063E4 on identityiq.spt_work_item_archive (assigned_scope_path);

    create index identityiq.SPT_IDX2AE3D4A6385CD3E0 on identityiq.spt_message_template (assigned_scope_path);

    create index identityiq.SPT_IDX749C6E992BBAE86 on identityiq.spt_dictionary_term (assigned_scope_path);

    create index identityiq.SPT_IDX836C2831FD8ED7B6 on identityiq.spt_file_bucket (assigned_scope_path);

    create index identityiq.SPT_IDX45D72A5E6CEE19E on identityiq.spt_work_item (assigned_scope_path);

    create index identityiq.SPT_IDX9542C8399A0989C6 on identityiq.spt_bundle_archive (assigned_scope_path);

    create index identityiq.SPT_IDX5BFDE38499178D1C on identityiq.spt_rule_registry (assigned_scope_path);

    create index identityiq.SPT_IDXBB0D4BCC29515FAC on identityiq.spt_policy_violation (assigned_scope_path);

    create index identityiq.SPT_IDXC1811197B7DE5802 on identityiq.spt_role_mining_result (assigned_scope_path);

    create index identityiq.SPT_IDX5165831AA4CEA5C8 on identityiq.spt_audit_event (assigned_scope_path);

    create index identityiq.spt_tag_assignedscopepath on identityiq.spt_tag (assigned_scope_path);

    create index identityiq.spt_uiconfig_assignedscopepath on identityiq.spt_uiconfig (assigned_scope_path);

    create index identityiq.SPT_IDX8F4ABD86AFAD1DA0 on identityiq.spt_scorecard (assigned_scope_path);

    create index identityiq.SPT_IDX8DFD31878D3B3E2 on identityiq.spt_target_association (assigned_scope_path);

    create index identityiq.SPT_IDX686990949D3B0B3C on identityiq.spt_activity_data_source (assigned_scope_path);

    create index identityiq.SPT_IDX59D4F6CD8690EEC on identityiq.spt_certification_definition (assigned_scope_path);

    create index identityiq.SPT_IDX377FCC029A032198 on identityiq.spt_identity_request (assigned_scope_path);

    create index identityiq.SPT_IDXA6919D21F9F21D96 on identityiq.spt_remediation_item (assigned_scope_path);

    create index identityiq.SPT_IDX608761A1BFB4BC8 on identityiq.spt_audit_config (assigned_scope_path);

    create index identityiq.spt_target_assignedscopepath on identityiq.spt_target (assigned_scope_path);

    create index identityiq.SPT_IDX99FA48D474C60BBC on identityiq.spt_task_event (assigned_scope_path);

    create index identityiq.SPT_IDXB52E1053EF6BCC7A on identityiq.spt_correlation_config (assigned_scope_path);

    create index identityiq.SPT_IDX7590C4E191BEDD16 on identityiq.spt_workflow_registry (assigned_scope_path);

    create index identityiq.SPT_IDX99763E0AD76DF7A8 on identityiq.spt_alert_definition (assigned_scope_path);

    create index identityiq.SPT_IDXE4B09B655AF1E31E on identityiq.spt_archived_cert_item (assigned_scope_path);

    create index identityiq.SPT_IDX321B16EB1422CFAA on identityiq.spt_identity_trigger (assigned_scope_path);

    create index identityiq.SPT_IDX660B15141EEE343C on identityiq.spt_workflow_case (assigned_scope_path);

    create index identityiq.spt_rule_assignedscopepath on identityiq.spt_rule (assigned_scope_path);

    create index identityiq.SPT_IDXECBE5C8C4B5A312C on identityiq.spt_capability (assigned_scope_path);

    create index identityiq.SPT_IDXD6F31180C85EB014 on identityiq.spt_quick_link (assigned_scope_path);

    create index identityiq.SPT_IDX4875A7F12BD64736 on identityiq.spt_authentication_question (assigned_scope_path);

    create index identityiq.spt_link_assignedscopepath on identityiq.spt_link (assigned_scope_path);

    create index identityiq.SPT_IDX8CEA0D6E33EF6770 on identityiq.spt_batch_request (assigned_scope_path);

    create index identityiq.SPT_IDX34534BBBC845CD4A on identityiq.spt_task_result (assigned_scope_path);

    create index identityiq.SPT_IDXDCCC1AEC8ACA85EC on identityiq.spt_certification_item (assigned_scope_path);

    create index identityiq.SPT_IDXBED7A8DAA6E4E148 on identityiq.spt_configuration (assigned_scope_path);

    create index identityiq.SPT_IDX5DA4B31DDBDDDB6 on identityiq.spt_activity_constraint (assigned_scope_path);

    create index identityiq.SPT_IDX11035135399822BE on identityiq.spt_mining_config (assigned_scope_path);

    create index identityiq.spt_scope_assignedscopepath on identityiq.spt_scope (assigned_scope_path);

    create index identityiq.SPT_IDX719553AD788A55AE on identityiq.spt_target_source (assigned_scope_path);

    create index identityiq.SPT_IDX1DB04E7170203436 on identityiq.spt_task_definition (assigned_scope_path);

    create index identityiq.SPT_IDXCE071F89DBC06C66 on identityiq.spt_sodconstraint (assigned_scope_path);

    create index identityiq.SPT_IDXC71C52111BEFE376 on identityiq.spt_account_group (assigned_scope_path);

    create index identityiq.SPT_IDX593FB9116D127176 on identityiq.spt_entitlement_group (assigned_scope_path);

    create index identityiq.SPT_IDX7F55103C9C96248C on identityiq.spt_role_metadata (assigned_scope_path);

    create index identityiq.SPT_IDXCEBEA62E59148F0 on identityiq.spt_group_factory (assigned_scope_path);

    create index identityiq.SPT_IDX7EDDBC591F6A3A06 on identityiq.spt_deleted_object (assigned_scope_path);

    create index identityiq.SPT_IDX1A2CF87C3B1B850C on identityiq.spt_certification_entity (assigned_scope_path);

    create index identityiq.SPT_IDXFB512F02CB48A798 on identityiq.spt_certification_challenge (assigned_scope_path);

    create index identityiq.SPT_IDXABF0D041BEBD0BD6 on identityiq.spt_integration_config (assigned_scope_path);

    create index identityiq.SPT_IDXAEACA8FDA84AB44E on identityiq.spt_role_index (assigned_scope_path);

    create index identityiq.SPT_IDXF70D54D58BC80EE on identityiq.spt_role_scorecard (assigned_scope_path);

    create index identityiq.spt_widget_assignedscopepath on identityiq.spt_widget (assigned_scope_path);

    create index identityiq.SPT_IDXCB6BC61E1128A4D0 on identityiq.spt_remote_login_token (assigned_scope_path);

    create index identityiq.spt_form_assignedscopepath on identityiq.spt_form (assigned_scope_path);

    create index identityiq.SPT_IDXA367F317D4A97B02 on identityiq.spt_application_scorecard (assigned_scope_path);

    create index identityiq.SPT_IDX54AF7352EE4EEBE on identityiq.spt_workflow_target (assigned_scope_path);

    create index identityiq.SPT_IDXA5EE253FB5399952 on identityiq.spt_jasper_result (assigned_scope_path);

    create index identityiq.SPT_IDXC439D3638206900 on identityiq.spt_sign_off_history (assigned_scope_path);

    create index identityiq.SPT_IDX6200CF1CF3199A4C on identityiq.spt_batch_request_item (assigned_scope_path);

    create index identityiq.SPT_IDXDD339B534953A27A on identityiq.spt_mitigation_expiration (assigned_scope_path);

    create index identityiq.SPT_IDX9D89C40FB709EAF2 on identityiq.spt_certification_action (assigned_scope_path);

    create index identityiq.SPT_IDXBAE32AF9A1817F46 on identityiq.spt_right_config (assigned_scope_path);

    create index identityiq.spt_workflow_assignedscopepath on identityiq.spt_workflow (assigned_scope_path);

    create index identityiq.SPT_IDXF89E6D4D93CDB0EE on identityiq.spt_monitoring_statistic (assigned_scope_path);

    create index identityiq.spt_profile_assignedscopepath on identityiq.spt_profile (assigned_scope_path);

    create index identityiq.spt_bundle_assignedscopepath on identityiq.spt_bundle (assigned_scope_path);

    create index identityiq.SPT_IDX823D9A61B16AE816 on identityiq.spt_certification_archive (assigned_scope_path);

    create index identityiq.SPT_IDXB1547649C7A749E6 on identityiq.spt_identity_snapshot (assigned_scope_path);

    create index identityiq.SPT_IDXBAF33EB59EE05DBE on identityiq.spt_archived_cert_entity (assigned_scope_path);

    create index identityiq.SPT_IDXFF9A9E0694DBFEA0 on identityiq.spt_partition_result (assigned_scope_path);

    create index identityiq.SPT_IDX133BD716174D236 on identityiq.spt_provisioning_request (assigned_scope_path);

    create index identityiq.SPT_IDX50B36EB8F7F2C884 on identityiq.spt_dynamic_scope (assigned_scope_path);

    create index identityiq.SPT_IDX95FDCE46C5917DC on identityiq.spt_application_schema (assigned_scope_path);

    create index identityiq.SPT_IDXE758C3D7FFA1CC82 on identityiq.spt_attachment (assigned_scope_path);

    create index identityiq.SPT_IDX52AF250AB5405B4 on identityiq.spt_jasper_page_bucket (assigned_scope_path);

    create index identityiq.SPT_IDX1E683C17685A4D02 on identityiq.spt_time_period (assigned_scope_path);

    create index identityiq.SPT_IDX90929F9EDF01B7D0 on identityiq.spt_certification (assigned_scope_path);

    create index identityiq.SPT_IDXEA8F35F17CF0E336 on identityiq.spt_email_template (assigned_scope_path);

    create index identityiq.spt_identity_assignedscopepath on identityiq.spt_identity (assigned_scope_path);

    create index identityiq.SPT_IDXA511A43C73CC4C8C on identityiq.spt_persisted_file (assigned_scope_path);

    create index identityiq.SPT_IDX9393E3B78D0A4442 on identityiq.spt_request_definition (assigned_scope_path);

    create index identityiq.SPT_IDXB999253482041C7C on identityiq.spt_work_item_config (assigned_scope_path);

    create index identityiq.SPT_IDXD9D9048A81D024A8 on identityiq.spt_dictionary (assigned_scope_path);

    create index identityiq.SPT_IDX6F2601261AB4CE0 on identityiq.spt_object_config (assigned_scope_path);

    create index identityiq.spt_policy_assignedscopepath on identityiq.spt_policy (assigned_scope_path);

    create index identityiq.spt_actgroup_name on identityiq.spt_account_group (name);

    create index identityiq.spt_actgroup_name_csi on identityiq.spt_account_group (name_ci);

    create index identityiq.spt_actgroup_native_ci on identityiq.spt_account_group (native_identity_ci);

    create index identityiq.spt_actgroup_key1_ci on identityiq.spt_account_group (key1_ci);

    create index identityiq.spt_actgroup_key2_ci on identityiq.spt_account_group (key2_ci);

    create index identityiq.spt_actgroup_key3_ci on identityiq.spt_account_group (key3_ci);

    create index identityiq.spt_actgroup_key4_ci on identityiq.spt_account_group (key4_ci);

    create index identityiq.spt_alert_extended1_ci on identityiq.spt_alert (extended1_ci);

    create index identityiq.spt_alert_definition_name on identityiq.spt_alert_definition (name_ci);

    create index identityiq.spt_app_extended1_ci on identityiq.spt_application (extended1_ci);

    create index identityiq.spt_application_name on identityiq.spt_application (name_ci);

    create index identityiq.spt_audit_config_name on identityiq.spt_audit_config (name_ci);

    create index identityiq.spt_audit_interface_ci on identityiq.spt_audit_event (interface_ci);

    create index identityiq.spt_audit_source_ci on identityiq.spt_audit_event (source_ci);

    create index identityiq.spt_audit_action_ci on identityiq.spt_audit_event (action_ci);

    create index identityiq.spt_audit_target_ci on identityiq.spt_audit_event (target_ci);

    create index identityiq.spt_audit_application_ci on identityiq.spt_audit_event (application_ci);

    create index identityiq.spt_audit_accountname_ci on identityiq.spt_audit_event (account_name_ci);

    create index identityiq.spt_audit_instance_ci on identityiq.spt_audit_event (instance_ci);

    create index identityiq.spt_audit_attr_ci on identityiq.spt_audit_event (attribute_name_ci);

    create index identityiq.spt_audit_attrVal_ci on identityiq.spt_audit_event (attribute_value_ci);

    create index identityiq.spt_audit_trackingid_ci on identityiq.spt_audit_event (tracking_id_ci);

    create index identityiq.spt_bulkidjoin_id_ci on identityiq.spt_bulk_id_join (join_id_ci);

    create index identityiq.spt_bulkidjoin_prop_ci on identityiq.spt_bulk_id_join (join_property_ci);

    create index identityiq.spt_bulkidjoin_user_ci on identityiq.spt_bulk_id_join (user_id_ci);

    create index identityiq.spt_bundle_extended1_ci on identityiq.spt_bundle (extended1_ci);

    create index identityiq.spt_bundle_dispname_ci on identityiq.spt_bundle (displayable_name_ci);

    create index identityiq.spt_bundle_name on identityiq.spt_bundle (name_ci);

    create index identityiq.spt_bpr_attr_ci on identityiq.spt_bundle_profile_relation (attribute_ci);

    create index identityiq.spt_bpr_value_ci on identityiq.spt_bundle_profile_relation (value_ci);

    create index identityiq.spt_bpr_display_value_ci on identityiq.spt_bundle_profile_relation (display_value_ci);

    create index identityiq.spt_capability_name on identityiq.spt_capability (name_ci);

    create index identityiq.spt_category_name on identityiq.spt_category (name_ci);

    create index identityiq.spt_certification_name_ci on identityiq.spt_certification (name_ci);

    create index identityiq.spt_cert_short_name_ci on identityiq.spt_certification (short_name_ci);

    create index identityiq.spt_cert_application_ci on identityiq.spt_certification (application_id_ci);

    create index identityiq.spt_cert_manager_ci on identityiq.spt_certification (manager_ci);

    create index identityiq.spt_cert_group_id_ci on identityiq.spt_certification (group_definition_id_ci);

    create index identityiq.spt_cert_group_name_ci on identityiq.spt_certification (group_definition_name_ci);

    create index identityiq.spt_cert_type_ci on identityiq.spt_certification (type_ci);

    create index identityiq.spt_cert_task_sched_id_ci on identityiq.spt_certification (task_schedule_id_ci);

    create index identityiq.spt_cert_trigger_id_ci on identityiq.spt_certification (trigger_id_ci);

    create index identityiq.spt_cert_cert_def_id_ci on identityiq.spt_certification (certification_definition_id_ci);

    create index identityiq.spt_cert_phase_ci on identityiq.spt_certification (phase_ci);

    create index identityiq.spt_certification_definition_n on identityiq.spt_certification_definition (name_ci);

    create index identityiq.spt_cert_entity_firstname_ci on identityiq.spt_certification_entity (firstname_ci);

    create index identityiq.spt_cert_entity_lastname_ci on identityiq.spt_certification_entity (lastname_ci);

    create index identityiq.spt_certitem_extended1_ci on identityiq.spt_certification_item (extended1_ci);

    create index identityiq.spt_classif_dispname_ci on identityiq.spt_classification (displayable_name_ci);

    create index identityiq.spt_classification_name on identityiq.spt_classification (name_ci);

    create index identityiq.spt_cloud_access_group_name on identityiq.spt_cloud_access_group (name_ci);

    create index identityiq.spt_cloud_access_role_name on identityiq.spt_cloud_access_role (name_ci);

    create index identityiq.spt_cloud_access_scope_name on identityiq.spt_cloud_access_scope (name_ci);

    create index identityiq.spt_configuration_name on identityiq.spt_configuration (name_ci);

    create index identityiq.spt_correlation_config_name on identityiq.spt_correlation_config (name_ci);

    create index identityiq.spt_custom_name on identityiq.spt_custom (name);

    create index identityiq.spt_custom_name_csi on identityiq.spt_custom (name_ci);

    create index identityiq.spt_delObj_name_ci on identityiq.spt_deleted_object (name_ci);

    create index identityiq.spt_delObj_nativeIdentity_ci on identityiq.spt_deleted_object (native_identity_ci);

    create index identityiq.spt_delObj_objectType_ci on identityiq.spt_deleted_object (object_type_ci);

    create index identityiq.spt_dictionary_term_value on identityiq.spt_dictionary_term (value_ci);

    create index identityiq.spt_dynamic_scope_name on identityiq.spt_dynamic_scope (name_ci);

    create index identityiq.spt_email_template_name on identityiq.spt_email_template (name_ci);

    create index identityiq.spt_ent_snap_application_ci on identityiq.spt_entitlement_snapshot (application_ci);

    create index identityiq.spt_ent_snap_nativeIdentity_ci on identityiq.spt_entitlement_snapshot (native_identity_ci);

    create index identityiq.spt_ent_snap_displayName_ci on identityiq.spt_entitlement_snapshot (display_name_ci);

    create index identityiq.spt_form_name on identityiq.spt_form (name_ci);

    create index identityiq.spt_full_text_index_name on identityiq.spt_full_text_index (name_ci);

    create index identityiq.spt_identity_extended1_ci on identityiq.spt_identity (extended1_ci);

    create index identityiq.spt_identity_extended2_ci on identityiq.spt_identity (extended2_ci);

    create index identityiq.spt_identity_extended3_ci on identityiq.spt_identity (extended3_ci);

    create index identityiq.spt_identity_extended4_ci on identityiq.spt_identity (extended4_ci);

    create index identityiq.spt_identity_extended5_ci on identityiq.spt_identity (extended5_ci);

    create index identityiq.spt_identity_displayName_ci on identityiq.spt_identity (display_name_ci);

    create index identityiq.spt_identity_firstname_ci on identityiq.spt_identity (firstname_ci);

    create index identityiq.spt_identity_lastname_ci on identityiq.spt_identity (lastname_ci);

    create index identityiq.spt_identity_email_ci on identityiq.spt_identity (email_ci);

    create index identityiq.spt_identity_type_ci on identityiq.spt_identity (type_ci);

    create index identityiq.spt_identity_sw_version_ci on identityiq.spt_identity (software_version_ci);

    create index identityiq.spt_identity_name on identityiq.spt_identity (name_ci);

    create index identityiq.spt_identity_ent_name_ci on identityiq.spt_identity_entitlement (name_ci);

    create index identityiq.spt_identity_ent_value_ci on identityiq.spt_identity_entitlement (value_ci);

    create index identityiq.spt_identity_ent_nativeid_ci on identityiq.spt_identity_entitlement (native_identity_ci);

    create index identityiq.spt_identity_ent_instance_ci on identityiq.spt_identity_entitlement (instance_ci);

    create index identityiq.spt_identity_ent_source_ci on identityiq.spt_identity_entitlement (source_ci);

    create index identityiq.spt_id_hist_item_account_ci on identityiq.spt_identity_history_item (account_ci);

    create index identityiq.spt_id_hist_item_ntv_id_ci on identityiq.spt_identity_history_item (native_identity_ci);

    create index identityiq.spt_id_hist_item_attribute_ci on identityiq.spt_identity_history_item (attribute_ci);

    create index identityiq.spt_id_hist_item_value_ci on identityiq.spt_identity_history_item (value_ci);

    create index identityiq.spt_idrequest_target_ci on identityiq.spt_identity_request (target_display_name_ci);

    create index identityiq.spt_idrequest_requestor_ci on identityiq.spt_identity_request (requester_display_name_ci);

    create index identityiq.spt_idrequest_ext_ticket_ci on identityiq.spt_identity_request (external_ticket_id_ci);

    create index identityiq.spt_reqitem_name_ci on identityiq.spt_identity_request_item (name_ci);

    create index identityiq.spt_reqitem_value_ci on identityiq.spt_identity_request_item (value_ci);

    create index identityiq.spt_reqitem_nativeid_ci on identityiq.spt_identity_request_item (native_identity_ci);

    create index identityiq.spt_reqitem_instance_ci on identityiq.spt_identity_request_item (instance_ci);

    create index identityiq.spt_integration_config_name on identityiq.spt_integration_config (name_ci);

    create index identityiq.spt_jasper_template_name on identityiq.spt_jasper_template (name_ci);

    create index identityiq.spt_link_key1_ci on identityiq.spt_link (key1_ci);

    create index identityiq.spt_link_extended1_ci on identityiq.spt_link (extended1_ci);

    create index identityiq.spt_link_dispname_ci on identityiq.spt_link (display_name_ci);

    create index identityiq.spt_link_nativeIdentity_ci on identityiq.spt_link (native_identity_ci);

    create index identityiq.spt_managed_attr_extended1_ci on identityiq.spt_managed_attribute (extended1_ci);

    create index identityiq.spt_managed_attr_extended2_ci on identityiq.spt_managed_attribute (extended2_ci);

    create index identityiq.spt_managed_attr_extended3_ci on identityiq.spt_managed_attribute (extended3_ci);

    create index identityiq.spt_managed_attr_attr_ci on identityiq.spt_managed_attribute (attribute_ci);

    create index identityiq.spt_managed_attr_value_ci on identityiq.spt_managed_attribute (value_ci);

    create index identityiq.spt_managed_attr_dispname_ci on identityiq.spt_managed_attribute (displayable_name_ci);

    create index identityiq.spt_managed_attr_uuid_ci on identityiq.spt_managed_attribute (uuid_ci);

    create index identityiq.spt_ma_key1_ci on identityiq.spt_managed_attribute (key1_ci);

    create index identityiq.spt_ma_key2_ci on identityiq.spt_managed_attribute (key2_ci);

    create index identityiq.spt_ma_key3_ci on identityiq.spt_managed_attribute (key3_ci);

    create index identityiq.spt_ma_key4_ci on identityiq.spt_managed_attribute (key4_ci);

    create index identityiq.spt_managed_attribute_hash on identityiq.spt_managed_attribute (hash_ci);

    create index identityiq.spt_message_template_name on identityiq.spt_message_template (name_ci);

    create index identityiq.spt_mining_config_name on identityiq.spt_mining_config (name_ci);

    create index identityiq.spt_mitigation_account_ci on identityiq.spt_mitigation_expiration (native_identity_ci);

    create index identityiq.spt_mitigation_attr_name_ci on identityiq.spt_mitigation_expiration (attribute_name_ci);

    create index identityiq.spt_mitigation_attr_val_ci on identityiq.spt_mitigation_expiration (attribute_value_ci);

    create index identityiq.spt_module_name on identityiq.spt_module (name_ci);

    create index identityiq.spt_monitoring_statistic_name on identityiq.spt_monitoring_statistic (name_ci);

    create index identityiq.spt_nativeidchange_identity_ci on identityiq.spt_native_identity_change_event (identity_id_ci);

    create index identityiq.spt_nativeidchange_link_ci on identityiq.spt_native_identity_change_event (link_id_ci);

    create index identityiq.spt_nativeidchange_ma_ci on identityiq.spt_native_identity_change_event (managed_attribute_id_ci);

    create index identityiq.spt_nativeidchange_oldni_ci on identityiq.spt_native_identity_change_event (old_native_identity_ci);

    create index identityiq.spt_nativeidchange_uuid_ci on identityiq.spt_native_identity_change_event (uuid_ci);

    create index identityiq.spt_object_config_name on identityiq.spt_object_config (name_ci);

    create index identityiq.spt_partition_result_name on identityiq.spt_partition_result (name_ci);

    create index identityiq.spt_password_policy_name on identityiq.spt_password_policy (name_ci);

    create index identityiq.spt_plugin_name_ci on identityiq.spt_plugin (name_ci);

    create index identityiq.spt_plugin_dn_ci on identityiq.spt_plugin (display_name_ci);

    create index identityiq.spt_policy_name on identityiq.spt_policy (name_ci);

    create index identityiq.spt_prvtrans_app_ci on identityiq.spt_provisioning_transaction (application_name_ci);

    create index identityiq.spt_prvtrans_idn_ci on identityiq.spt_provisioning_transaction (identity_name_ci);

    create index identityiq.spt_prvtrans_iddn_ci on identityiq.spt_provisioning_transaction (identity_display_name_ci);

    create index identityiq.spt_prvtrans_nid_ci on identityiq.spt_provisioning_transaction (native_identity_ci);

    create index identityiq.spt_prvtrans_adn_ci on identityiq.spt_provisioning_transaction (account_display_name_ci);

    create index identityiq.spt_prvtrans_integ_ci on identityiq.spt_provisioning_transaction (integration_ci);

    create index identityiq.spt_quick_link_name on identityiq.spt_quick_link (name_ci);

    create index identityiq.spt_recommender_definition_nam on identityiq.spt_recommender_definition (name_ci);

    create index identityiq.spt_request_definition_name on identityiq.spt_request_definition (name_ci);

    create index identityiq.spt_right_config_name on identityiq.spt_right_config (name_ci);

    create index identityiq.spt_rule_name on identityiq.spt_rule (name_ci);

    create index identityiq.spt_rule_registry_name on identityiq.spt_rule_registry (name_ci);

    create index identityiq.scope_name_ci on identityiq.spt_scope (name_ci);

    create index identityiq.scope_disp_name_ci on identityiq.spt_scope (display_name_ci);

    create index identityiq.spt_score_config_name on identityiq.spt_score_config (name_ci);

    create index identityiq.spt_server_extended1_ci on identityiq.spt_server (extended1_ci);

    create index identityiq.spt_server_name on identityiq.spt_server (name_ci);

    create index identityiq.spt_service_definition_name on identityiq.spt_service_definition (name_ci);

    create index identityiq.spt_service_status_name on identityiq.spt_service_status (name_ci);

    create index identityiq.spt_arch_entity_tgt_name on identityiq.spt_archived_cert_entity (target_name);

    create index identityiq.spt_arch_entity_tgt_name_csi on identityiq.spt_archived_cert_entity (target_name_ci);

    create index identityiq.spt_arch_entity_identity on identityiq.spt_archived_cert_entity (identity_name);

    create index identityiq.spt_arch_entity_identity_csi on identityiq.spt_archived_cert_entity (identity_name_ci);

    create index identityiq.spt_arch_entity_acct_grp on identityiq.spt_archived_cert_entity (account_group);

    create index identityiq.spt_arch_entity_acct_grp_csi on identityiq.spt_archived_cert_entity (account_group_ci);

    create index identityiq.spt_right_name on identityiq.spt_right (name_ci);

    create index identityiq.spt_tag_name on identityiq.spt_tag (name_ci);

    create index identityiq.spt_target_extended1_ci on identityiq.spt_target (extended1_ci);

    create index identityiq.spt_target_assoc_targ_name_ci on identityiq.spt_target_association (target_name_ci);

    create index identityiq.spt_task_definition_name on identityiq.spt_task_definition (name_ci);

    create index identityiq.spt_taskresult_targetname_ci on identityiq.spt_task_result (target_name_ci);

    create index identityiq.spt_task_result_name on identityiq.spt_task_result (name_ci);

    create index identityiq.spt_uiconfig_name on identityiq.spt_uiconfig (name_ci);

    create index identityiq.spt_widget_name on identityiq.spt_widget (name_ci);

    create index identityiq.spt_workflow_name on identityiq.spt_workflow (name_ci);

    create index identityiq.spt_workflow_registry_name on identityiq.spt_workflow_registry (name_ci);

    create index identityiq.spt_workflow_test_suite_name on identityiq.spt_workflow_test_suite (name_ci);

    create index identityiq.spt_item_archive_owner_ci on identityiq.spt_work_item_archive (owner_name_ci);

    create index identityiq.spt_item_archive_assignee_ci on identityiq.spt_work_item_archive (assignee_ci);

    create index identityiq.spt_item_archive_requester_ci on identityiq.spt_work_item_archive (requester_ci);

    create sequence identityiq.spt_identity_request_sequence start with 1 increment by 1 nocache order;

    create sequence identityiq.spt_work_item_sequence start with 1 increment by 1 nocache order;

    create sequence identityiq.spt_syslog_event_sequence start with 1 increment by 1 nocache order;

    create sequence identityiq.spt_prv_trans_sequence start with 1 increment by 1 nocache order;

    create sequence identityiq.spt_alert_sequence start with 1 increment by 1 nocache order;
