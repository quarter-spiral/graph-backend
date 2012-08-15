# graph-backend

A backend to store relations between entities.

## Setup

### Prerequisites

Make sure you have the following installed:

* neo4j

## API

The graph must be accessed by HTTPS.

### Create a new relationship

#### Request

**POST** ``/entities/:UUID-SOURCE:/:RELATION-NAME:/:UUID-TARGET:``

##### Parameters

- **UUID-SOURCE** [REQUIRED]: The UUID of the source entity for the relationship
- **RELATION-NAME** [REQUIRED]: Name of the relation type (see [relation names](#relation-names))
- **UUID-TARGET** [REQUIRED]: The UUID of the target entity of the relationship

##### Body
JSON encoded options hash.

- **direction**: Direction of the relation. Possible values: ``both``
  (source relates to targte and target relates to source),
  ``incoming`` (target relates to source) and ``outgoing`` (source
relates to target)

#### Response

##### Body

Empty.

#### Example

The relationship: ``Peter plays Chess`` would be created as a ``POST`` to: ``/entities/peter/plays/chess`` with the body ``{"direction": "outgoing"}``.

### Check for an existing relationship

#### Request

**GET** ``/entities/:UUID-SOURCE:/:RELATION-NAME:/:UUID-TARGET:``

##### Parameters

- **UUID-SOURCE** [REQUIRED]: The UUID of the source entity for the relationship
- **RELATION-NAME** [REQUIRED]: Name of the relation type (see [relation names](#relation-names))
- **UUID-TARGET** [REQUIRED]: The UUID of the target entity of the relationship

##### Body

Empty.

#### Response

HTTP status code 200 if the relation exists. HTTP status code 404 if not.

##### Body

Empty.

#### Example

To find out if ``Peter plays chess`` send a ``GET`` to: ``/entities/peter/plays/chess``. If he does, it would return HTTP status code 200 otherwise status code 404.


### Delete an existing relationship

#### Request

**DELETE** ``/entities/:UUID-SOURCE:/:RELATION-NAME:/:UUID-TARGET:``

##### Parameters

- **UUID-SOURCE** [REQUIRED]: The UUID of the source entity for the relationship
- **RELATION-NAME** [REQUIRED]: Name of the relation type (see [relation names](#relation-names))
- **UUID-TARGET** [REQUIRED]: The UUID of the target entity of the relationship

##### Body

Empty.

#### Response

##### Body

Empty.

#### Example

If ``Peter stops playing chess`` send a ``DELETE`` to: ``/entities/peter/plays/chess``.

### List related entities

#### Request

**GET** ``/entities/:UUID-SOURCE:/:RELATION-NAME:``

##### Parameters

- **UUID-SOURCE** [REQUIRED]: The UUID of the source entity for the relationship
- **RELATION-NAME** [REQUIRED]: Name of the relation type (see [relation names](#relation-names))

##### Body

Empty.

#### Response

##### Body

A JSON encoded array of UUIDs of the related entities.

#### Example

To find out ``What is Peter playing`` send a ``GET`` to:
``/entities/peter/plays``.

The response might be: ``["chess", "mahjong"]``.

### Add role to an entity

**POST** ``/entities/:UUID-SOURCE:/roles/:ROLE-NAME:``

##### Parameters

- **UUID-SOURCE** [REQUIRED]: The UUID of the source entity for the relationship
- **ROLE-NAME** [REQUIRED]: Name of the role to add (see [roles](#roles))

##### Body

Empty.

#### Response

##### Body

Empty.

#### Example

To ``make Peter a developer`` send a ``GET`` to: ``/entities/peter/roles/developer``.

### Remove a role from an entity

**DELETE** ``/entities/:UUID-SOURCE:/roles/:ROLE-NAME:``

##### Parameters

- **UUID-SOURCE** [REQUIRED]: The UUID of the source entity for the relationship
- **ROLE-NAME** [REQUIRED]: Name of the role to add (see [roles](#roles))

##### Body

Empty.

#### Response

##### Body

Empty.

#### Example

To ``revoke the developer role from Peter`` send a ``DELETE`` to: ``/entities/peter/roles/developer``.

### List all entities which have a role

**GET** ``/roles/:ROLE-NAME:``

##### Parameters

- **ROLE-NAME** [REQUIRED]: Name of the role to add (see [roles](#roles))

##### Body

Empty.

#### Response

##### Body

A JSON encoded array of UUIDs of entities with that role.

#### Example

To ``find all developers`` send a ``GET`` to ``/roles/developer``.

The response might be: ``["dev-1", "dev-2"]``

## Relation names

The supported relations are:

+--------------+---------------------+--------------------------------------------+
| **develops** | Developer of a game | Jumping Sun Studios develops Sun Jumper IV |
+--------------+---------------------+--------------------------------------------+

## Roles

Every entity has a set of roles that define the node. Currently
available roles are:

+-----------+--------------------+
| developer | Developer of games |
+-----------+--------------------+
| game      | A game             |
+-----------+--------------------+
