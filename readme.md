# Docker PHP MySQL phpMyAdmin
Docker configuration for running PHP application with MySQL (MySQLi/PDO) and phpMyAdmin.

## Clone
```
git clone https://github.com/agragregra/docker-php . && rm -rf trunk .git readme.md && chmod +x run.sh
```

## Features
- **PHP**: Stable PHP version.
- **MySQL**: Stable MySQL/MariaDB version.
- **DB**: MySQLi & PDO.
- **phpMyAdmin**: Stable version.
- **Composer**.

## Server
  - app: www
  - public: www/public_html
  - http: http://localhost:8000
  - https: https://localhost:8443
  - phpMyAdmin: http://localhost:8080 (root:root & user:user)

## Service

* ./run.sh args
```
Usage: ./run.sh { backup | bash | clear | deploy | down | prune | up }
```

* docker up / down:
```
# first
sudo chmod -R 777 . && docker compose up -d

docker compose up -d
docker compose down
```

* internal bash:
```
docker compose exec web bash
exit
```

* import db
```
# mariadb
docker compose exec -T db mariadb -u root -proot example < backup.sql

# mysql
docker compose exec -T db mysql -u root -proot example < backup.sql
```

* export db
```
# mariadb
docker compose exec db mariadb-dump -u root -proot example > backup.sql

# mysql
docker compose exec db mysqldump -u root -proot example > backup.sql
```

* remove all images & volumes:
```
docker system prune -af --volumes
```

## Troubleshooting
```
chmod -R 777 .
linux: sed -i 's/\r$//' run.sh
macos: sed -i '' 's/\r$//' run.sh
docker pull php:8.2-apache
```

## Troubleshooting NTFS /mnt Issues
If you encounter issues when using this setup with MySQL data stored on an NTFS partition (e.g., /mnt in WSL2), it may be due to permission or compatibility problems with the file system. Follow these steps to resolve them:

1. Adding the [automount] block to /etc/wsl.conf
```
grep -q "\[automount\]" /etc/wsl.conf || echo -e "\n[automount]\noptions=\"metadata,umask=0022\"" | sudo tee -a /etc/wsl.conf
```

2. Then restart WSL:
```
logout
wsl --shutdown
```

Note: This configuration ensures proper metadata handling and sets a umask of 0022 to align file permissions with WSL2 and MySQL requirements. After restarting, re-run your Docker Compose setup to verify the fix
