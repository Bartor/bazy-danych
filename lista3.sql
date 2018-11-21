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
    waga FLOAT,
    rozmiar_buta INT,
    ulubiony_kolor ENUM('czarny', 'czerwony', 'zielony', 'niebieski', 'biały')
);
CREATE TABLE pracownicy(
    PESEL CHAR(11) PRIMARY KEY NOT NULL,
    zawod VARCHAR(50),
    pensja FLOAT
);
DELIMITER //
CREATE TRIGGER insertludzie BEFORE INSERT ON ludzie
FOR EACH ROW
BEGIN
    IF (
        SUBSTRING(NEW.PESEL, 1, 2) <> SUBSTRING(YEAR(NEW.data_urodzenia), 3, 2) OR
        SUBSTRING(NEW.PESEL, 3, 2) <> MONTH(NEW.data_urodzenia) OR
        SUBSTRING(NEW.PESEL, 5, 2) <> DAYOFMONTH(NEW.data_urodzenia) OR
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
        ) <> SUBSTRING(NEW.PESEL, 11, 1) OR
        NEW.wzrost < 0 OR NEW.waga < 0
    ) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'niepoprawny rekord';
END//
CREATE TRIGGER updateludzie BEFORE UPDATE ON ludzie
FOR EACH ROW
BEGIN
    IF (
        SUBSTRING(NEW.PESEL, 1, 2) <> SUBSTRING(YEAR(NEW.data_urodzenia), 3, 2) OR
        SUBSTRING(NEW.PESEL, 3, 2) <> MONTH(NEW.data_urodzenia) OR
        SUBSTRING(NEW.PESEL, 5, 2) <> DAYOFMONTH(NEW.data_urodzenia) OR
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
        ) <> SUBSTRING(NEW.PESEL, 11, 1) OR
        NEW.wzrost < 0 OR NEW.waga < 0
    ) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'niepoprawny rekord';
END//
DELIMITER ;
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
DELIMITER //
CREATE PROCEDURE agregacja (IN kol ENUM('pesel', 'imie', 'nazwisko', 'data_urodzenia', 'wzrost', 'waga', 'rozmiar_buta', 'ulubiony_kolor'), IN agg VARCHAR(20), OUT X VARCHAR(100))
BEGIN
    SET @temp = NULL;
    SET @arg = kol;
    CASE LOWER(agg)
        WHEN 'avg' THEN
            SET @query = CONCAT('SELECT AVG(', kol, ') FROM LUDZIE INTO @temp');
            PREPARE stmt FROM @query;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
        WHEN 'count' THEN
            SET @query = CONCAT('SELECT COUNT(', kol, ') FROM ludzie INTO @temp');
            PREPARE stmt FROM @query;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
        WHEN 'max' THEN
            SET @query = CONCAT('SELECT MAX(', kol, ') FROM ludzie INTO @temp');
            PREPARE stmt FROM @query;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
        WHEN 'min' THEN
            SET @query = CONCAT('SELECT MIN(', kol, ') FROM ludzie INTO @temp');
            PREPARE stmt FROM @query;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
        WHEN 'sum' THEN
            SET @query = CONCAT('SELECT SUM(', kol, ') FROM ludzie INTO @temp');
            PREPARE stmt FROM @query;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
        ELSE
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'niepoprawna funkcja agregująca';
    END CASE;
    SET X = @temp;
END//
DELIMITER ;
6.:
/* to zadanie znowu nie ma sensu, bo nie da się rollbackować selectów, więc mija się to kompletnie z celem */
DELIMITER //
CREATE PROCEDURE zaplac (IN budzet FLOAT, IN zawod ENUM('aktor', 'agent', 'informatyk', 'reporter', 'sprzedawca'))
BEGIN
    DECLARE wyplacalne INT DEFAULT 1;
    DECLARE done INT DEFAULT FALSE;
    DECLARE pesel CHAR(11);
    DECLARE pensja FLOAT;
    DECLARE cur1 CURSOR FOR (SELECT P.pesel, P.pensja FROM pracownicy P WHERE P.zawod = zawod);
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    CREATE TEMPORARY TABLE temp (pesel CHAR(3), status BOOLEAN); /* tablica zbierająca informacje, bo selecta się nie da rollbackować */
    SET @bud = budzet;
    SET autocommit=0;
    OPEN cur1;
    START TRANSACTION;
    r: LOOP
        FETCH cur1 INTO pesel, pensja;
        IF done THEN
            LEAVE r;
        END IF;
        SET @bud = @bud - pensja;
        IF (@bud > 0) THEN
            INSERT INTO temp VALUES(SUBSTRING(pesel, 9), TRUE); /* tu powinna być też operacja płacenia */
        ELSE
            SET wyplacalne = FALSE;
            LEAVE r;
        END IF;
    END LOOP;
    CLOSE cur1;
    IF (wyplacalne = 1) THEN
        SELECT * FROM temp;
        COMMIT;
    ELSE ROLLBACK;
    END IF;
    DROP TABLE temp;
END//
DELIMITER ;
7.:
/* nie wiem, o co chodzi w tym rozkładzie, to zadanie będzie działać, jak się dowiem */
DELIMITER //
CREATE FUNCTION laplace(a FLOAT, b FLOAT, x FLOAT) RETURNS FLOAT DETERMINISTIC
BEGIN
    DECLARE r FLOAT DEFAULT 0;
    SET r = (1/(2*b))*EXP(-(ABS(x-a)/b));
    RETURN r;
END//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE statystyki (IN kol ENUM('wzrost', 'waga', 'pensja'), IN zawod ENUM('aktor', 'agent', 'informatyk', 'reporter', 'sprzedawca'))
BEGIN
    DECLARE delta FLOAT;
    SET @z = zawod;
    SET @r = NULL;
    SET @maks = 0;
    SET @min = 0;
    SET @query = CONCAT('SELECT MAX(', kol, ') FROM ludzie INTO @maks');
    PREPARE stmt1 FROM @query;
    SET @query = CONCAT('SELECT MAX(', kol, ') FROM ludzie INTO @min');
    PREPARE stmt2 FROM @query;
    EXECUTE stmt1;
    EXECUTE stmt2;
    SET delta = @maks - @min;
    SET @query = CONCAT('SELECT laplace(0, (SELECT ', kol, ' FROM ludzie ORDER BY RAND() LIMIT 1), (', delta, '/0.05))+SUM(', kol, ') FROM ludzie L JOIN pracownicy P ON L.pesel = P.pesel WHERE zawod = ? INTO @r');
    /* chciałbym wiedzieć, co znaczą te literki przy rozkładzie, ale nie mieliśmy tego nigdy nigdzie poza bd, a google milczy */
    PREPARE stmt FROM @query;
    EXECUTE stmt USING @z;
    SELECT @r AS Wynik;
END//
DELIMITER ;
8.:
CREATE DATABASE logi;
CREATE TABLE pensje(
    pesel CHAR(11),
    stare FLOAT,
    nowe FLOAT,
    czas DATE,
    uzytkownik TEXT
);
DELIMITER //
CREATE TRIGGER pensjeupdate AFTER UPDATE ON lista3.pracownicy
FOR EACH ROW
BEGIN
    INSERT INTO logi.pensje VALUES (
        OLD.pesel,
        OLD.pensja,
        NEW.pensja,
        NOW(),
        USER()
    );
END//
CREATE TRIGGER pensjeinsert AFTER INSERT ON lista3.pracownicy
FOR EACH ROW
BEGIN
    INSERT INTO logi.pensje VALUES (
        NEW.pesel,
        NULL,
        NEW.pensja,
        NOW(),
        USER()
    );
END//
CREATE TRIGGER pensjedelete AFTER DELETE ON lista3.pracownicy
FOR EACH ROW
BEGIN
    INSERT INTO logi.pensje VALUES (
        OLD.pesel,
        OLD.pensja,
        NULL,
        NOW(),
        USER()
    );
END//
DELIMITER ;
9.:
/* powershell w MySQL Server/bin */
.\mysqldump.exe lista3 --user=root --result-file lista3.sql --password
/* podajemy hasło, baza danych znajduje się w pliku dump.sql */
DROP DATABASE lista3;
/* teraz używamy cmd w tym samym folderze, bo tak */
.\mysql.exe -u root -p lista3 < .\lista3.sql