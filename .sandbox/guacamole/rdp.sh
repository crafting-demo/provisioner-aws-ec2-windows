#!/bin/bash

function run_mysql() {
    mysql -h guacamoledb --user=guacamole --password=guacamole guacamole "$@"
}

function resource_output() {
    jq -cMr ".$1.value" </run/sandbox/fs/resources/windows/state 2>/dev/null || true
}

function wait_for_resource() {
    while true ; do
        [[ -z "$(resource_output public_dns)" ]] || return 0
        sleep 1
    done
}

set -ex

echo "Waiting for guacamoledb"
cs wait service guacamoledb
echo "Waiting for resource: windows"
wait_for_resource

echo "Inject sandbox owner: $SANDBOX_OWNER_EMAIL"
run_mysql <<EOS
INSERT IGNORE INTO guacamole_entity (name,type) VALUES ('$SANDBOX_OWNER_EMAIL', 'USER');
INSERT IGNORE INTO guacamole_user (entity_id, password_hash, password_date)
    SELECT entity_id, '', NOW() FROM guacamole_entity WHERE name = '$SANDBOX_OWNER_EMAIL';
INSERT INTO guacamole_connection (connection_id,connection_name,protocol) VALUES (1,'windows','rdp')
    ON DUPLICATE KEY UPDATE protocol = 'rdp';
REPLACE INTO guacamole_connection_parameter (connection_id,parameter_name,parameter_value) VALUES
    (1,'username','Administrator'),
    (1,'ignore-cert','true'),
    (1,'hostname','$(resource_output public_dns)'),
    (1,'password','$(resource_output password)'),
    (1,'enable-drive','true'),
    (1,'drive-name','sandbox'),
    (1,'drive-path','/drive');
REPLACE INTO guacamole_connection_permission (entity_id,connection_id,permission)
    SELECT entity_id,1,'READ' FROM guacamole_entity WHERE name = '$SANDBOX_OWNER_EMAIL';
EOS

docker rm guacamole -f >/dev/null 2>&1 || true
exec docker run -a STDOUT -a STDERR --name guacamole --rm \
    --link guacd:guacd \
    -e MYSQL_HOSTNAME=guacamoledb \
    -e MYSQL_DATABASE=guacamole \
    -e MYSQL_USER=guacamole \
    -e MYSQL_PASSWORD=guacamole \
    -e MYSQL_AUTO_CREATE_ACCOUNTS=true \
    -e HEADER_ENABLED=true \
    -e HTTP_AUTH_HEADER=X-Crafting-User \
    -p 8080:8080 \
    guacamole/guacamole:1.4.0