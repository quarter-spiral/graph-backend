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
- **meta**: An object with meta information on this relationship. When used on an already existing relationship this will update the existing meta information and only overwrite keys that are present in this request. All existing meta keys that are not present in this request will remain untouched.

#### Response

Will return status code 201 when created and 304 if the relation exists
already. If the relation exists but meta data was updated status code
200 is returned instead.

##### Body

JSON encoded array of objects which contains the new meta information (the array contains 2 elements if you create a relationship in ``both`` directions):

```javascript
[
  {
    "source": "peter",
    "target": "chess",
    "relation: "plays",
    "meta": {
      "location": "Paris"
    }
  }
]
```

#### Example

The relationship: ``Peter plays Chess`` would be created as a ``POST`` to: ``/entities/peter/plays/chess`` with the body ``{"direction": "outgoing"}``.

The relationship: ``Peter plays Chess in Paris`` could be created as a ``POST`` to: ``/entities/peter/plays/chess`` with the body ``{"direction": "outgoing", "meta": {"location": "Paris"}``.

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

JSON encoded object of the form:

```javascript
{
  "source": "peter",
  "target": "chess",
  "relation: "plays",
  "meta": {
    "location": "Paris"
  }
}
```

#### Example

To find out if ``Peter plays chess`` send a ``GET`` to: ``/entities/peter/plays/chess``. If he does, it would return HTTP status code 200 otherwise status code 404.

### Change metadata of an existing relationship

#### Request

**PUT** ``/entities/:UUID-SOURCE:/:RELATION-NAME:/:UUID-TARGET:``

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
- **meta**: An object with meta information on this relationship. This object overwrites any existing meta information.

#### Response

HTTP status code 200 if the relation exists. HTTP status code 404 if not.

##### Body

JSON encoded array of objects which contains the new meta information (might be 2 elements when changing a relationship in ``both``directions):

```javascript
[
  {
    "source": "peter",
    "target": "chess",
    "relation": "plays",
    "meta": {
      "location": "Rome"
    }
  }
]
```

#### Example

To change Peter's location where plays chess from Paris to Rome ``PUT`` to: ``/entities/peter/plays/chess`` with the body ``{"direction": "outgoing", "meta": {"location": "Rome"}``.

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

JSON encoded options hash.

- **direction** [OPTIONAL]: Direction of the related entities. Possible values: ``both``
  (entities relating to the given UUID and entities the given UUID is relating to), ``incoming`` (entities relating to the given UUID) and ``outgoing`` (default) (entities the given UUID is relating to).

#### Response

##### Body

A JSON encoded object of the related entities:

```javascript
[
  {
    "source": "peter",
    "target": "chess",
    "relation: "plays",
    "meta": {
      "location": "Paris"
    }
  },
  {
    "source": "peter",
    "target": "poker",
    "relation: "plays",
    "meta": {
    }
  }
]
```

#### Example

To find out ``What is Peter playing`` send a ``GET`` to:
``/entities/peter/plays``.

The response might be: ``["chess", "mahjong"]``.

To find out ``Who is playing chess`` send a ``GET`` to:
``/entities/chess/plays?direction=incoming``.

The response might be: ``["peter"]``.

### Issue advanced queries to the graph

The used query language is Neo4J's [Cypher](http://docs.neo4j.org/chunked/milestone/cypher-query-lang.html). In order to make life a little bit easier the backend is already setting the ``START`` of the query to a node determined by the UUIDs specified.

#### Request

**GET** to ``/query/:UUID-SOURCE-1:/:UUID-SOURCE-2:/…``

##### Parameters

- **UUID-SOURCE-N** [REQUIRED]: The UUID of an entity the query is relating to

##### Body

JSON encoded object.

###### Options

* **query**: Contains the *Cypher* query starting with the ``WHERE`` part. The ``START`` is already filled out by the backend in this way: ``START node1 = the_node_with_the_given_uuid_1, node2 = the_node_with_the_given_uuid_2``

#### Response

An JSON encoded array of arrays of whatever you have returned in the Cypher query.

*Hint*: It's very likely that you want to return single UUIDs.

#### Examples

Assuming that **my** user has the UUID ``12345`` and plays a game with the UUID ``67890``.

##### Games that my friends play

**GET** to ``/query/12345`` with the body:

```javascript
"query": "MATCH node0-[:friends]->friend-[:plays]->game RETURN game.uuid"
```

##### My friends who play that game, too, on Facebook
**GET** to ``/query/12345/67890`` with the body:

```javascript
"query": "MATCH node0-[:friends]->friend-[p:plays]->game WHERE game  = node1 AND p.venueFacebook! = true RETURN DISTINCT friend.uuid"
```

##### Developers of games my friends play on Facebook
**GET** to ``/query/12345`` with the body:

```javascript
"query" => "MATCH node1-[:friends]->()->[:plays]->()<-[:develops]->developer RETURN developer"
```

### Remove an entity and all it's relations from the graph

#### Request

**DELETE** ``/entities/:UUID-SOURCE:``

##### Parameters

- **UUID-SOURCE** [REQUIRED]: The UUID of the entity to delete

##### Body

Empty.

#### Response

##### Body

Empty.

#### Example

To ``Remove the game chess and all connections to it's players`` send a
``DELETE`` to: ``/entities/chess``.

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

### List all roles of an entity

**GET** ``/entities/:UUID-SOURCE:/roles``

##### Parameters

- **UUID-SOURCE** [REQUIRED]: The UUID of the entity you want to look up the roles for

##### Body

Empty.

#### Response

##### Body

A JSON encoded array of roles for that entity.

#### Example

To ``find what roles Peter has`` send a ``GET`` to
``/entities/peter/roles``.

The response might be: ``["developer"]``

## Relation names

The supported relations are:

| Name                | Description          | Example                                    |
|---------------------|----------------------|--------------------------------------------|
| **develops**        | Developer of a game  | Jumping Sun Studios develops Sun Jumper IV |
| **friends**         | A friend of a player | Pete friends Kate                          |
| **plays**           | A player of a game   | Pete plays chess                           |
| **is_a_match_of**   | A match of a game    | Match #527 is a game of chess              |
| **participates_in** | A player in a match  | Pete participates in match #527            |

## Roles

Every entity has a set of roles that define the node. Currently
available roles are:

| Name            | Description        |
|-----------------|--------------------|
| developer       | Developer of games |
| game            | A game             |
| player          | A player           |
| turnbased-match | A match            |
