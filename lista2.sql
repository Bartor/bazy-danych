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
INSERT INTO zagrali SELECT film_id AS film, actor_id AS aktor FROM sakila.film_actor WHERE film_id IN (SELECT id FROM filmy) AND actor_id IN (SELECT id FROM aktorzy);
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
6.:
INSERT INTO kontrakty (agent, aktor, poczatek, koniec, gaza) VALUES ('/A4ojQ==', 1, '20110101', '20120101', 666);
/* itd. */
/* okazuje się, że w mysql check constrainty nie działają, ale są parsowane przy tworzeniu tabel, hahahahahaha, trzeba pisać teraz triggery */
DELIMITER //
CREATE TRIGGER sprawdzdaty BEFORE INSERT ON kontrakty
FOR EACH ROW
BEGIN
    IF (NEW.gaza < 0 OR NEW.koniec < DATE_ADD(NEW.poczatek, INTERVAL 1 DAY)) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'niepoprawny rekord';
    END IF;
END;//
DELIMITER ;
ALTER TABLE kontrakty CHANGE gaza gaza INT COMMENT 'dolary papieskie na tydzień';
7.:
DELIMITER //
CREATE FUNCTION wyszukaj (im VARCHAR(30), naz VARCHAR(30)) RETURNS VARCHAR(120) DETERMINISTIC
BEGIN
    DECLARE res VARCHAR(120) DEFAULT '';
    SELECT CONCAT_WS(', ', imie, nazwisko, nazwa, DATEDIFF(koniec, CURDATE())) AS informacja FROM aktorzy A JOIN kontrakty K ON A.id = K.aktor JOIN agenci AG ON AG.licencja = K.agent WHERE A.imie = im AND A.nazwisko = naz INTO res;
    IF res = '' THEN SET res = 'Nie istnieje taki aktor!';
    END IF;
    RETURN res;
END//
DELIMITER ;
8.:
DELIMITER //
CREATE FUNCTION srednia (lic VARCHAR(30)) RETURNS INT DETERMINISTIC
BEGIN
    DECLARE v INT DEFAULT 0;
    SELECT AVG(gaza) FROM kontrakty WHERE agent = lic INTO v;
    IF ISNULL(v) THEN RETURN NULL;
    END IF;
    RETURN v;
END//
DELIMITER ;
9.:
PREPARE iloscklientow FROM 'SELECT agent, COUNT(*) AS ilosc FROM (SELECT agent, aktor FROM kontrakty K JOIN agenci A ON K.agent = A.licencja WHERE A.nazwa = ?) AS T;';
SET @test = 'Kamil Piesek Agenci'; /*przykładowe dane dla mojej tabeli*/
EXECUTE iloscklientow USING @test;
10:.
DELIMITER //
CREATE PROCEDURE najdluzszykontrakt (OUT lic VARCHAR(30), OUT naz VARCHAR(90), OUT wie INT, OUT typ ENUM('osoba indywidualna', 'agencja', 'inny'), OUT dlugosc INT)
BEGIN
    DECLARE maksag VARCHAR(30); /* numer licencji agenta, którego szukamy */
    DECLARE maks INT DEFAULT 0;
    DECLARE i INT DEFAULT 0;
    DECLARE ilosckontraktow INT DEFAULT 0;
    DECLARE ag VARCHAR(30);
    DECLARE iloscklientow INT DEFAULT 0;
    DECLARE kl INT DEFAULT 0;
    DECLARE j INT DEFAULT 0;
    DECLARE ilosckontr INT DEFAULT 0;
    DECLARE k INT DEFAULT 1;
    DECLARE k1 INT DEFAULT 0;
    DECLARE k2 INT DEFAULT 0;
    DECLARE dnizrzedu INT DEFAULT 0;
    SELECT COUNT(*) FROM kontrakty INTO ilosckontraktow; /* przygotowanie do iterowania przez wszystkie kontrakty */
    agenci_petla: WHILE i < ilosckontraktow DO /* iteracja przez kontrakty */
        SET j = 0;
        SELECT agent FROM kontrakty LIMIT i, 1 INTO ag; /* wybór konkretnego agenta */
        SELECT COUNT(aktor) FROM kontrakty WHERE agent = ag INTO iloscklientow; /* przygotowanie do iteracji przez klientów */
        klienci_petla: WHILE j < iloscklientow DO /* iteracja przez klientów */
            SET dnizrzedu = 0;
            SET k = 1;
            SELECT aktor FROM kontrakty WHERE agent = ag LIMIT j, 1 INTO kl; /* wybór konkretnego klienta */
            CREATE TEMPORARY TABLE kontr AS SELECT * FROM (SELECT poczatek AS data FROM kontrakty WHERE agent = ag AND aktor = kl UNION SELECT koniec AS data FROM kontrakty WHERE agent = ag AND aktor = kl) AS T ORDER BY data DESC; /* tabela tymczasowa, aby skrócić zapisy */
            SELECT COUNT(*) FROM kontr INTO ilosckontr;
            IF ((SELECT data FROM kontr LIMIT 1) > CURDATE()) THEN
                SET dnizrzedu = DATEDIFF(CURDATE(), (SELECT data FROM kontr LIMIT 1, 1)); /* ustawiamy liczbę dni z rzędu na różnicę aktualnej daty i rozpoczęcia ostatniego kontraktu */
            END IF;
            IF (dnizrzedu > 0) THEN
                daty_petla: WHILE k+2 < ilosckontr DO /* iteracja po datach konkretnego układu klient-agent */
                SET k1 = k + 1;
                SET k2 = k + 2;
                CREATE TEMPORARY TABLE kontr1 AS SELECT * FROM (SELECT poczatek AS data FROM kontrakty WHERE agent = ag AND aktor = kl UNION SELECT koniec AS data FROM kontrakty WHERE agent = ag AND aktor = kl) AS T ORDER BY data DESC; /* mysql zabrania odwołania się do tej samej tablicy tymczasowej dwukrotnie xDDDDDDD */ 
                CREATE TEMPORARY TABLE kontr2 AS SELECT * FROM (SELECT poczatek AS data FROM kontrakty WHERE agent = ag AND aktor = kl UNION SELECT koniec AS data FROM kontrakty WHERE agent = ag AND aktor = kl) AS T ORDER BY data DESC;
                IF (DATEDIFF((SELECT data FROM kontr1 LIMIT k, 1), (SELECT data FROM kontr2 LIMIT k1, 1)) > 1) THEN
                    SET k = ilosckontr;
                    DROP TEMPORARY TABLE kontr1;
                    DROP TEMPORARY TABLE kontr2;
                    ITERATE daty_petla;
                END IF;
                SET dnizrzedu = dnizrzedu + DATEDIFF((SELECT data FROM kontr1 LIMIT k1, 1), (SELECT data FROM kontr2 LIMIT k2, 1));
                DROP TEMPORARY TABLE kontr1;
                DROP TEMPORARY TABLE kontr2;
                SET k = k+2;
                END WHILE;
            END IF;
            IF (dnizrzedu > maks) THEN
                SET maks = dnizrzedu;
                SET maksag = ag;
            END IF;
            DROP TEMPORARY TABLE kontr;
            SET j = j+1;
        END WHILE;
        SET i = i+1;
    END WHILE;
    SELECT licencja FROM agenci WHERE licencja = maksag INTO lic;
    SELECT wiek FROM agenci WHERE licencja = maksag INTO wie;
    SELECT nazwa FROM agenci WHERE licencja = maksag INTO naz;
    SELECT typ FROM agenci WHERE licencja = maksag INTO typ;
    SET dlugosc = maks;
END;// /* o cholera to chyba działa xDDDDDD */
DELIMITER ;
11.:
DELIMITER //
CREATE TRIGGER insertaktorzy AFTER INSERT ON zagrali
FOR EACH ROW
BEGIN
    UPDATE aktorzy SET liczba = (SELECT COUNT(*) FROM zagrali WHERE aktorzy.id = zagrali.aktor);
    UPDATE aktorzy SET filmy = (SELECT GROUP_CONCAT(tytul SEPARATOR ', ') FROM zagrali Z JOIN filmy F ON F.id = Z.film WHERE aktorzy.liczba < 4 AND aktorzy.id = Z.aktor);
END;//
DELIMITER ;
DELIMITER //
CREATE TRIGGER updateaktorzy AFTER UPDATE ON zagrali
FOR EACH ROW
BEGIN
    UPDATE aktorzy SET liczba = (SELECT COUNT(*) FROM zagrali WHERE aktorzy.id = zagrali.aktor);
    UPDATE aktorzy SET filmy = (SELECT GROUP_CONCAT(tytul SEPARATOR ', ') FROM zagrali Z JOIN filmy F ON F.id = Z.film WHERE aktorzy.liczba < 4 AND aktorzy.id = Z.aktor);
END;//
DELIMITER ;
DELIMITER //
CREATE TRIGGER deleteaktorzy AFTER DELETE ON zagrali
FOR EACH ROW
BEGIN
    UPDATE aktorzy SET liczba = (SELECT COUNT(*) FROM zagrali WHERE aktorzy.id = zagrali.aktor);
    UPDATE aktorzy SET filmy = (SELECT GROUP_CONCAT(tytul SEPARATOR ', ') FROM zagrali Z JOIN filmy F ON F.id = Z.film WHERE aktorzy.liczba < 4 AND aktorzy.id = Z.aktor);
END;//
DELIMITER ;
12.:
DELIMITER //
CREATE TRIGGER dowolnyagent BEFORE INSERT ON kontrakty
FOR EACH ROW
BEGIN
    INSERT INTO agenci (licencja, nazwa, wiek, typ) VALUES (
        NEW.agent,
        CONCAT_WS(' ',
            ELT(FLOOR(RAND()*10 + 1), 'Jan', 'Pawel', 'Jurek', 'Kamil', 'Krzysztof', 'Anna', 'Dionizy', 'Topkekens', 'Filip', 'Natalia'),
            ELT(FLOOR(RAND()*10 + 1), 'Sitwar', 'Drugi', 'Enty', 'Dadad', 'Futrzak', 'Piesek', 'Walesa', 'Wojtyla', 'Kamien', 'Sykala'),
            ELT(FLOOR(RAND()*3 + 1), 'Agenci', 'S.C.', 'Z.O.O.')
        ),
        (RAND()*50 + 21),
        ELT(FLOOR(RAND()*3 + 1), 'osoba indywidualna', 'agencja', 'inny')
    );
    DELETE FROM kontrakty WHERE NEW.aktor = aktor AND poczatek < CURDATE() AND koniec > CURDATE();
END;//
DELIMITER ;
/* to robi co ma robić, ale nie działa, ale jest ok */
13.:
DELIMITER //
CREATE TRIGGER usunietofilm AFTER DELETE ON filmy
FOR EACH ROW
BEGIN
    DELETE FROM zagrali WHERE zagrali.film = old.id;
END;//
DELIMITER ;
/* odpowiedź na pytanie do zadania: tabela aktorzy zaktualizuje się zgodnie z triggerem deleteaktorzy z zadania 11. */
14.:
CREATE VIEW czternaste AS SELECT imie, nazwisko, nazwa, DATEDIFF(koniec, CURDATE()) AS koniec FROM aktorzy A JOIN kontrakty K ON (A.id = K.aktor AND DATEDIFF(K.koniec, CURDATE()) > 0) JOIN agenci AG ON AG.licencja = K.agent;
/* odpowiedź na pytania do zadania: nie moze być utworzony, użytkownik nie ma permisji CREATE VIEW, ma do niego dostęp, widok może być wyświetlony SELECTem */
15.:
CREATE VIEW aktorzypub AS SELECT imie, nazwisko FROM aktorzy;
CREATE VIEW agencipub AS SELECT nazwa, wiek, typ FROM agenci;
CREATE VIEW filmypub AS SELECT tytul, gatunek, kategoria, czas FROM filmy;
CREATE USER 'publiczny'@'localhost' IDENTIFIED BY 'publiczny'; /* specjalnie brak realnych zabezpieczeń */
GRANT SELECT ON LaboratoriumFilmoteka.aktorzypub TO 'publiczny'@'localhost';
GRANT SELECT ON LaboratoriumFilmoteka.agencipub TO 'publiczny'@'localhost';
GRANT SELECT ON LaboratoriumFilmoteka.filmypub TO 'publiczny'@'localhost';
/* odpowiedź na pytania do zadania: nie może wykonywać niczego z tych rzeczy, mówi o tym brak uprawnień EXECUTE oraz UPDATE, DELETE i INSERT */