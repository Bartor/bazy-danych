1.:
CREATE INDEX filmyidx ON filmy (tytul);
CREATE INDEX aktorzyidx ON aktorzy (nazwisko, imie(1));
CREATE INDEX zagraliidx ON zagrali (aktor);
/* żaden z utworzonych indeksów u mnie nie istanił */
2.:
CREATE INDEX koniecidx USING BTREE ON kontrakty (koniec);
/* używamy btree, ponieważ nadaje się on do porównań >, <, >=, <=, a hash jedynie do = i <> */
SELECT aktor FROM kontrakty WHERE koniec < DATE_ADD(CURDATE(), INTERVAL 1 MONTH);
3.:
SELECT imie FROM aktorzy WHERE imie LIKE 'J%';
/* używany jest indeks pierwszej litery imienia */
SELECT A.nazwisko, COUNT(film) FROM zagrali Z JOIN aktorzy A ON Z.aktor = A.id GROUP BY aktor HAVING COUNT(film) >= 12;
/* używany jest indeks nazwiska */
SELECT DISTINCT F.tytul FROM zagrali Z JOIN zagrali ZZ ON Z.film = ZZ.film JOIN filmy F ON Z.film = F.id AND ZZ.aktor = (SELECT id FROM aktorzy WHERE imie = 'ZERO' AND nazwisko = 'CAGE');
/* używany jest indeks aktora i tytułu */
SELECT aktor, DATEDIFF(koniec, CURDATE()) FROM kontrakty WHERE koniec > CURDATE() ORDER BY DATEDIFF(koniec, CURDATE()) LIMIT 1;
/* używany jest indeks na koniec */
SELECT imie, COUNT(id) FROM aktorzy GROUP BY imie ORDER BY COUNT(id) DESC LIMIT 1;
/* używany jest indeks istniejący na id, ale nie żaden utworzony w 1. czy 2. */
/* odpowiedzi w komentarzach do zapytań tego zadania nie są sprawdzone w 100% */
4.:
CREATE DATEBASE lista3;
CREATE TABLE ludzie(
    PESEL CHAR(11) PRIMARY KEY NOT NULL,
    imie VARCHAR(30),
    nazwisko VARCHAR(30),
    data_urodzenia DATE,
    wzrost FLOAT,
    WAGA FLOAT,
    rozmiar_buta INT,
    ulubiony_kolor ENUM('czarny', 'czerwony', 'zielony', 'niebieski', 'biały')
);
CREATE TABLE pracownicy(
    PESEL CHAR(11) PRIMARY KEY NOT NULL,
    zawod VARCHAR(50),
    pensja FLOAT
);
DELIMITER //
CREATE PROCEDURE dodajludzi (IN ilosc INT)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE pesel VARCHAR(11);
    DECLARE data DATE;
    WHILE i < ilosc DO
        SET data = DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND()*30000+1) DAY);
        SET pesel = CONCAT(
            SUBSTRING(YEAR(data), 3, 2),
            LPAD(MONTH(data), 2, '0'),
            LPAD(DAYOFMONTH(data), 2, '0'),
            FLOOR(RAND()*10),
            FLOOR(RAND()*10),
            FLOOR(RAND()*10),
            FLOOR(RAND()*10)
        );
        SET pesel = CONCAT(
            pesel,
            MOD(
                9*CAST(SUBSTRING(pesel, 1, 1) AS UNSIGNED) + 
                7*CAST(SUBSTRING(pesel, 2, 1) AS UNSIGNED) + 
                3*CAST(SUBSTRING(pesel, 3, 1) AS UNSIGNED) + 
                1*CAST(SUBSTRING(pesel, 4, 1) AS UNSIGNED) + 
                9*CAST(SUBSTRING(pesel, 5, 1) AS UNSIGNED) + 
                7*CAST(SUBSTRING(pesel, 6, 1) AS UNSIGNED) + 
                3*CAST(SUBSTRING(pesel, 7, 1) AS UNSIGNED) + 
                1*CAST(SUBSTRING(pesel, 8, 1) AS UNSIGNED) + 
                9*CAST(SUBSTRING(pesel, 9, 1) AS UNSIGNED) + 
                7*CAST(SUBSTRING(pesel, 10, 1) AS UNSIGNED),
                10
            )
        );
        INSERT INTO ludzie VALUES (
            CAST(pesel AS CHAR(11)),
            ELT(FLOOR(RAND()*10 + 1), 'Jan', 'Piotr', 'Paweł', 'Bartosz', 'Krzysztof', 'Maciej', 'Anna', 'Zuzanna', 'Ewa', 'Julia'),
            ELT(FLOOR(RAND()*10 + 1), 'Papież', 'Piesek', 'Kotek', 'Kura', 'Wąż', 'Świnia', 'Tygrys', 'Nietoperz', 'Polak', 'Krowa'),
            data,
            RAND()*30 + 160,
            RAND()*50 + 50,
            FLOOR(RAND()*10 + 35),
            ELT(FLOOR(RAND()*5 + 1), 'czarny', 'czerwony', 'zielony', 'niebieski', 'biały')
        );
        SET i = i + 1;
    END WHILE;
END//
DELIMITER ;
CALL dodajludzi(200); /* na wszelki wypadek można powtórzyć, bo chociaż mamy mieć 200 ludzi, to wszyscy pracownicy mają być pełnoletni, a przy 200 ludziach jest niewielka szansa, że aż tyle będzie pełnoletnich */
DELIMITER //
CREATE PROCEDURE dodajpracownikow()
BEGIN
    DECLARE i INT DEFAULT 0; /* iterator po ilości danego zawodu */
    DECLARE j INT DEFAULT 1; /* iterator po tablicy ludzie */
    WHILE i < 50 DO
        IF (DATEDIFF(CURDATE(), (SELECT data_urodzenia FROM ludzie ORDER BY data_urodzenia LIMIT j, 1)) > 18*365) THEN
            SET i = i + 1;
            INSERT INTO pracownicy VALUES(
                (SELECT pesel FROM LUDZIE ORDER BY data_urodzenia LIMIT j, 1),
                'aktor',
                RAND()*50000 + 5000
            );
        END IF;
        SET j = j + 1;
    END WHILE;
    SET i = 0;
    WHILE i < 33 DO
        IF (DATEDIFF(CURDATE(), (SELECT data_urodzenia FROM ludzie ORDER BY data_urodzenia LIMIT j, 1)) > 18*365) THEN
            SET i = i + 1;
            INSERT INTO pracownicy VALUES(
                (SELECT pesel FROM LUDZIE ORDER BY data_urodzenia LIMIT j, 1),
                'agent',
                RAND()*10000 + 2000
            );
        END IF;
        SET j = j + 1;
    END WHILE;
    SET i = 0;
    WHILE i < 13 DO
        IF (DATEDIFF(CURDATE(), (SELECT data_urodzenia FROM ludzie ORDER BY data_urodzenia LIMIT j, 1)) > 18*365) THEN
            SET i = i + 1;
            INSERT INTO pracownicy VALUES(
                (SELECT pesel FROM LUDZIE ORDER BY data_urodzenia LIMIT j, 1),
                'informatyk',
                RAND()*20000 + 10000
            );
        END IF;
        SET j = j + 1;
    END WHILE;
    SET i = 0;
    WHILE i < 2 DO
        IF (DATEDIFF(CURDATE(), (SELECT data_urodzenia FROM ludzie ORDER BY data_urodzenia LIMIT j, 1)) > 18*365) THEN
            SET i = i + 1;
            INSERT INTO pracownicy VALUES(
                (SELECT pesel FROM LUDZIE ORDER BY data_urodzenia LIMIT j, 1),
                'reporter',
                RAND()*4000 + 1000
            );
        END IF;
        SET j = j + 1;
    END WHILE;
    SET i = 0;
    WHILE i < 77 DO
        IF (DATEDIFF(CURDATE(), (SELECT data_urodzenia FROM ludzie ORDER BY data_urodzenia LIMIT j, 1)) > 18*365 AND DATEDIFF(CURDATE(), (SELECT data_urodzenia FROM ludzie ORDER BY data_urodzenia LIMIT j, 1)) < 65*365) THEN
            SET i = i + 1;
            INSERT INTO pracownicy VALUES(
                (SELECT pesel FROM LUDZIE ORDER BY data_urodzenia LIMIT j, 1),
                'sprzedawca',
                RAND()*2000 + 1000
            );
        END IF;
        SET j = j + 1;
    END WHILE;
END//
DELIMITER ;
/* ten kod ma błędy, kiedy dwie osoby urodziły się tego samego dnia, nie przejmuję się tym, bo sql nie służy w ogóle do generowania samemu sobie danych i próba naprawienia tego jest po prostu marnowaniem czasu */
5.:

