# graph-backend

A backend to store relations between entities.

## API


The graph must be accessed by HTTPS.

### Create a new relation

#### Request

**POST** ``/:relation-name:/:UUID-SOURCE:/:UUID-TARGET:``

##### Parameters

- **relation-type** [URL] [REQUIRED]: name of the relation type (see [relation types](#relation-types))
- **UUID-SOURCE** [URL] [REQUIRED]: The UUID of the entity the data set should be created for
- **UUID-TARGET** [URL] [REQUIRED]: The UUID of the entity the data set should be created for

##### Body
Empty.

#### Response

##### Body

Empty.

… tbc