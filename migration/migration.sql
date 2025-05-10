CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE "users"(
    "id" UUID NOT NULL,
    "email" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "nickname" TEXT NOT NULL,
    "phone" VARCHAR(20) NULL
);
ALTER TABLE
    "users" ADD PRIMARY KEY("id");
CREATE INDEX "users_email_index" ON
    "users"("email");
CREATE INDEX "users_nickname_index" ON
    "users"("nickname");
CREATE INDEX "users_phone_index" ON
    "users"("phone");
CREATE TABLE "events"(
    "id" UUID NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NULL,
    "start_date" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
    "end_date" TIMESTAMP(0) WITHOUT TIME ZONE NULL,
    "creator_id" UUID NULL,
    "location" TEXT NULL,
    "category_id" UUID NULL,
    "participant_count" INTEGER NULL,
    "image_urls" TEXT[] NULL,
    "created_at" TIMESTAMP(0) WITH
        TIME zone NULL DEFAULT NOW()
);
ALTER TABLE
    "events" ADD PRIMARY KEY("id");
CREATE INDEX "events_title_index" ON
    "events"("title");
CREATE INDEX "events_start_date_index" ON
    "events"("start_date");
CREATE INDEX "events_creator_id_index" ON
    "events"("creator_id");
CREATE INDEX "events_location_index" ON
    "events"("location");
CREATE INDEX "events_category_id_index" ON
    "events"("category_id");
CREATE TABLE "categories"(
    "id" UUID NOT NULL,
    "name" TEXT NOT NULL
);
ALTER TABLE
    "categories" ADD PRIMARY KEY("id");
CREATE TABLE "reviews"(
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "event_id" UUID NOT NULL,
    "description" TEXT NOT NULL,
    "score" FLOAT(53) NOT NULL
);
ALTER TABLE
    "reviews" ADD PRIMARY KEY("id");
CREATE INDEX "reviews_user_id_index" ON
    "reviews"("user_id");
CREATE INDEX "reviews_event_id_index" ON
    "reviews"("event_id");
CREATE TABLE "approved_participants"(
    "event_id" UUID NOT NULL,
    "user_id" UUID NOT NULL
);
CREATE INDEX "approved_participants_event_id_index" ON
    "approved_participants"("event_id");
CREATE INDEX "approved_participants_user_id_index" ON
    "approved_participants"("user_id");
ALTER TABLE
    "approved_participants" ADD CONSTRAINT "approved_participants_event_id_foreign" FOREIGN KEY("event_id") REFERENCES "events"("id");
ALTER TABLE
    "reviews" ADD CONSTRAINT "reviews_event_id_foreign" FOREIGN KEY("event_id") REFERENCES "events"("id");
ALTER TABLE
    "events" ADD CONSTRAINT "events_creator_id_foreign" FOREIGN KEY("creator_id") REFERENCES "users"("id");
ALTER TABLE
    "approved_participants" ADD CONSTRAINT "approved_participants_user_id_foreign" FOREIGN KEY("user_id") REFERENCES "users"("id");
ALTER TABLE
    "events" ADD CONSTRAINT "events_category_id_foreign" FOREIGN KEY("category_id") REFERENCES "categories"("id");
ALTER TABLE
    "reviews" ADD CONSTRAINT "reviews_user_id_foreign" FOREIGN KEY("user_id") REFERENCES "users"("id");

INSERT INTO "public"."events" ("id", "title", "description", "start_date", "end_date", "creator_id", "location", "category_id", "participant_count", "image_urls", "created_at") VALUES ('678f1223-b49c-44eb-83b9-944d3c182429', 'Кабаре. Пушкин', 'По мотивам', '2025-04-26 00:00:00', null, '593790a2-c5d6-4e74-855a-de61706a88f7', '55.670214, 37.476654', '5a8bf55c-c5f8-442c-aa43-f271885a8603', '0', '"{\"https://ytitnwyszqopaqcuemat.supabase.co/storage/v1/object/public/eventimages/1744405606927.jpg\"]}', '2025-04-12 00:06:47.582102+00'), ('6c38a045-a19a-4d88-859d-afff0205f842', 'Большой сольный концерт Мота "Август Навсегда"', 'Главный современный лирик страны МОТ даст стадионные концерты «АВГУСТ НАВСЕГДА» в Москве и Санкт-Петербурге.

По традиции провожаем лето 2025 под душевные и танцевальные песни Матвея Мельникова (МОТ). Шоу стадионного масштаба под названием «АВГУСТ НАВСЕГДА» пройдут 31 августа 2025 года в Москве на «ВТБ Арене» и 6 сентября 2025 года в «Ледовом Дворце» в Санкт-Петербурге. На больших концертах МОТ выступит с полным составом музыкантов и танцовщиков, а также покажет зрелищное шоу со спецэффектами и пиротехникой. В рамках шоу артист исполнит свои самые известные хиты «Август – это ты», «Капкан», «Случайности не случайны», «Мурашками», «День и ночь», «Мама, я в Дубае», «Сопрано», «Абсолютно всё», «Лилии», «Паруса», а также свежие песни, вошедшие в новый одноименный альбом.', '2025-08-31 19:30:00', null, 'fdff6946-e86c-46f2-a81c-19c3a1dfabaf', 'ВТБ Арена', '5a82c8bc-9b19-418d-b4c6-25384f22323a', '0', '"{\"https://ytitnwyszqopaqcuemat.supabase.co/storage/v1/object/public/eventimages/1744434393145.jpg\"]}', '2025-04-12 08:06:34.740908+00'), ('90fac2da-028f-4cdb-99da-d41ff9b301d7', 'Баста', '', '2025-06-27 00:00:00', '2025-06-28 23:58:00', '593790a2-c5d6-4e74-855a-de61706a88f7', 'Олимпийский комплекс «Лужники»', '5a82c8bc-9b19-418d-b4c6-25384f22323a', '0', '"{\"https://ytitnwyszqopaqcuemat.supabase.co/storage/v1/object/public/eventimages/1744445110333.jpg\"]}', '2025-04-12 11:05:11.886351+00'), ('afe07b2e-ff6a-4a9f-afc1-b66c4f8fd636', 'Лекция стартап', 'для студентов', '2025-04-26 10:40:00', '2025-04-26 12:10:00', '593790a2-c5d6-4e74-855a-de61706a88f7', 'Проспект Вернадского, 78', 'c000d02b-5ac2-4950-b544-7cc0aa74616c', '60', '"{\"https://ytitnwyszqopaqcuemat.supabase.co/storage/v1/object/public/eventimages/1745662668540.jpg\"]}', '2025-04-12 14:42:47.158214+00'), ('bfdcf26d-f351-4040-9229-13631085ed09', 'Alice in Wonderland', 'Спектакль от театральной студии FLC. Ждём всех. Последний конкурс весной! Желаем победы. Вход свободный.', '2025-04-20 15:15:00', '2025-04-20 16:00:00', '593790a2-c5d6-4e74-855a-de61706a88f7', 'м.Кунцевская', '0251ad88-cfa2-4646-9cef-b87d32b55005', '50', '"{\"https://ytitnwyszqopaqcuemat.supabase.co/storage/v1/object/public/eventimages/1744457830739.jpg\"]}', '2025-04-11 11:31:07.142036+00'), ('cebdacae-0258-41d4-a3c8-637541a15d57', 'Guns N’Roses', 'Легендарный вечер рок-н-ролла в Эр-Рияде', '2025-05-23 20:30:00', '2025-05-23 23:50:00', '593790a2-c5d6-4e74-855a-de61706a88f7', 'Mohammed Abdo Arena (Эр-Рияд, Саудовская Аравия)', '5a82c8bc-9b19-418d-b4c6-25384f22323a', '0', '"{\"https://ytitnwyszqopaqcuemat.supabase.co/storage/v1/object/public/eventimages/1744449628270.jpg\"]}', '2025-04-12 12:20:29.644695+00');
INSERT INTO "public"."categories" ("id", "name") VALUES ('0251ad88-cfa2-4646-9cef-b87d32b55005', 'Хобби и творчество'), ('0296cc23-6c03-4be9-a2a7-e1bf39dd7ac2', 'Экскурсии и путешествия'), ('53114d71-fb63-426f-b20f-70063e79e06f', 'Вечеринки'), ('5a82c8bc-9b19-418d-b4c6-25384f22323a', 'Концерт'), ('5a8bf55c-c5f8-442c-aa43-f271885a8603', 'Искусство и культура'), ('99d018a9-b7e6-4987-9f56-6b1679248336', 'Другие развлечения'), ('c000d02b-5ac2-4950-b544-7cc0aa74616c', 'Для детей');
INSERT INTO "public"."users" ("id", "email", "nickname", "password") VALUES ('593790a2-c5d6-4e74-855a-de61706a88f7', 'poloshkova.a.y@edu.mirea.ru', 'Anastasia', '123'), ('fdff6946-e86c-46f2-a81c-19c3a1dfabaf', 'mail@mail.com', 'user_11274da6', '123');