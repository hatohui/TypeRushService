CREATE TABLE "rooms" (
  "id" string PRIMARY KEY,
  "created_at" datetime DEFAULT (now()),
  "password" string
);

CREATE TABLE "room_participants" (
  "account_id" string,
  "room_id" string,
  PRIMARY KEY ("account_id", "room_id")
);

ALTER TABLE "room_participants" ADD FOREIGN KEY ("room_id") REFERENCES "rooms" ("id");
