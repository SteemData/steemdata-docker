# steemdata-docker
A Docker-Compose based deployment to bring up the SteemData DB stack.


# Todo
- Create a bash script to pull all the required SteemData repositories locally.
- Remove dependence on dockerhub, and build images locally instead
- Keep persistent volumes for mongodb
- Automate setup of mongodb admin/readonly users when mongodb starts
- Convert this docker-cloud stack into regular docker-compose stack

docker-cloud.yml
```
api:
  autoredeploy: true
  environment:
    - FLASK_HOST=0.0.0.0
    - 'MONGO_URL=mongodb://steemit:steemit@mongo1.steemdata.com:27017/SteemData'
    - PRODUCTION=true
    - 'ROOT_URL=http://api.steemdata.com/'
    - VIRTUAL_HOST=api.steemdata.com
    - VIRTUAL_PORT=5000
  expose:
    - '5000'
  image: 'furion/steemdata-api:latest'
  restart: always
  tags:
    - steemdata
celery-worker:
  autoredeploy: true
  command: celery worker -A tasks  -l info -c 1 -P solo
  environment:
    - 'CELERY_BACKEND_URL=redis://:not_real_redis_password@redis'
    - 'CELERY_BROKER_URL=redis://:not_real_redis_password@redis'
    - 'DB_HOST=server:not_real_mongodb_password@mongodb'
    - DB_NAME=SteemData
    - DB_PORT=27017
  image: 'furion/steemdata-mongo:latest'
  links:
    - mongodb
    - redis
  mem_limit: 1094m
  restart: always
  sequential_deployment: true
  tags:
    - steemdata
  target_num_containers: 10
mongodb:
  command: 'mongod --auth --storageEngine wiredTiger --wiredTigerEngineConfigString="cache_size=30GB"'
  image: 'mongo:latest'
  mem_limit: 33000m
  ports:
    - '27017:27017'
    - '28017:28017'
  privileged: true
  restart: always
  tags:
    - steemdata
  volumes:
    - '/mongo:/data/db'
    - '/mongo-backup:/mongo-backup'
nginx:
  image: 'jwilder/nginx-proxy:latest'
  ports:
    - '80:80'
  roles:
    - global
  tags:
    - steemdata
  volumes:
    - '/var/run/docker.sock:/tmp/docker.sock:ro'
redis:
  command: redis-server --requirepass not_real_redis_password
  environment:
    - REDIS_PASSWORD=not_real_redis_password
  image: 'redis:alpine'
  ports:
    - '6379:6379'
  restart: always
  tags:
    - steemdata
  tty: true
web:
  autoredeploy: true
  environment:
    - 'MONGO_URL=mongodb://steemit:steemit@mongo1.steemdata.com:27017/SteemData'
    - 'ROOT_URL=http://steemdata.com/'
    - VIRTUAL_HOST=steemdata.com
  expose:
    - '3000'
  image: 'furion/steemdata.com:latest'
  restart: always
  tags:
    - steemdata
webapi:
  autoredeploy: true
  environment:
    - FLASK_HOST=0.0.0.0
    - 'MONGO_URL=mongodb://steemit:steemit@mongo1.steemdata.com:27017/SteemData'
    - PRODUCTION=true
    - 'ROOT_URL=http://webapi.steemdata.com/'
    - VIRTUAL_HOST=webapi.steemdata.com
  expose:
    - '5000'
  image: 'furion/steemdata-webapi:latest'
  restart: always
  tags:
    - steemdata
worker-refresh-dbstats:
  autoredeploy: true
  command: python __main__.py -w refresh_dbstats
  environment:
    - 'CELERY_BACKEND_URL=redis://:not_real_redis_password@redis'
    - 'CELERY_BROKER_URL=redis://:not_real_redis_password@redis'
    - 'DB_HOST=server:not_real_mongodb_password@mongodb'
    - DB_NAME=SteemData
    - DB_PORT=27017
  image: 'furion/steemdata-mongo:latest'
  links:
    - mongodb
  mem_limit: 512m
  restart: always
  tags:
    - steemdata
worker-scrape-all-users:
  autoredeploy: true
  command: python __main__.py -w scrape_all_users
  environment:
    - 'CELERY_BACKEND_URL=redis://:not_real_redis_password@redis'
    - 'CELERY_BROKER_URL=redis://:not_real_redis_password@redis'
    - 'DB_HOST=server:not_real_mongodb_password@mongodb'
    - DB_NAME=SteemData
    - DB_PORT=27017
  image: 'furion/steemdata-mongo:latest'
  links:
    - mongodb
  mem_limit: 512m
  restart: always
  tags:
    - steemdata
worker-scrape-operations:
  autoredeploy: true
  command: python __main__.py -w scrape_operations
  environment:
    - 'CELERY_BACKEND_URL=redis://:not_real_redis_password@redis'
    - 'CELERY_BROKER_URL=redis://:not_real_redis_password@redis'
    - 'DB_HOST=server:not_real_mongodb_password@mongodb'
    - DB_NAME=SteemData
    - DB_PORT=27017
  image: 'furion/steemdata-mongo:latest'
  mem_limit: 1024m
  restart: always
  tags:
    - steemdata
worker-scrape-prices:
  autoredeploy: true
  command: python __main__.py -w scrape_prices
  environment:
    - 'CELERY_BACKEND_URL=redis://:not_real_redis_password@redis'
    - 'CELERY_BROKER_URL=redis://:not_real_redis_password@redis'
    - 'DB_HOST=server:not_real_mongodb_password@mongodb'
    - DB_NAME=SteemData
    - DB_PORT=27017
  image: 'furion/steemdata-mongo:latest'
  links:
    - mongodb
  mem_limit: 512m
  restart: always
  tags:
    - steemdata
worker-validate-operations:
  command: python __main__.py -w validate_operations
  environment:
    - 'CELERY_BACKEND_URL=redis://:not_real_redis_password@redis'
    - 'CELERY_BROKER_URL=redis://:not_real_redis_password@redis'
    - 'DB_HOST=server:not_real_mongodb_password@mongodb'
    - DB_NAME=SteemData
    - DB_PORT=27017
  image: 'furion/steemdata-mongo:latest'
  links:
    - mongodb
  mem_limit: 512m
  restart: always
  tags:
    - steemdata

```


MongoDB Create User script:
```
use admin
db.createUser({
    user: "admin",
    pwd: "super_strong_password_here",
    roles: [{role: "userAdminAnyDatabase", db: "admin"}]
});

db.createUser({
    user: "root",
    pwd: "super_strong_password_here",
    roles: [{role: "root", db: "admin"}]
});

// worker accessible database
use SteemData
db.createUser({
        user: "server",
        pwd: "not_a_real_mongodb_password",
        roles: ["readWrite", "dbAdmin"]
    }
);

// public database (read-only)
db.createUser({
    "user": "steemit",
    "pwd": "steemit",
    "roles": ["read"]
});
```
