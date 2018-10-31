1.:
CREATE DATABASE LaboratoriumFilmoteka;
CREATE USER '244928'@'localhost' IDENTIFIED BY 'Bartosz928';
GRANT SELECT, INSERT, UPDATE ON LaboratoriumFilmoteka.* TO '244928'@'localhost';
2.:
CREATE TABLE aktorzy (id INT NOT NULL PRIMARY KEY AUTO_INCREMENT, imie VARCHAR(30), nazwisko VARCHAR(30));
CREATE TABLE filmy (id INT NOT NULL PRIMARY KEY AUTO_INCREMENT, tytul VARCHAR(64), gatunek VARCHAR(20), czas INT, kategoria VARCHAR(5));
CREATE TABLE zagrali (aktor INT, film INT);
INSERT INTO LaboratoriumFilmoteka.aktorzy SELECT actor_id AS id, first_name AS imie, last_name AS nazwisko FROM sakila.actor WHERE first_name NOT LIKE '%x%' AND first_name NOT LIKE '%v%' AND last_name NOT LIKE '%x%' AND last_name NOT LIKE '%v%';
INSERT INTO LaboratoriumFilmoteka.filmy SELECT F.film_id AS id, title AS tytul, name AS gatunek, rating AS kategoria, length AS czas FROM sakila.film F JOIN sakila.film_category FC ON F.film_id = FC.film_id JOIN sakila.category C ON FC.category_id = C.category_id WHERE title NOT LIKE '%x%' AND title NOT LIKE '%v%';
INSERT INTO zagrali SELECT film_id AS film, actor_id AS aktor FROM sakila.film_actor WHERE film_id IN (SELECT id FROM filmy) AND actor_id IN (SELECT id from aktorzy);
3.:
ALTER TABLE aktorzy ADD COLUMN liczba INT;
ALTER TABLE aktorzy ADD COLUMN filmy TEXT;
UPDATE aktorzy SET liczba = (SELECT COUNT(*) FROM zagrali WHERE aktorzy.id = zagrali.aktor);
UPDATE aktorzy SET filmy = (SELECT GROUP_CONCAT(tytul SEPARATOR ', ') FROM zagrali Z JOIN filmy F ON F.id = Z.film WHERE aktorzy.liczba < 4 AND aktorzy.id = Z.aktor);
4.:
CREATE TABLE agenci (
    licencja VARCHAR(30) NOT NULL PRIMARY KEY, 
    nazwa VARCHAR(90), 
    wiek INT CHECK(wiek >= 21),
    typ ENUM('osoba indywidualna', 'agencja', 'inny')
);
CREATE TABLE kontrakty (
    id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    agent VARCHAR(30), 
    aktor INT,
    poczatek DATE,
    koniec DATE,
    gaza INT CHECK (gaza >= 0),
    FOREIGN KEY (aktor)
        REFERENCES aktorzy(id)
        ON DELETE CASCADE,
    FOREIGN KEY (agent)
        REFERENCES agenci(licencja)
        ON DELETE CASCADE,
    CONSTRAINT data CHECK (koniec >= DATE_ADD(poczatek, INTERVAL 1 DAY))
);
5.:
DELIMITER //
CREATE PROCEDURE dodajagentow (IN ilosc INT)
BEGIN
    DECLARE i INT DEFAULT 0;
    WHILE i < ilosc DO
        INSERT INTO agenci (licencja, nazwa, wiek, typ) VALUES (
            TO_BASE64(RANDOM_BYTES(FLOOR(RAND(NOW())*16 + 4))),
            CONCAT_WS(' ',
                ELT(FLOOR(RAND()*10 + 1), 'Jan', 'Pawel', 'Jurek', 'Kamil', 'Krzysztof', 'Anna', 'Dionizy', 'Topkekens', 'Filip', 'Natalia'),
                ELT(FLOOR(RAND()*10 + 1), 'Sitwar', 'Drugi', 'Enty', 'Dadad', 'Futrzak', 'Piesek', 'Walesa', 'Wojtyla', 'Kamien', 'Sykala'),
                ELT(FLOOR(RAND()*3 + 1), 'Agenci', 'S.C.', 'Z.O.O.')
            ),
            (RAND()*50 + 21),
            ELT(FLOOR(RAND()*3 + 1), 'osoba indywidualna', 'agencja', 'inny')
        );
        SET i = i + 1;
    END WHILE;
END//
DELIMITER ; 
CALL dodajagentow(1000);
DELIMITER //
CREATE PROCEDURE przydzielkontrakty ()
BEGIN
    DECLARE n INT DEFAULT 0;
    DECLARE i INT DEFAULT 0;
    SELECT COUNT(*) FROM aktorzy INTO n;
    WHILE i < n DO
        INSERT INTO kontrakty (agent, aktor, poczatek, koniec, gaza) VALUES (
            (SELECT licencja FROM agenci ORDER BY RAND() LIMIT 1),
            (SELECT id FROM aktorzy LIMIT i,1),
            CURDATE(),
            DATE_ADD(CURDATE(), INTERVAL FLOOR(RAND()*365) DAY),
            FLOOR(RAND()*1000 + 1)
        );
        SET i = i + 1;
    END WHILE;
END//
DELIMITER ;
CALL przydzielkontrakty();