CREATE TABLE IF NOT EXISTS boot (
  id integer PRIMARY KEY,
  note text NOT NULL
);

INSERT INTO boot (id, note) VALUES (1, 'init')
ON CONFLICT DO NOTHING;
