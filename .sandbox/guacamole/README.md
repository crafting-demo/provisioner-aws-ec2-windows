# Web RDP using guacamole

This folder contains database initialization script.
The sandbox template uses a prepared database snapshot which
can be created using the following command (with an empty MySQL).

The definition of the depenency:

```yaml
dependencies:
  - name: guacamoledb
    service_type: mysql
    properties:
      database: guacamole
      password: guacamole
      username: guacamole
```

To initialize the database:

```sh
mysql -h guacamoledb --user=guacamole --password=guacamole guacamole <initdb.sql
```

Then take a snapshot:

```sh
cs snapshot create -W guacamoledb guacamoledb-r1
```

Then update the definition of the dependency to use:

```yaml
dependencies:
  - name: guacamoledb
    service_type: mysql
    properties:
      database: guacamole
      password: guacamole
      username: guacamole
    snapshot: guacamoledb-r1
```
