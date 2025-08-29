#!/bin/ksh
# ------------------------------------------------------------------------------------------------------------------------------
# File:         build_schema.sh
#               (c) Copyright Jeremy Rickard 2025
# ------------------------------------------------------------------------------------------------------------------------------

  # Notify incorrect invocation
  function usage {
    print "Usage: build_schema.sh -d <database name> -s <schema name> -t"
    print "  Option -d <database name>: Database in which to create objects [mandatory]"
    print "  Option -s <schema name>: Schema name [optional, default STATEMODEL]"
    print "  Option -t: Skip tablespace creation [optional, use after dropping only schema]"
    test ! -z "$1" && print "\n $1"
    exit 1
  }

  # Abort
  function abort {
    print "# ABORT: $1"
    exit 4    
  }

  # Log message
  function log {
    print "$1"
  }

  # Connect to database
  function connect {
    typeset sql

    log "  # Establish database connection: ${dbName} ... [$0]"
    sql=$(print -r -- "CONNECT TO ${dbName};")
    print -r -- "${sql}" | db2 +p -t
    test $? -eq 0 || abort "Failed to connect to database"
    sql=$(print -r -- "SET SCHEMA ${schemaName};")
    print -r -- "${sql}" | db2 +p -t
    test $? -eq 0 || abort "Error setting schema name"
    sql=$(print -r -- "SET PATH SYSTEM PATH, ${schemaName};")
    print -r -- "${sql}" | db2 +p -t
    test $? -eq 0 || abort "Error setting path"
    log "  # Done"
    return 0
  }

  # Execute SQL script
  function execSql {
    log "  # Execute SQL script $1 ... [$0]"
    print -r -- "${sql}" | db2 +p -stf $1
    test $? -le 2 || abort "Error executing SQL script"
    log "  # Done"
    return 0
  }

  # Execute SQL routine script
  function execRoutineSql {
    log "  # Execute SQL routine script $1 ... [$0]"
    print -r -- "${sql}" | db2 +p -std@ -f $1
    test $? -eq 0 || abort "Error executing SQL routine script"
    log "  # Done"
    return 0
  }

# Set environment.
cd $(dirname $0)

# Set argument defaults.
typeset dbName
typeset schemaName="STATEMODEL"
typeset -i skipTablespaces=0

# Get parameters.
while getopts "d:s:t" opt
do
  case ${opt} in
    d) dbName=$(print ${OPTARG} | tr 'a-z' 'A-Z') || usage ;;
    s) schemaName=$(print ${OPTARG} | tr 'a-z' 'A-Z') || usage ;;
    t) skipTablespaces=1 ;;
    *) usage ;;
  esac
done
shift ${OPTIND}-1
test $# -eq 0 || usage

# Verify and finalize settings.
logFile="${logDir}/capture_table_stats.${dbName}.$(date +%Y%m%d).log"
test -z "${dbName}" && usage "Database name must be specified"
test -z "${schemaName}" && usage "Schema name must be specified"

# Build the schema.
log "# Start"
log "#   Invocation: build_schema.sh -d ${dbName} -s ${schemaName}"
connect
test skipTablespaces -eq 0 && execSql tablespaces_STATEMODEL.sql
execSql table_OBJTYP.sql
execSql table_MODELZ.sql
execSql table_MODSTA.sql
execSql table_STATRA.sql
execSql table_OBJECT.sql
execSql table_OBSTTR.sql
execSql table_OBTRQU.sql
execSql table_SUBSCR.sql
execSql table_SUBBAC.sql
execSql sequence_OBJECT_ID.sql
execSql sequence_TRANSITION_ID.sql
execSql module_AUXILIARY.sql
execSql module_MODEL_INFO.sql
execSql module_OBJECT_CHANGE.sql
execSql module_OBJECT_INFO.sql
execSql module_SUBSCRIPTION.sql
execRoutineSql module_AUXILIARY/function_IS_JSON_DOCUMENT.sql
execRoutineSql module_MODEL_INFO/function_GET_ACTIVE_STATES.sql
execRoutineSql module_MODEL_INFO/function_GET_ALL_STATES.sql
execRoutineSql module_MODEL_INFO/function_HAS_STATE.sql
execRoutineSql module_OBJECT_CHANGE/function_IS_FROM_STATES_MATCH.sql
execRoutineSql module_OBJECT_CHANGE/function_IS_QUORATE.sql
execRoutineSql module_OBJECT_CHANGE/procedure_TRACK_OBJECT_QUORUMS.sql
execRoutineSql module_OBJECT_CHANGE/procedure_ADD_OBJECT.sql
execRoutineSql module_OBJECT_CHANGE/procedure_APPLY_TRANSITION.sql
execRoutineSql module_OBJECT_INFO/function_OBJECT_ID.sql
execRoutineSql module_OBJECT_INFO/function_GET_OBJECT.sql
execRoutineSql module_OBJECT_INFO/function_GET_OBJECT_TRANSITIONS.sql
execRoutineSql module_OBJECT_INFO/function_OBJECT_JSON.sql
execRoutineSql module_OBJECT_INFO/function_TRANSITION_JSON.sql
execSql module_SUBSCRIPTION/type_SUBSCRIPTION_ROW.sql
execRoutineSql module_SUBSCRIPTION/function_IS_SKIPPABLE.sql
execRoutineSql module_SUBSCRIPTION/function_IS_COMMITTED.sql
execRoutineSql module_SUBSCRIPTION/function_IS_DATA_MISSING
execRoutineSql module_SUBSCRIPTION/function_GET_TRANSITIONS_FOR_ALL.sql
execRoutineSql module_SUBSCRIPTION/function_GET_TRANSITIONS_FOR_CODE.sql
execRoutineSql module_SUBSCRIPTION/function_GET_BACKTRACK_TRANSITIONS.sql
execRoutineSql module_SUBSCRIPTION/function_GET_TRANSITIONS.sql
execRoutineSql module_SUBSCRIPTION/procedure_SET_LAST_TRANSITION.sql
execRoutineSql module_SUBSCRIPTION/procedure_ADD_BACKTRACK_TRANSITION_RANGE.sql
execRoutineSql module_SUBSCRIPTION/procedure_REMOVE_BACKTRACK_TRANSITION.sql
