# Secrets

Les mots de passe ne sont pas dans Git. Copier les exemples puis remplacer `changeme` par les mots de passe utilisés à l'initialisation du volume MariaDB.

```powershell
Copy-Item mariadb_root_password.txt.example mariadb_root_password.txt
Copy-Item mariadb_password.txt.example mariadb_password.txt
```

Compose les monte dans `/run/secrets/`. MariaDB lit `MARIADB_ROOT_PASSWORD_FILE` et `MARIADB_PASSWORD_FILE`. WordPress lit `WORDPRESS_DB_PASSWORD_FILE` via `wp-config.php`.
