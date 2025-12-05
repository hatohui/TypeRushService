CREATE TABLE "accounts" (
  "account_id" string UNIQUE PRIMARY KEY,
  "password" string,
  "email" string UNIQUE,
  "name" string,
  "created_at" datetime DEFAULT (now()),
  "refresh_token" string,
  "role_id" int,
  "avatar_url" string
);
