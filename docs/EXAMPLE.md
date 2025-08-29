# Insurance Policy Example

This example imagines a financial services company that provides insurance to customers. Online quotes for draft policies can be submitted by the customer for approval. Once approved, a policy is paid for and activated. To protect the company, the fraud team have systems that monitor for possibly fraudulent activity.

<img src="db2-state-model.png" title="db2-state-model example" width="70%"/>

###### Note
For brevity, in the examples below the output of many SQL statements is omitted. It is assumed that these statements are successful in all cases, and the actual output is not interesting. Where shown, output is indented.

## Metadata setup

As part of the system setup, static metadata is required to define permitted model states and transitions for an object type.

### Add a new Object Type

The object type is used to identify different sets of data in the STATEMODEL schema. Every state model, transition and object is associated with an object type.

In the Insurance Policy example, we create a new object type that represents a prospective insurance policy:

###### Metadata insert for new object type
```
INSERT INTO object_type(object_type_id, type_name, owner, default_model_states, creator_role, viewer_role, json_viewer_role)
VALUES
  (99, 'INSURANCE_POLICY', 'Insurance Division', 81, 'POLICY_CREATOR', 'POLICY_VIEWER', 'JSON_VIEWER');
```

``99`` is used as the unique identifier of this object type. ``Insurance Policy`` is the type name, and all data of this object type is owned by the ``Insurance Division``. The creator and viewer roles define which database roles a database user must have to update or view data of this object type. Default model states define the initial model states, but this is described in more detail later.

### Create the Models for the new Object Type

To be useful, the object type must be associated with at least one state model. Typically, a model represents a graph, with a number of related but mutually exclusive states. However some models can permit multiple concurrent states.

In the Insurance Policy example, we use three related models (shown top to bottom in the previous diagram):
1. A model representing the lifecycle of a policy. This includes a number of prospect policy states before the policy is (hopefully) activated.
1. A model that tracks whether a policy is current or expired. Both a policy application and an activated policy can expire. However, is it helpful to track this separately so that we can easily see when a policy expired. For example, the business may wish to take actions for active policies that expire that would not apply to, say, expired unsubmitted applications.
1. A model that allows a policy to be tagged or untagged with a "fraud flag". This represents a concern about potential fraud.

Each model is defined by a unique model identifier, and associated with the object type:

###### Metadata insert for new models
```
INSERT INTO model(model_id, object_type_id, model_name)
VALUES
  (1, 99, 'Prospect & Policy Lifecycle'),
  (2, 99, 'Expiry'),
  (3, 99, 'Fraud Flag');
```

### Define the Model States

In the db2-state-model solution, model states are mapped to individual bits of a Db2 INTEGER column. This allows up to 31 model states (bits 0 to 30) for any given object type.

It is normal for every model to have two or more states. An edge case in our example is the fraud flag model, which we implement using a single bit flag (mostly to show this can still work when we define the transitions):

###### Metadata inserts for permitted model states
```
INSERT INTO model_state(model_id, object_type_id, bit_index, state_code)
VALUES
  (1, 99, 0, 'draft'),
  (1, 99, 1, 'submitted'),
  (1, 99, 2, 'approved'),
  (1, 99, 3, 'active'),
  (1, 99, 9, 'refused');

INSERT INTO model_state(model_id, object_type_id, bit_index, state_code)
VALUES
  (2, 99, 4, 'current'),
  (2, 99, 5, 'expired');

INSERT INTO model_state(model_id, object_type_id, bit_index, state_code)
VALUES
  (3, 99, 6, 'not flagged');
```

Going back to the default model states defined when we added the object type, we can see now that 81 defines the initial state of our three models for the object type, being the sum of the bit values:

###### States decode query
```
SELECT *, POWER(2, bit_index) AS bit_value FROM TABLE(model_info.get_active_states(99, 81));
```

###### Output
```
MODEL_ID    BIT_INDEX STATE_CODE           BIT_VALUE  
----------- --------- -------------------- -----------
          1         0 draft                          1
          2         4 current                       16
          3         6 not flagged                   64
    
  3 record(s) selected.
```

### Define the State Transitions

Reflecting their power perhaps, state transitions are the most complex part of setup. A state transition is an event that transforms the model from one set of states to another set of states. It can alter the state of either a single model or multiple models associated with an object.

When defining our transitions, we will be working with the bit values of the states in our models for object type ``99``:

###### All states query
```
SELECT *, POWER(2, bit_index) AS bit_value FROM TABLE(model_info.get_all_states(99));
```

###### Output
```
MODEL_ID    BIT_INDEX STATE_CODE           BIT_VALUE  
----------- --------- -------------------- -----------
          1         0 draft                          1
          1         1 submitted                      2
          1         2 approved                       4
          1         3 active                         8
          1         9 refused                      512
          2         4 current                       16
          2         5 expired                       32
          3         6 not flagged                   64

  8 record(s) selected.
```

A key principle is that the MODEL_STATES value of an object is always the sum of the bit values of all active states of each of the models associated with the object type. In a single operation, a transition can enable or disable a single state or multiple states.

We define state transition rules as rows in the STATE_TRANSITION table. Each row defines a transition. To understand the usage of each column in this table, consider the TRANSITION_CODE ``submit`` row in the first set of rows added for object type ``99``:

###### Metadata insert for permitted state transitions
```
INSERT INTO state_transition
(
  object_type_id,
  transition_code,
  bitand_match_rule,
  from_mask,
  to_mask_off,
  to_mask_on,
  transition_role,
  transition_quorum,
  description
)
VALUES
  (99, '_INIT', 'NONE', DEFAULT, DEFAULT, 1 + 16 + 64, 'INSURANCE_SERVICE', 1, 'Initialise'),
  (99, 'submit', 'ALL', 1 + 16 + 64, DEFAULT, 2 + 16 + 64, 'INSURANCE_SERVICE', 1, 'Submit'),
  (99, 'approve', 'ALL', 2 + 16 + 64, DEFAULT, 4 + 16 + 64, 'STANDARD_APPROVER', 2, 'Approve submission'),
  (99, 'fast-track', 'ALL', 2 + 16 + 64, DEFAULT, 4 + 16 + 64, 'SPECIAL_APPROVER', 1, 'Fast-track submission'),
  (99, 'refuse', 'ALL', 2 + 16, 2147483647 - 64, 512 + 16, 'APPROVER', 1, 'Reject submission'),
  (99, 'activate', 'ALL', 4 + 16 + 64, DEFAULT, 8 + 16 + 64, 'PAYMENTS_SERVICE', 1, 'Activate policy');
```

OBJECT_TYPE_ID and TRANSITION_CODE form the primary key of the STATE_TRANSITION table.

The purpose of each of the columns in the table:
* OBJECT_TYPE_ID ``99``: Identifies the object type to which the transition relates.
* TRANSITION_CODE ``submit``: A name for the transition. A good name reflects an event or action. Note also ``_INIT``, a reserved name used to define an initial transition that sets the default state for the object type. 
* BITAND_MATCH_RULE: Used in combination with column FROM_MASK to define a rule that decides whether or not a transition is permitted. The default is ``ALL``, meaning that for the transition to be permitted all bits of the masked object MODEL_STATES must be set on. Other column values are ``NONE`` (no bits must be on) or ``SOME`` (at least one bit must be on). A value of ``ANY`` is means no rule in applied, the transition will always be permitted.
* FROM_MASK: Defines the bit mask that is applied to the pre-transition MODEL_STATES of an object, before applying the bit matching rule defined by column BITAND_MATCH_RULE. In the example of the ``submit`` row, we use ``1 + 16 + 64`` i.e. ``81``. The ``1`` bit value of the Prospect & Policy Lifecycle model means that policy must be in a draft state to be submitted, the ``16`` bit value of the Expiry model means that it must be current i.e. not expired, and the ``64`` bit value of the Fraud Flag model means the policy is not flagged (contrast the ``refuse`` row, which disregards ``64`` because the business can refuse a policy application whether or not it is fraud flagged). The ``DEFAULT`` values corresponds with INTEGER maximum 2147483647, meaning all bits are considered by the matching rule.
* TO_MASK_OFF: Defines a bit mask that is used to turn off post-transition MODEL_STATES bits. The ``DEFAULT`` values corresponds with INTEGER maximum 2147483647, meaning all bits are turned off (contrast the ``refuse`` row, which preserves the fraud flagged bit).
* TO_MASK_ON: Defines a bit mask that is used to turn on post-transition MODEL_STATES bits. Note that this operation is applied after TO_MASK_OFF.
* TRANSITION_ROLE: Defines the database role that a database user must have to perform the transition.
* TRANSITION_QUORUM: Defines a quorum that must be met before the transition proceeds. Each different user that requests the transition counts as one vote. The default of ``1`` means that no quorum is needed.
* DESCRIPTION: A meaningful description of the transition.

###### Further metadata inserts for permitted state transitions
```
INSERT INTO state_transition
(
  object_type_id,
  transition_code,
  bitand_match_rule,
  from_mask,
  to_mask_off,
  to_mask_on,
  transition_role,
  transition_quorum,
  description
)
VALUES
  (99, 'expire', 'ALL', 16, 16, 32, 'INSURANCE_SERVICE', 1, 'Expire policy');

INSERT INTO state_transition
(
  object_type_id,
  transition_code,
  bitand_match_rule,
  from_mask,
  to_mask_off,
  to_mask_on,
  transition_role,
  transition_quorum,
  description
)
VALUES
  (99, 'flag', 'ANY', 0, 64, 0, 'FRAUD_SERVICE', 1, 'Flag'),
  (99, 'unflag', 'ANY', 0, 0, 64, 'FRAUD_SERVICE', 1, 'Unflag');
```

## Locking it down

The Insurance Division is part of a highly regulated industry. It is expected that the database is encrypted, and that SECADM is a separate user that is used to restrict all access to the database. Once the metadata has been set up, no users will be permitted to read or modify data, except using the modules provided.

The foregoing is a prerequisite, but also standard practice so not described here. This section focuses on how the database is then locked down even further, using the roles defined in the metadata.

### Create the database roles

As the SECADM user:

###### New roles
```
-- Object insert and reading roles
CREATE ROLE policy_creator;
CREATE ROLE policy_viewer;
CREATE ROLE json_viewer;

-- Transition roles
CREATE ROLE insurance_service;
CREATE ROLE standard_approver;
CREATE ROLE special_approver;
CREATE ROLE approver;
CREATE ROLE payments_service;
CREATE ROLE fraud_service;
```

### Assigning the roles to users

In the example, we assign the roles directly to individual users. In the real world, roles might be assigned via a trusted context restricting access to particular IP addresses and to encrypted connections.

As the SECADM user:

###### Roles grants
```
GRANT ROLE policy_creator TO USER insurance;
GRANT ROLE insurance_service TO USER insurance;
GRANT ROLE policy_viewer TO USER bill, USER mandy, USER sakshi, USER jane, USER jeremy;
GRANT ROLE standard_approver TO USER bill, USER mandy, USER sakshi;
GRANT ROLE special_approver TO USER jane;
GRANT ROLE approver TO ROLE standard_approver, ROLE special_approver;
GRANT ROLE payments_service TO USER payments;
GRANT ROLE fraud_service TO USER fraud;
GRANT ROLE json_viewer TO USER jeremy;
```

## A simple demonstration

In this section we show how an insurance policy is registered, then transitions between various states.

### Prerequisites

As the SECADM user, grant privileges to allow a test user (JEREMY) to mimic other users:

###### Grants to test user
```
GRANT SETSESSIONUSER ON USER insurance, USER payments, USER fraud TO USER jeremy;
GRANT SETSESSIONUSER ON USER bill, USER mandy, USER sakshi, USER jane TO USER jeremy;
```

As the SECADM user, grant privileges to allow a any user to execute module routines:

###### Test-only grants
```
GRANT EXECUTE ON MODULE model_info TO PUBLIC;
GRANT EXECUTE ON MODULE object_change TO PUBLIC;
GRANT EXECUTE ON MODULE object_info TO PUBLIC;
```
Although this is lazy (and definitely only for testing), it is not quite as dangerous as first appears. The additional role checks enforced within OBJECT_CHANGE routines mean that public users can query data, but not update it.

### Validation queries

The queries shown below will be used by user JEREMY to validate the result of each of the subsequent operations.

###### Validation query 1 (object information)
```
SET SESSION AUTHORIZATION jeremy;

SELECT
  object_id,
  object_type_id,
  CAST(object_ref AS CHAR(15)) as object_ref,
  creation_utc_ts,
  CAST(creation_db_user AS CHAR(15)) as creation_db_user,
  CAST(creation_client_user AS CHAR(15)) as creation_client_user,
  model_states,
  last_change_transition_id,
  CAST(object_info.object_json(object_id) AS VARCHAR(20)) AS object_json
FROM
  TABLE(object_info.get_object(object_info.object_id(99, '00030082')));
```

###### Validation query 2 (transition information)
```
SET SESSION AUTHORIZATION jeremy;

SELECT
  object_id,
  transition_id,
  is_quorate,
  from_states,
  to_states,
  transition_code,
  transition_utc_ts,
  CAST(transition_db_user AS CHAR(15)) as transition_db_user,
  CAST(transition_client_user AS CHAR(15)) as transition_client_user
FROM
  TABLE(object_info.get_object_transitions(object_info.object_id(99, '00030082'), NULL));
```

###### Validation query 3 (transition JSON)
```
SET SESSION AUTHORIZATION jeremy;

SELECT
  object_id,
  transition_id,
  CAST(object_info.transition_json(object_id, transition_id) AS VARCHAR(90)) AS transition_json
FROM
  TABLE(object_info.get_object_transitions(object_info.object_id(99, '00030082'), NULL));
```

### Creating a draft policy

The online insurance system allows customers to generate quotes for insurance and progress policy applications. After adding a draft quote to the insurance system database as a prospective policy, the system registers the policy number as a new Insurance Policy object for user ``webuser1234`` in the State Model database:

###### State change call
```
SET SESSION AUTHORIZATION insurance;

CALL object_change.add_object(99, '00030082', '{}', 'webuser1234', ?);
```

###### Output
```
  Value of output parameters
  --------------------------
  Parameter Name  : P_OBJECT_ID
  Parameter Value : 1
    
  Return Status = 0
```

###### Validation query output
```
-- Validation query 1 result

OBJECT_ID            OBJECT_TYPE_ID OBJECT_REF      CREATION_UTC_TS         CREATION_DB_USER CREATION_CLIENT_USER MODEL_STATES LAST_CHANGE_TRANSITION_ID OBJECT_JSON         
-------------------- -------------- --------------- ----------------------- ---------------- -------------------- ------------ ------------------------- --------------------
                   1             99 00030082        2025-06-22-06.53.13.672 INSURANCE        webuser1234                    81                         0 {}                  
    
  1 record(s) selected.

-- Validation query 2 result

OBJECT_ID            TRANSITION_ID        IS_QUORATE FROM_STATES TO_STATES   TRANSITION_CODE      TRANSITION_UTC_TS       TRANSITION_DB_USER TRANSITION_CLIENT_USER
-------------------- -------------------- ---------- ----------- ----------- -------------------- ----------------------- ------------------ ----------------------

  0 record(s) selected.
```

###### States decode query
```
SELECT *, POWER(2, bit_index) AS bit_value FROM TABLE(model_info.get_active_states(99, 81));
```

###### Output
```
MODEL_ID    BIT_INDEX STATE_CODE           BIT_VALUE  
----------- --------- -------------------- -----------
          1         0 draft                          1
          2         4 current                       16
          3         6 not flagged                   64

  3 record(s) selected.
```

### Submitting an application

Having previously created a draft policy for an online quote, insurance system user ``webuser1234`` decides to submit a policy application. The insurance system updates the status of the Insurance Policy object in the State Model database:

###### State change call
```
SET SESSION AUTHORIZATION insurance;

CALL object_change.apply_transition(object_info.object_id(99, '00030082'), 'submit', 'webuser1234', '{}', ?);
```

###### Output
```
  Value of output parameters
  --------------------------
  Parameter Name  : P_TRANSITION_ID
  Parameter Value : 21

  Return Status = 0
```

###### Validation query output
```
-- Validation query 1 result

OBJECT_ID            OBJECT_TYPE_ID OBJECT_REF      CREATION_UTC_TS         CREATION_DB_USER CREATION_CLIENT_USER MODEL_STATES LAST_CHANGE_TRANSITION_ID OBJECT_JSON         
-------------------- -------------- --------------- ----------------------- ---------------- -------------------- ------------ ------------------------- --------------------
                   1             99 00030082        2025-06-22-06.53.13.672 INSURANCE        webuser1234                    82                        21 {}                  

  1 record(s) selected.

-- Validation query 2 result

OBJECT_ID            TRANSITION_ID        IS_QUORATE FROM_STATES TO_STATES   TRANSITION_CODE      TRANSITION_UTC_TS       TRANSITION_DB_USER TRANSITION_CLIENT_USER
-------------------- -------------------- ---------- ----------- ----------- -------------------- ----------------------- ------------------ ----------------------
                   1                   21          1          81          82 submit               2025-06-22-06.59.19.362 INSURANCE          webuser1234           

  1 record(s) selected.
```

###### States decode query
```
SELECT *, POWER(2, bit_index) AS bit_value FROM TABLE(model_info.get_active_states(99, 82));
```

###### Output
```
MODEL_ID    BIT_INDEX STATE_CODE           BIT_VALUE  
----------- --------- -------------------- -----------
          1         1 submitted                      2
          2         4 current                       16
          3         6 not flagged                   64

  3 record(s) selected.
```

### Flagging possible fraud
The fraud team have systems that review policy applications for potential fraud. In the case of the newly submitted policy, a possible overvaluation is detected. The system determines to ``flag`` the policy:

###### State change call
```
SET SESSION AUTHORIZATION fraud;

CALL object_change.apply_transition(object_info.object_id(99, '00030082'), 'flag', NULL, '{"fraud-flag":{"concern":"valuation"}}', ?);
```

###### Output
```
  Value of output parameters
  --------------------------
  Parameter Name  : P_TRANSITION_ID
  Parameter Value : 22

  Return Status = 0
```

###### Validation query output
```
-- Validation query 1 result

OBJECT_ID            OBJECT_TYPE_ID OBJECT_REF      CREATION_UTC_TS         CREATION_DB_USER CREATION_CLIENT_USER MODEL_STATES LAST_CHANGE_TRANSITION_ID OBJECT_JSON         
-------------------- -------------- --------------- ----------------------- ---------------- -------------------- ------------ ------------------------- --------------------
                   1             99 00030082        2025-06-22-06.53.13.672 INSURANCE        webuser1234                    18                        22 {}                  

  1 record(s) selected.

-- Validation query 2 result

OBJECT_ID            TRANSITION_ID        IS_QUORATE FROM_STATES TO_STATES   TRANSITION_CODE      TRANSITION_UTC_TS       TRANSITION_DB_USER TRANSITION_CLIENT_USER
-------------------- -------------------- ---------- ----------- ----------- -------------------- ----------------------- ------------------ ----------------------
                   1                   21          1          81          82 submit               2025-06-22-06.59.19.362 INSURANCE          webuser1234           
                   1                   22          1          82          18 flag                 2025-06-22-07.00.59.804 FRAUD              -                     

  2 record(s) selected.

-- Validation query 3 result

OBJECT_ID            TRANSITION_ID        TRANSITION_JSON                                                                           
-------------------- -------------------- ------------------------------------------------------------------------------------------
                   1                   21 {}                                                                                        
                   1                   22 {"fraud-flag":{"concern":"valuation"}}                                                    

  2 record(s) selected.
```

###### States decode query
```
SELECT *, POWER(2, bit_index) AS bit_value FROM TABLE(model_info.get_active_states(99, 18));
```

###### Output
```
MODEL_ID    BIT_INDEX STATE_CODE           BIT_VALUE  
----------- --------- -------------------- -----------
          1         1 submitted                      2
          2         4 current                       16

  2 record(s) selected.
```

### Attempting to authorise the flagged policy

Staff member Bill reviews the submitted policy application. Unaware of the fraud flag, he decides to ``approve`` it:

###### State change call
```
SET SESSION AUTHORIZATION bill;

CALL object_change.apply_transition(object_info.object_id(99, '00030082'), 'approve', NULL, '{}', ?);
```

###### Output
```
SQL0438N  Application raised error or warning with diagnostic text: "Invalid 
transition from current state".  SQLSTATE=SM003
```

The transition rules we have defined mean that it is not possible to progress an application when the fraud flag is set. Our systems should handle this as gracefully as possible.

### Unflagging the policy

Further investigation determines that the previous fraud concerns were unwarranted. The fraud system can ``unflag`` the policy application:

###### State change call
```
SET SESSION AUTHORIZATION fraud;

CALL object_change.apply_transition(object_info.object_id(99, '00030082'), 'unflag', NULL, '{}', ?);
```

###### Output
```
  Value of output parameters
  --------------------------
  Parameter Name  : P_TRANSITION_ID
  Parameter Value : 23

  Return Status = 0
```

###### Validation query output
```
-- Validation query 1 result

OBJECT_ID            OBJECT_TYPE_ID OBJECT_REF      CREATION_UTC_TS         CREATION_DB_USER CREATION_CLIENT_USER MODEL_STATES LAST_CHANGE_TRANSITION_ID OBJECT_JSON         
-------------------- -------------- --------------- ----------------------- ---------------- -------------------- ------------ ------------------------- --------------------
                   1             99 00030082        2025-06-22-06.53.13.672 INSURANCE        webuser1234                    82                        23 {}                  

  1 record(s) selected.

-- Validation query 2 result

OBJECT_ID            TRANSITION_ID        IS_QUORATE FROM_STATES TO_STATES   TRANSITION_CODE      TRANSITION_UTC_TS       TRANSITION_DB_USER TRANSITION_CLIENT_USER
-------------------- -------------------- ---------- ----------- ----------- -------------------- ----------------------- ------------------ ----------------------
                   1                   21          1          81          82 submit               2025-06-22-06.59.19.362 INSURANCE          webuser1234           
                   1                   22          1          82          18 flag                 2025-06-22-07.00.59.804 FRAUD              -                     
                   1                   23          1          18          82 unflag               2025-06-22-07.04.30.123 FRAUD              -                     

  3 record(s) selected.
```

###### States decode query
```
SELECT *, POWER(2, bit_index) AS bit_value FROM TABLE(model_info.get_active_states(99, 82));
```

###### Output
```
MODEL_ID    BIT_INDEX STATE_CODE           BIT_VALUE  
----------- --------- -------------------- -----------
          1         1 submitted                      2
          2         4 current                       16
          3         6 not flagged                   64

  3 record(s) selected.
```

### Authorising the policy

Staff member Bill tries again to ``approve`` the policy:

###### State change call
```
SET SESSION AUTHORIZATION bill;

CALL object_change.apply_transition(object_info.object_id(99, '00030082'), 'approve', NULL, '{}', ?);
```

###### Output
```
  Value of output parameters
  --------------------------
  Parameter Name  : P_TRANSITION_ID
  Parameter Value : 24

  Return Status = 0
```

###### Validation query output
```
-- Validation query 1 result

OBJECT_ID            OBJECT_TYPE_ID OBJECT_REF      CREATION_UTC_TS         CREATION_DB_USER CREATION_CLIENT_USER MODEL_STATES LAST_CHANGE_TRANSITION_ID OBJECT_JSON         
-------------------- -------------- --------------- ----------------------- ---------------- -------------------- ------------ ------------------------- --------------------
                   1             99 00030082        2025-06-22-06.53.13.672 INSURANCE        webuser1234                    82                        23 {}                  

  1 record(s) selected.

-- Validation query 2 result

OBJECT_ID            TRANSITION_ID        IS_QUORATE FROM_STATES TO_STATES   TRANSITION_CODE      TRANSITION_UTC_TS       TRANSITION_DB_USER TRANSITION_CLIENT_USER
-------------------- -------------------- ---------- ----------- ----------- -------------------- ----------------------- ------------------ ----------------------
                   1                   21          1          81          82 submit               2025-06-22-06.59.19.362 INSURANCE          webuser1234           
                   1                   22          1          82          18 flag                 2025-06-22-07.00.59.804 FRAUD              -                     
                   1                   23          1          18          82 unflag               2025-06-22-07.04.30.123 FRAUD              -                     
                   1                   24          0          82          84 approve              2025-06-22-07.06.44.040 BILL               -                     

  4 record(s) selected.
```

Validation query 1 shows the state has still not changed. What happened?

You can see that validation query 2 shows a new object transition row, but the transition is not marked quorate. Because the ``approve`` transition was defined with a transition quorum 2, someone else also needs to approve the new policy. Consequently, the object model states have not changed. However,Bill's "vote" is recorded and counts towards the quorum.

Staff member Sakshi also decides to approve the submitted policy application:

###### State change call
```
SET SESSION AUTHORIZATION sakshi;

CALL object_change.apply_transition(object_info.object_id(99, '00030082'), 'approve', NULL, '{}', ?);
```

###### Output
```
  Value of output parameters
  --------------------------
  Parameter Name  : P_TRANSITION_ID
  Parameter Value : 25

  Return Status = 0
```

###### Validation query output
```
-- Validation query 1 result

OBJECT_ID            OBJECT_TYPE_ID OBJECT_REF      CREATION_UTC_TS         CREATION_DB_USER CREATION_CLIENT_USER MODEL_STATES LAST_CHANGE_TRANSITION_ID OBJECT_JSON         
-------------------- -------------- --------------- ----------------------- ---------------- -------------------- ------------ ------------------------- --------------------
                   1             99 00030082        2025-06-22-06.53.13.672 INSURANCE        webuser1234                    84                        25 {}                  

  1 record(s) selected.

-- Validation query 2 result

OBJECT_ID            TRANSITION_ID        IS_QUORATE FROM_STATES TO_STATES   TRANSITION_CODE      TRANSITION_UTC_TS       TRANSITION_DB_USER TRANSITION_CLIENT_USER
-------------------- -------------------- ---------- ----------- ----------- -------------------- ----------------------- ------------------ ----------------------
                   1                   21          1          81          82 submit               2025-06-22-06.59.19.362 INSURANCE          webuser1234           
                   1                   22          1          82          18 flag                 2025-06-22-07.00.59.804 FRAUD              -                     
                   1                   23          1          18          82 unflag               2025-06-22-07.04.30.123 FRAUD              -                     
                   1                   24          0          82          84 approve              2025-06-22-07.06.44.040 BILL               -                     
                   1                   25          1          82          84 approve              2025-06-22-07.08.52.058 SAKSHI             -                     

  5 record(s) selected.
```

###### States decode query
```
SELECT *, POWER(2, bit_index) AS bit_value FROM TABLE(model_info.get_active_states(99, 84));
```

###### Output
```
MODEL_ID    BIT_INDEX STATE_CODE           BIT_VALUE  
----------- --------- -------------------- -----------
          1         2 approved                       4
          2         4 current                       16
          3         6 not flagged                   64

  3 record(s) selected.
```

Validation query 2 shows another object transition row has been added, and that the transition is now quorate. The updated object model states are shown by validation query 1. The policy is now authorised. However, payment is needed before the policy is activated.

### Policy activation
The payments system processes the payment from the customer, allowing it to ``activate`` the policy:

###### State change call
```
SET SESSION AUTHORIZATION payments;

CALL object_change.apply_transition(object_info.object_id(99, '00030082'), 'activate', NULL, '{}', ?);
```

###### Output
```
  Value of output parameters
  --------------------------
  Parameter Name  : P_TRANSITION_ID
  Parameter Value : 26

  Return Status = 0
```

###### Validation query output
```
-- Validation query 1 result

OBJECT_ID            OBJECT_TYPE_ID OBJECT_REF      CREATION_UTC_TS         CREATION_DB_USER CREATION_CLIENT_USER MODEL_STATES LAST_CHANGE_TRANSITION_ID OBJECT_JSON         
-------------------- -------------- --------------- ----------------------- ---------------- -------------------- ------------ ------------------------- --------------------
                   1             99 00030082        2025-06-22-06.53.13.672 INSURANCE        webuser1234                    88                        26 {}                  

  1 record(s) selected.

-- Validation query 2 result

OBJECT_ID            TRANSITION_ID        IS_QUORATE FROM_STATES TO_STATES   TRANSITION_CODE      TRANSITION_UTC_TS       TRANSITION_DB_USER TRANSITION_CLIENT_USER
-------------------- -------------------- ---------- ----------- ----------- -------------------- ----------------------- ------------------ ----------------------
                   1                   21          1          81          82 submit               2025-06-22-06.59.19.362 INSURANCE          webuser1234           
                   1                   22          1          82          18 flag                 2025-06-22-07.00.59.804 FRAUD              -                     
                   1                   23          1          18          82 unflag               2025-06-22-07.04.30.123 FRAUD              -                     
                   1                   24          0          82          84 approve              2025-06-22-07.06.44.040 BILL               -                     
                   1                   25          1          82          84 approve              2025-06-22-07.08.52.058 SAKSHI             -                     
                   1                   26          1          84          88 activate             2025-06-22-07.10.15.075 PAYMENTS           -                     

  6 record(s) selected.
```

###### States decode query
```
SELECT *, POWER(2, bit_index) AS bit_value FROM TABLE(model_info.get_active_states(99, 88));
```

###### Output
```
MODEL_ID    BIT_INDEX STATE_CODE           BIT_VALUE  
----------- --------- -------------------- -----------
          1         3 active                         8
          2         4 current                       16
          3         6 not flagged                   64

  3 record(s) selected.
```

### Policy expiry

Years later (or minutes, since this is just testing), the customer decides not to pay for a policy renewal. The insurance system will then ``expire`` the policy:

###### State change call
```
SET SESSION AUTHORIZATION insurance;

CALL object_change.apply_transition(object_info.object_id(99, '00030082'), 'expire', NULL, '{}', ?);
```

###### Output
```
  Value of output parameters
  --------------------------
  Parameter Name  : P_TRANSITION_ID
  Parameter Value : 27

  Return Status = 0
```

###### Validation query output
```
-- Validation query 1 result

OBJECT_ID            OBJECT_TYPE_ID OBJECT_REF      CREATION_UTC_TS         CREATION_DB_USER CREATION_CLIENT_USER MODEL_STATES LAST_CHANGE_TRANSITION_ID OBJECT_JSON         
-------------------- -------------- --------------- ----------------------- ---------------- -------------------- ------------ ------------------------- --------------------
                   1             99 00030082        2025-06-22-06.53.13.672 INSURANCE        webuser1234                   104                        27 {}                  
    
  1 record(s) selected.

-- Validation query 2 result

OBJECT_ID            TRANSITION_ID        IS_QUORATE FROM_STATES TO_STATES   TRANSITION_CODE      TRANSITION_UTC_TS       TRANSITION_DB_USER TRANSITION_CLIENT_USER
-------------------- -------------------- ---------- ----------- ----------- -------------------- ----------------------- ------------------ ----------------------
                   1                   21          1          81          82 submit               2025-06-22-06.59.19.362 INSURANCE          webuser1234           
                   1                   22          1          82          18 flag                 2025-06-22-07.00.59.804 FRAUD              -                     
                   1                   23          1          18          82 unflag               2025-06-22-07.04.30.123 FRAUD              -                     
                   1                   24          0          82          84 approve              2025-06-22-07.06.44.040 BILL               -                     
                   1                   25          1          82          84 approve              2025-06-22-07.08.52.058 SAKSHI             -                     
                   1                   26          1          84          88 activate             2025-06-22-07.10.15.075 PAYMENTS           -                     
                   1                   27          1          88         104 expire               2025-06-22-07.11.41.435 INSURANCE          -                     
    
  7 record(s) selected.
```

###### States decode query
```
SELECT *, POWER(2, bit_index) AS bit_value FROM TABLE(model_info.get_active_states(99, 104));
```

###### Output
```
MODEL_ID    BIT_INDEX STATE_CODE           BIT_VALUE  
----------- --------- -------------------- -----------
          1         3 active                         8
          2         5 expired                       32
          3         6 not flagged                   64

  3 record(s) selected.
```

You can see that the expiry transition has preserved other model states. For example, we can still see that this was an active policy that expired, not a draft one, and that it was not fraud flagged.

## See also

* [Subscription Example](SUBSCRIPTION_EXAMPLE.md)
* [Overview](../README.md)
