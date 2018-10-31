1. SHOW tables;
2. SELECT title FROM film WHERE length > 120;
3. SELECT title, name FROM film F JOIN language L ON F.language_id = L.language_id WHERE description LIKE '%Documentary%';
4. SELECT title FROM film F JOIN film_category FC ON F.film_id = FC.film_id JOIN category C ON C.category_id = FC.category_id WHERE C.name = 'documentary' AND F.description NOT LIKE '%documentary%';
5. SELECT DISTINCT first_name, last_name FROM film F JOIN film_actor FA ON F.film_id = FA.film_id JOIN actor A ON FA.actor_id = A.actor_id WHERE F.special_features LIKE '%Deleted Scenes%';
6. SELECT COUNT(film_id), rating FROM film GROUP BY rating ORDER BY COUNT(film_id) DESC;
7. SELECT title FROM rental R JOIN inventory I ON R.inventory_id = I.inventory_id JOIN film F on F.film_id = I.film_id WHERE R.rental_date > '20050525' AND R.rental_date < '20050530' ORDER by title;
8. SELECT title FROM film WHERE rating = 'R' SORT BY length LIMIT 5;
9. SELECT DISTINCT C.first_name, C.last_name FROM rental R JOIN rental RR ON R.customer_id = RR.customer_id JOIN customer C ON R.customer_id = C.customer_id WHERE R.staff_id < RR.staff_id;
10. SELECT country, count FROM (SELECT COUNT(city_id) AS count, country FROM city C JOIN country CO ON C.country_id = CO.country_id GROUP BY country ORDER BY COUNT(city_id) DESC) T WHERE count >= (SELECT COUNT(city_id) FROM city C JOIN country CO ON C.country_id = CO.country_id WHERE country = 'canada');
11. SELECT * FROM (SELECT COUNT(rental_id) AS count, C.* FROM rental R JOIN customer C ON R.customer_id = C.customer_id GROUP BY customer_id ORDER BY COUNT(rental_id) DESC) T WHERE count > (SELECT COUNT(rental_id) AS count FROM rental R JOIN customer C ON R.customer_id = C.customer_id WHERE C.email = 'PETER.MENARD@sakilacustomer.org');
12. SELECT actor1, actor2, COUNT(*) FROM (SELECT F1.actor_id AS actor1, F2.actor_id AS actor2, F1.film_id FROM film_actor F1 LEFT JOIN film_actor F2 ON F1.film_id = F2.film_id WHERE F1.actor_id < F2.actor_id) T GROUP BY actor1, actor2 HAVING COUNT(*) > 1;
13. SELECT DISTINCT last_name FROM film_actor FA JOIN actor A ON FA.actor_id = A.actor_id WHERE A.actor_id NOT IN (SELECT actor_id FROM film_actor FA JOIN film F ON FA.film_id = F.film_id WHERE title LIKE 'B%');
14.:
CREATE VIEW actions AS SELECT A.actor_id AS actor1, C.name AS c1, COUNT(F.film_id) AS count1 FROM film_actor FA JOIN actor A ON FA.actor_id = A.actor_id JOIN film F ON FA.film_id = F.film_id JOIN film_category FC ON F.film_id = FC.film_id JOIN category C ON FC.category_id = C.category_id WHERE C.name = 'action' GROUP BY A.actor_id, C.name ORDER BY A.actor_id;
CREATE VIEW horrors AS SELECT A.actor_id AS actor2, C.name AS c2, COUNT(F.film_id) AS count2 FROM film_actor FA JOIN actor A ON FA.actor_id = A.actor_id JOIN film F ON FA.film_id = F.film_id JOIN film_category FC ON F.film_id = FC.film_id JOIN category C ON FC.category_id = C.category_id WHERE C.name = 'horror' GROUP BY A.actor_id, C.name ORDER BY A.actor_id;
CREATE VIEW horror_action AS SELECT * FROM horrors LEFT JOIN actions ON horrors.actor2 = actions.actor1 UNION ALL SELECT * FROM horrors RIGHT JOIN actions ON horrors.actor2 = actions.actor1 WHERE horrors.actor2 IS NULL;
SELECT last_name FROM horror_action HA JOIN actor A ON HA.actor2 = A.actor_id WHERE count2 > count1 OR isNull(count1);
15. SELECT customer_id FROM payment GROUP BY customer_id HAVING AVG(amount) > (SELECT AVG(amount) FROM payment WHERE payment_date > '20050706' AND payment_date < '20050708');
16.:
ALTER TABLE language ADD COLUMN film_no int AFTER name;
UPDATE language SET film_no = (SELECT COUNT(*) FROM film WHERE film.language_id = language.language_id);
17.:
UPDATE film SET language_id = (SELECT language_id FROM language WHERE name = 'Mandarin') WHERE title = 'WON DARES';
UPDATE film F JOIN film_actor FA ON F.film_id = FA.film_id JOIN actor A ON FA.actor_id = A.actor_id SET F.language_id = (SELECT language_id FROM language WHERE name = 'German') WHERE A.first_name = 'NICK' AND A.last_name = 'WAHLBERG';
UPDATE language SET film_no = (SELECT COUNT(*) FROM film WHERE film.language_id = language.language_id);
18. ALTER TABLE film DROP COLUMN release_year;