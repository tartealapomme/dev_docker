CREATE DATABASE IF NOT EXISTS kennelDB;
USE kennelDB;

CREATE TABLE clients (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nom VARCHAR(100) NOT NULL,
  prenom VARCHAR(100) NOT NULL,
  date_naissance DATE NOT NULL,
  pseudonyme VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE adresses (
  id INT AUTO_INCREMENT PRIMARY KEY,
  numero VARCHAR(20) NOT NULL,
  rue VARCHAR(200) NOT NULL,
  code_postal VARCHAR(20) NOT NULL,
  commune VARCHAR(100) NOT NULL
);

CREATE TABLE clients_adresses (
  client_id INT NOT NULL,
  adresse_id INT NOT NULL,
  PRIMARY KEY (client_id, adresse_id),
  FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE,
  FOREIGN KEY (adresse_id) REFERENCES adresses(id) ON DELETE CASCADE
);

CREATE TABLE chiens (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nom VARCHAR(100) NOT NULL,
  date_naissance DATE NOT NULL,
  race VARCHAR(100) NOT NULL,
  sterilise BOOLEAN NOT NULL DEFAULT FALSE,
  client_id INT NULL,
  FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL
);

CREATE TABLE chats (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nom VARCHAR(100) NOT NULL,
  date_naissance DATE NOT NULL,
  race VARCHAR(100) NOT NULL,
  sterilise BOOLEAN NOT NULL DEFAULT FALSE,
  client_id INT NULL,
  FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL
);

INSERT INTO clients (nom, prenom, date_naissance, pseudonyme) VALUES
  ('Dupont', 'Alice', '1990-05-12', 'alice_d'),
  ('Martin', 'Bob', '1985-11-03', 'bob_m'),
  ('Bernard', 'Claire', '1998-02-20', 'claire_b');

INSERT INTO adresses (numero, rue, code_postal, commune) VALUES
  ('12', 'Rue des Lilas', '75011', 'Paris'),
  ('4', 'Avenue Victor Hugo', '69002', 'Lyon'),
  ('28', 'Boulevard de la Mer', '13008', 'Marseille');

INSERT INTO clients_adresses (client_id, adresse_id) VALUES
  (1, 1),
  (2, 2),
  (3, 3),
  (1, 2);

INSERT INTO chiens (nom, date_naissance, race, sterilise, client_id) VALUES
  ('Rex', '2020-03-15', 'Berger Allemand', TRUE, 1),
  ('Bella', '2021-07-22', 'Labrador', FALSE, 2),
  ('Max', '2019-12-01', 'Bulldog', TRUE, 3);

INSERT INTO chats (nom, date_naissance, race, sterilise, client_id) VALUES
  ('Misty', '2022-01-10', 'Siamois', TRUE, 1),
  ('Garfield', '2018-06-30', 'Persan', FALSE, 2),
  ('Luna', '2023-04-05', 'Maine Coon', TRUE, 3);
