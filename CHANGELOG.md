# 0.0.32 / 2013-08-12

* Fixed sentry app id

# 0.0.31 / 2013-08-12

* Fixes service-client request tracking

# 0.0.30 / 2013-08-12

* Adds getsentry.com exception tracking
* Adds request id tracking
* Updates client dependencies

# 0.0.29 / 2013-08-07

* Adds a special ping endpoint that calls NEO4J to monitor failures there

# 0.0.28 / 2013-07-02

* :gift: :birthday: BIRTHDAY RELEASE :birthday: :tada:
* Adds relationships and node types for turnbased matches

# 0.0.27 / 2013-04-17

* Adds caching auth-client

# 0.0.26 / 2013-04-02

* Adds authorization

# 0.0.25

* Transforms empty responses to JSON objects instead of empty strings
* Upgrades auth-backend

# 0.0.24

* Updates grape and neography

# 0.0.23

* Fixes problems with modifying roles on entities with a lot of relations

# 0.0.22

* Updates grape

# 0.0.21

* Updates JSON to 1.7.7

# 0.0.20

* Fixed a regression that occurred with the Neo4J/neography update

# 0.0.19

* Improves the Node#add_role performance a lot
* Makes return value of #add_role / #remove_role way simpler

# 0.0.18 !DOES NOT EXIST!

# 0.0.17

* Improve Newrelic instrumenting

# 0.0.16

* Adds Newrelic monitoring and ping middleware

# 0.0.15

* Fixes bug that deleted relationship's meta data instead of updating it

# 0.0.14

* Improves the response status codes for creating new relationships

# 0.0.13

* Adds the query API

# 0.0.12

* Adds a first version of a relationship metadata concept

# 0.0.11

* Eases the dependency on grape

# 0.0.10

* Adds friends relationship and player role

# 0.0.9

* Relaxes dependency on auth-client

# 0.0.8

* Adds private gemserver as a gem source

# 0.0.7

* ``OPTIONS`` requests do not need to be authenticated anymore

# 0.0.6

* Secures all requests with OAuth2

# 0.0.5

* Adds thin to the main bundle to run on Heroku

# 0.0.4

  * Deals with/Prevents relationship duplicates
  * A lot of improvements related to ``metaserver``

# 0.0.3

* Adds a direction parameter to queries for related entities
* Adds an endpoint to remove an entity with all of it's relations

# 0.0.2

* Adds a relationship validation mechanism

# 0.0.1

The start.
