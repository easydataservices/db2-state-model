# Installation instructions

Follow the steps in the subsequent sections to install.

## Quick installation

Execute Korn shell script ``build_schema.sh -d <database name>`` to create the tablespaces and schema in your database (substituting your database name for ``<database name>``)

Include option ``-s <schema name>`` (substituting the desired schema name for ``<schema name>``) to use a schema name other the default STATEMODEL.

Include option ``-t`` to skip tablespace creation; this is appropriate if recreating the schema after dropping it but not the tablespaces.

## Uninstalling

If you wish to uninstall, you can do so quickly with ADMIN_DROP_SCHEMA.

For example: ``CALL admin_drop_schema('STATEMODEL', NULL, 'TEMP', 'DROP_SCHEMA')``

The security administer will need to remove related roles.

## Next steps

You need to populate your metadata. See the [Insurance Policy Example](EXAMPLE.md).

## Manual installation

### Environment

1. Connect to your Db2 for LUW database.
1. Change to the ``db2`` directory.
1. The default schema is STATEMODEL. If you want to implement using a different schema name then edit file set_env.sql. Then execute the script to set the environment: ``db2 -tf set_env.sql``
1. The default tablespaces are defined in file tablespaces_STATEMODEL.sql. You may change the definitions, for example to assign specific page sizes, bufferpools or storage groups. Then execute the script: ``db2 -tf tablespaces_STATEMODEL``

### Tables and sequences

Execute the following steps in order to create the tables:
```
db2 -tf table_OBJTYP.sql
db2 -tf table_MODELZ.sql
db2 -tf table_MODSTA.sql
db2 -tf table_STATRA.sql
db2 -tf table_OBJECT.sql
db2 -tf table_OBSTTR.sql
db2 -tf table_OBTRQU.sql
db2 -tf table_SUBSCR.sql
db2 -tf table_SUBBAC.sql
```

Create the sequences:
```
db2 -tf sequence_OBJECT_ID.sql
db2 -tf sequence_TRANSITION_ID.sql
```

### Modules

#### Create module definitions

Execute the following steps in order:
```
db2 -tf module_AUXILIARY.sql
db2 -tf module_MODEL_INFO.sql
db2 -tf module_OBJECT_CHANGE.sql
db2 -tf module_OBJECT_INFO.sql
db2 -tf module_SUBSCRIPTION.sql
```

### Create module AUXILIARY routines

Execute the following step:
```
db2 -td@ -f module_AUXILIARY/function_IS_JSON_DOCUMENT.sql
```

### Create module MODEL_INFO routines

Execute the following step:
```
db2 -td@ -f module_MODEL_INFO/function_GET_ACTIVE_STATES.sql
db2 -td@ -f module_MODEL_INFO/function_GET_ALL_STATES.sql
db2 -td@ -f module_MODEL_INFO/function_HAS_STATE.sql
```

### Create module OBJECT_CHANGE routines

Execute the following steps in order:
```
db2 -td@ -f module_OBJECT_CHANGE/function_IS_FROM_STATES_MATCH.sql
db2 -td@ -f module_OBJECT_CHANGE/function_IS_QUORATE.sql
db2 -td@ -f module_OBJECT_CHANGE/procedure_TRACK_OBJECT_QUORUMS.sql
db2 -td@ -f module_OBJECT_CHANGE/procedure_ADD_OBJECT.sql
db2 -td@ -f module_OBJECT_CHANGE/procedure_APPLY_TRANSITION.sql
```

### Create module OBJECT_INFO routines

Execute the following steps:
```
db2 -td@ -f module_OBJECT_INFO/function_OBJECT_ID.sql
db2 -td@ -f module_OBJECT_INFO/function_GET_OBJECT.sql
db2 -td@ -f module_OBJECT_INFO/function_GET_OBJECT_TRANSITIONS.sql
db2 -td@ -f module_OBJECT_INFO/function_OBJECT_JSON.sql
db2 -td@ -f module_OBJECT_INFO/function_TRANSITION_JSON.sql
```
### Create module SUBSCRIPTION routines

Execute the following steps:
```
db2 -tf module_SUBSCRIPTION/type_SUBSCRIPTION_ROW.sql
db2 -td@ -f module_SUBSCRIPTION/function_IS_SKIPPABLE.sql
db2 -td@ -f module_SUBSCRIPTION/function_IS_COMMITTED.sql
db2 -td@ -f module_SUBSCRIPTION/function_IS_DATA_MISSING.sql
db2 -td@ -f module_SUBSCRIPTION/function_GET_TRANSITIONS_FOR_ALL.sql
db2 -td@ -f module_SUBSCRIPTION/function_GET_TRANSITIONS_FOR_CODE.sql
db2 -td@ -f module_SUBSCRIPTION/function_GET_BACKTRACK_TRANSITIONS.sql
db2 -td@ -f module_SUBSCRIPTION/function_GET_TRANSITIONS.sql
db2 -td@ -f module_SUBSCRIPTION/procedure_SET_LAST_TRANSITION.sql
db2 -td@ -f module_SUBSCRIPTION/procedure_ADD_BACKTRACK_TRANSITION_RANGE.sql
db2 -td@ -f module_SUBSCRIPTION/procedure_REMOVE_BACKTRACK_TRANSITION.sql
```

## See also

* [Overview](../README.md)