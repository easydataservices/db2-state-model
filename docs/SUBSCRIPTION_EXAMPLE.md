# Subscription Example

We can extend the previous See [Insurance Policy Example](EXAMPLE.md) with a demonstration of subscription functionality.

## Subscriptions

A subscription allows a process to retrieve details of state transitions for a specified object type. Optionally the subscription can be restricted to transitions for a particular transition code; otherwise all transitions are returned.

## Metadata setup

We define a subscription by adding a row to the SUBSCRIPTION table. SUBSCRIPTION_ID is the primary key.
```
INSERT INTO subscription(subscription_id, object_type_id, transition_code, subscription_role, max_result_rows)
VALUES
  (101, 99, NULL, 'INSURANCE_SUBSCRIBER', 5);
```

The purpose of each of the columns in the table:
* SUBSCRIPTION_ID ``99``: Unique identifier for the subscription.
* OBJECT_TYPE_ID ``99``: Identifies the object type to which the subscription relates.
* TRANSITION_CODE ``NULL``: Limits of the subscription to a particular transition code. If NULL then all transitions for the object type are returned.
* SUBSCRIPTION_ROLE ``INSURANCE_SUBSCRIBER``: Role permitting use of the subscription by the subscriber.
* MAX_RESULT_ROWS: Maximum number of rows returned by a single GET_TRANSITIONS call. Default ``500``.
* BACKTRACK_LIMIT_MINUTES: Maximum duration that uncommitted transitions are tracked. Default ``1440`` (24 hours).
* LAST_TRANSITION_ID: Last returned transition processed by the subscriber. Default ``0``.

## Locking it down

The new insurance subscriber subscription is already locked down. To use it, the application user will need the ``INSURANCE_SUBSCRIBER`` role defined when we defined the subscription.

### Create the database role

As the SECADM user:

```
CREATE ROLE insurance_subscriber;
```

### Assigning the role to a user

The subscription user controls subscription processing. It generally only makes sense for a single user to be assigned the role.

In this example we grant the role to user SUBSCRIBER;

As the SECADM user:

###### Roles grants
```
GRANT ROLE insurance_subscriber TO USER subscriber;
```

## A simple demonstration

### Prerequisites

As the SECADM user, grant privileges to allow a test user (JEREMY) to mimic other users:

###### Grants to test user

```
GRANT SETSESSIONUSER ON USER subscriber TO USER jeremy;
```

###### Test-only grants

```
GRANT EXECUTE ON MODULE subscription TO PUBLIC;
```

### Using SUBSCRIPTION.GET_TRANSITIONS to retrieve subscription data

Table function SUBSCRIPTION.GET_TRANSITIONS is called to retrieve subscription data:
```
SET SESSION AUTHORIZATION subscriber;

SELECT
  CAST(transition_id AS INTEGER) AS transition_id,
  object_type_id,
  CAST(transition_code AS VARCHAR(15)) as transition_code,
  CAST(object_id AS INTEGER) AS object_id,
  CAST(object_ref AS VARCHAR(10)) AS object_ref,
  from_states,
  to_states,
  transition_utc_ts,
  CAST(transition_db_user AS VARCHAR(19)) AS transition_db_user,
  CAST(transition_client_user AS VARCHAR(21)) AS transition_client_user
FROM
  TABLE(subscription.get_transitions(101));
```

###### Example query output
```
TRANSITION_ID OBJECT_TYPE_ID TRANSITION_CODE OBJECT_ID   OBJECT_REF FROM_STATES TO_STATES   TRANSITION_UTC_TS       TRANSITION_DB_USER    TRANSITION_CLIENT_USER
------------- -------------- --------------- ----------- ---------- ----------- ----------- ----------------------- --------------------- ----------------------
            1             99 _INIT                     1 00030082             0          81 2025-07-06-12.09.36.761 INSURANCE             webuser1234
            2             99 submit                    1 00030082            81          82 2025-07-06-12.11.30.802 INSURANCE             webuser1234
            3             99 flag                      1 00030082            82          18 2025-07-06-12.12.39.962 FRAUD                 -
            4             99 unflag                    1 00030082            18          82 2025-07-06-12.14.12.015 FRAUD                 -
            6             99 approve                   1 00030082            82          84 2025-07-06-12.15.06.780 SAKSHI                -

  5 record(s) selected.
```

Note that unlike function GET_OBJECT_TRANSITIONS in module OBJECT_INFO, the system ``_INIT`` transition is returned. This sets initial model states for an object, which is a proxy for object creation.

Note also that only the first 5 transitions are returned. This is because we set a limit of five when we defined the subscription.

### Acknowledging processed subscription rows

In order for the subscriber to retrieve further rows, it first needs to acknowledge transitions already processed.

For example, suppose that the subscriber has retrieved and processed the first three rows from the above result set. It can acknowledge this with the following stored procedure call:
```
CALL subscription.set_last_transition(101, 3);
```

(Note that ``3`` is the last processed transition id, not the number of rows processed.)

Repeating our query, table function SUBSCRIPTION.GET_TRANSITIONS now returns:

###### Example query output
```
TRANSITION_ID OBJECT_TYPE_ID TRANSITION_CODE OBJECT_ID   OBJECT_REF FROM_STATES TO_STATES   TRANSITION_UTC_TS       TRANSITION_DB_USER    TRANSITION_CLIENT_USER
------------- -------------- --------------- ----------- ---------- ----------- ----------- ----------------------- --------------------- ----------------------
            4             99 unflag                    1 00030082            18          82 2025-07-06-12.14.12.015 FRAUD                 -
            6             99 approve                   1 00030082            82          84 2025-07-06-12.15.06.780 SAKSHI                -
            7             99 activate                  1 00030082            84          88 2025-07-06-12.15.23.656 PAYMENTS              -
            8             99 expire                    1 00030082            88         104 2025-07-06-12.16.02.070 INSURANCE             -

  4 record(s) selected.
```

To acknowledge those four rows:
```
CALL subscription.set_last_transition(101, 8);
```

No further rows are then returned by the query.

## Further reading

The preceding demonstrates the basics of subscription functionality with enough detail for most users. Behind the scenes however, the solution must handle more complex scenarios of missing and uncommitted data. For details of that, see [Subscription Advanced Example](SUBSCRIPTION_ADVANCED_EXAMPLE.md).

## See also

* [Subscription Advanced Example](SUBSCRIPTION_ADVANCED_EXAMPLE.md)
* [Insurance Policy Example](EXAMPLE.md)
* [Overview](../README.md)