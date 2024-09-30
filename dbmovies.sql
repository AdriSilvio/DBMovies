-- Crear la base de datos
CREATE DATABASE IF NOT EXISTS BaseDeDatosPeliculas;

-- Usar la base de datos
USE BaseDeDatosPeliculas;

-- TABLAS
-- Crear la tabla 1 de MOVIE
CREATE TABLE MOVIE (
    ID_movie INT AUTO_INCREMENT PRIMARY KEY,
    Title VARCHAR(100),
    Original_title VARCHAR(100),
    Genre VARCHAR(100),
    Keyword VARCHAR(100),
    Overview TEXT,
    Tagline TEXT,
    Runtime TIME,
    Language VARCHAR(100),
    Release_date DATETIME
);

-- Crear la tabla 2 de COMPANY
CREATE TABLE COMPANY (
    ID_movie INT,
    Production_company VARCHAR(100),
    Production_country VARCHAR(100),
    PRIMARY KEY (Production_company),
    FOREIGN KEY (ID_movie) REFERENCES MOVIE(ID_movie)
);

-- Crear la tabla 3 de PROFIT
CREATE TABLE PROFIT (
    ID_movie INT,
    Revenue INT,
    Budget INT,
    FOREIGN KEY (ID_movie) REFERENCES MOVIE(ID_movie)
);

-- Crear la tabla 4 de hechos
CREATE TABLE FACT_SALES (
    Sale_ID INT AUTO_INCREMENT PRIMARY KEY,
    ID_movie INT, -- FK referencing MOVIE
    Production_company VARCHAR(100), -- FK referencing COMPANY
    Sale_Date DATE,
    Revenue DECIMAL(15,2),
    Budget DECIMAL(15,2),
    Profit DECIMAL(15,2) GENERATED ALWAYS AS (Revenue - Budget),
    FOREIGN KEY (ID_movie) REFERENCES MOVIE(ID_movie),
    FOREIGN KEY (Production_company) REFERENCES COMPANY(Production_company)
);

-- Crear tabla 5 transaccional 1
CREATE TABLE TRANSACTION_VIEW (
    View_ID INT AUTO_INCREMENT PRIMARY KEY,
    User_ID INT, -- ID of the user who viewed the movie
    ID_movie INT, -- FK referencing MOVIE
    View_Date DATETIME,
    Duration_Watched TIME, -- How long the movie was watched
    FOREIGN KEY (ID_movie) REFERENCES MOVIE(ID_movie)
);

-- Crear tabla 6 transaccional 2
CREATE TABLE TRANSACTION_RATING (
    Rating_ID INT AUTO_INCREMENT PRIMARY KEY,
    User_ID INT, -- ID of the user who rated the movie
    ID_movie INT, -- FK referencing MOVIE
    Rating DECIMAL(2,1), -- Rating given to the movie, e.g., 8.5
    Rating_Date DATE,
    FOREIGN KEY (ID_movie) REFERENCES MOVIE(ID_movie)
);

-- Crear tablas 7,8 principales
CREATE TABLE ACTOR (
    ID_actor INT PRIMARY KEY AUTO_INCREMENT,
    First_name VARCHAR(50) NOT NULL,
    Last_name VARCHAR(50) NOT NULL,
    Birthdate DATE,
    Nationality VARCHAR(50)
);

CREATE TABLE DIRECTOR (
    ID_director INT PRIMARY KEY AUTO_INCREMENT,
    First_name VARCHAR(50) NOT NULL,
    Last_name VARCHAR(50) NOT NULL,
    Birthdate DATE,
    Nationality VARCHAR(50)
);

-- Crear tablas 9, 10 intermedias para actores y directores
CREATE TABLE MOVIE_ACTOR (
    ID_movie INT,
    ID_actor INT,
    Role VARCHAR(100),
    PRIMARY KEY (ID_movie, ID_actor),
    FOREIGN KEY (ID_movie) REFERENCES MOVIE(ID_movie),
    FOREIGN KEY (ID_actor) REFERENCES ACTOR(ID_actor)
);

CREATE TABLE MOVIE_DIRECTOR (
    ID_movie INT,
    ID_director INT,
    PRIMARY KEY (ID_movie, ID_director),
    FOREIGN KEY (ID_movie) REFERENCES MOVIE(ID_movie),
    FOREIGN KEY (ID_director) REFERENCES DIRECTOR(ID_director)
);

-- Crear tabla 11 de usuarios
CREATE TABLE USER_ACCOUNT (
    ID_user INT PRIMARY KEY AUTO_INCREMENT,
    Username VARCHAR(50) UNIQUE NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    Password VARCHAR(255) NOT NULL,
    Signup_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Crear tablas 12, 13 de streaming
CREATE TABLE STREAMING (
    ID_streaming INT PRIMARY KEY AUTO_INCREMENT,
    Platform_name VARCHAR(100) NOT NULL,
    Subscription_required BOOLEAN DEFAULT TRUE
);

CREATE TABLE MOVIE_STREAMING (
    ID_movie INT,
    ID_streaming INT,
    Availability_date DATE,
    PRIMARY KEY (ID_movie, ID_streaming),
    FOREIGN KEY (ID_movie) REFERENCES MOVIE(ID_movie),
    FOREIGN KEY (ID_streaming) REFERENCES STREAMING(ID_streaming)
);

-- Crear tabla 14 de ratings
CREATE TABLE RATING (
    ID_rating INT PRIMARY KEY AUTO_INCREMENT,
    Source VARCHAR(100) NOT NULL,
    Score DECIMAL(3,1) NOT NULL,
    ID_movie INT,
    FOREIGN KEY (ID_movie) REFERENCES MOVIE(ID_movie)
);

-- Crear tablas 15, 16 de premios
CREATE TABLE AWARDS (
    ID_award INT PRIMARY KEY AUTO_INCREMENT,
    Award_name VARCHAR(100) NOT NULL,
    Year INT,
    Category VARCHAR(100)
);

CREATE TABLE MOVIE_AWARDS (
    ID_movie INT,
    ID_award INT,
    PRIMARY KEY (ID_movie, ID_award),
    FOREIGN KEY (ID_movie) REFERENCES MOVIE(ID_movie),
    FOREIGN KEY (ID_award) REFERENCES AWARDS(ID_award)
);

 -- Para eliminar alguna tabla
DROP TABLE IF EXISTS xxxxx;

-- VISTAS
-- Vista 1 rentabilidad
CREATE VIEW V_MOST_PROFITABLE_MOVIES AS
SELECT M.Title, M.Release_date, FS.Revenue, FS.Budget, FS.Profit
FROM MOVIE M
JOIN FACT_SALES FS ON M.ID_movie = FS.ID_movie
ORDER BY FS.Profit DESC;

-- Vista 2 popularidad streaming
CREATE VIEW V_POPULAR_MOVIES_ON_STREAMING AS
SELECT M.Title, S.Platform_name, AVG(R.Score) AS Average_Rating
FROM MOVIE M
JOIN MOVIE_STREAMING MS ON M.ID_movie = MS.ID_movie
JOIN STREAMING S ON MS.ID_streaming = S.ID_streaming
JOIN RATING R ON M.ID_movie = R.ID_movie
GROUP BY M.Title, S.Platform_name
ORDER BY Average_Rating DESC;

-- Vista 3 Elenco
CREATE VIEW V_MOVIE_CREW AS
SELECT M.Title, CONCAT(A.First_name, ' ', A.Last_name) AS Actor, CONCAT(D.First_name, ' ', D.Last_name) AS Director
FROM MOVIE M
LEFT JOIN MOVIE_ACTOR MA ON M.ID_movie = MA.ID_movie
LEFT JOIN ACTOR A ON MA.ID_actor = A.ID_actor
LEFT JOIN MOVIE_DIRECTOR MD ON M.ID_movie = MD.ID_movie
LEFT JOIN DIRECTOR D ON MD.ID_director = D.ID_director;

-- Vista 4 premios
CREATE VIEW V_AWARD_WINNING_MOVIES AS
SELECT M.Title, A.Award_name, A.Year, A.Category
FROM MOVIE M
JOIN MOVIE_AWARDS MA ON M.ID_movie = MA.ID_movie
JOIN AWARDS A ON MA.ID_award = A.ID_award
ORDER BY A.Year DESC;

-- Vista 5 usuarios
CREATE VIEW V_USER_ACTIVITY AS
SELECT UA.Username, M.Title, TR.Rating, TR.Rating_Date, TV.View_Date, TV.Duration_Watched
FROM USER_ACCOUNT UA
JOIN TRANSACTION_RATING TR ON UA.ID_user = TR.User_ID
JOIN MOVIE M ON TR.ID_movie = M.ID_movie
LEFT JOIN TRANSACTION_VIEW TV ON UA.ID_user = TV.User_ID AND M.ID_movie = TV.ID_movie
ORDER BY TR.Rating_Date DESC;

-- STORED PROCEDURES
-- SP 1 Agregar nueva película e ingresos
DELIMITER //

CREATE PROCEDURE AddMovieAndProfit(
    IN p_Title VARCHAR(100),
    IN p_Original_title VARCHAR(100),
    IN p_Genre VARCHAR(100),
    IN p_Keyword VARCHAR(100),
    IN p_Overview TEXT,
    IN p_Tagline TEXT,
    IN p_Runtime TIME,
    IN p_Language VARCHAR(100),
    IN p_Release_date DATETIME,
    IN p_Revenue INT,
    IN p_Budget INT
)
BEGIN
    DECLARE new_movie_id INT;

    -- Insertar la nueva película en la tabla MOVIE
    INSERT INTO MOVIE (Title, Original_title, Genre, Keyword, Overview, Tagline, Runtime, Language, Release_date)
    VALUES (p_Title, p_Original_title, p_Genre, p_Keyword, p_Overview, p_Tagline, p_Runtime, p_Language, p_Release_date);

    -- Obtener el ID de la película recién insertada
    SET new_movie_id = LAST_INSERT_ID();

    -- Insertar los datos de ingresos y presupuesto en la tabla PROFIT
    INSERT INTO PROFIT (ID_movie, Revenue, Budget)
    VALUES (new_movie_id, p_Revenue, p_Budget);
END //

DELIMITER ;

-- SP 2 Actualizar ingresos
DELIMITER //

CREATE PROCEDURE UpdateMovieRevenue(
    IN p_ID_movie INT,
    IN p_NewRevenue DECIMAL(15,2),
    IN p_NewBudget DECIMAL(15,2)
)
BEGIN
    -- Actualiza los ingresos y presupuesto de la película en la tabla PROFIT
    UPDATE PROFIT
    SET Revenue = p_NewRevenue,
        Budget = p_NewBudget
    WHERE ID_movie = p_ID_movie;

    END //

DELIMITER ;



-- FUNCIONES
-- FUNCION 1 Promedio rating
DELIMITER //

CREATE FUNCTION CalculateAverageRating(p_ID_movie INT)
RETURNS DECIMAL(3,1)
DETERMINISTIC
BEGIN
    DECLARE avg_rating DECIMAL(3,1);

    -- Calcular el promedio de calificaciones para la película especificada
    SELECT AVG(Score) INTO avg_rating
    FROM RATING
    WHERE ID_movie = p_ID_movie;

    RETURN avg_rating;
END //

DELIMITER ;

-- FUNCION 2 Margen de ganancia
DELIMITER //

CREATE FUNCTION GetMovieProfitMargin(p_ID_movie INT)
RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE profit_margin DECIMAL(5,2);
    DECLARE movie_revenue INT;
    DECLARE movie_budget INT;

    -- Obtener el ingreso y presupuesto de la película
    SELECT Revenue, Budget INTO movie_revenue, movie_budget
    FROM PROFIT
    WHERE ID_movie = p_ID_movie;

    -- Calcular el margen de ganancia
    IF movie_revenue > 0 THEN
        SET profit_margin = (movie_revenue - movie_budget) / movie_revenue * 100;
    ELSE
        SET profit_margin = 0;
    END IF;

    RETURN profit_margin;
END //

DELIMITER ;

-- TRIGGERS
-- Trigger 1 duración película
DELIMITER //

CREATE TRIGGER before_insert_transaction_view
BEFORE INSERT ON TRANSACTION_VIEW
FOR EACH ROW
BEGIN
    DECLARE movie_runtime TIME;

    -- Obtener la duración total de la película desde la tabla MOVIE
    SELECT Runtime INTO movie_runtime
    FROM MOVIE
    WHERE ID_movie = NEW.ID_movie;

    -- Validar que la duración de visualización no sea mayor que la duración total de la película
    IF NEW.Duration_Watched > movie_runtime THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: La duración de visualización no puede ser mayor que la duración total de la película.';
    END IF;
END //

DELIMITER ;

-- trigger 2 eliminar pelicula
DELIMITER //

CREATE TRIGGER before_delete_movie
BEFORE DELETE ON MOVIE
FOR EACH ROW
BEGIN
    DECLARE associated_records INT;

    -- Verificar si existen registros asociados en MOVIE_ACTOR
    SELECT COUNT(*) INTO associated_records
    FROM MOVIE_ACTOR
    WHERE ID_movie = OLD.ID_movie;

    IF associated_records > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: No se puede eliminar la película porque tiene actores asociados.';
    END IF;

    -- Verificar si existen registros asociados en MOVIE_DIRECTOR
    SELECT COUNT(*) INTO associated_records
    FROM MOVIE_DIRECTOR
    WHERE ID_movie = OLD.ID_movie;

    IF associated_records > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: No se puede eliminar la película porque tiene directores asociados.';
    END IF;

    -- Verificar si existen registros asociados en FACT_SALES
    SELECT COUNT(*) INTO associated_records
    FROM FACT_SALES
    WHERE ID_movie = OLD.ID_movie;

    IF associated_records > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: No se puede eliminar la película porque tiene datos de ventas asociados.';
    END IF;

END //

DELIMITER ;











