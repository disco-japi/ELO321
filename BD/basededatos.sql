DROP DATABASE IF EXISTS telefactory;
CREATE DATABASE telefactory;
USE telefactory;



-- Se decidio crear la super entidad persona y las subentidades usuario e administrador haciendo uso de herencia
CREATE TABLE Persona(
    rut VARCHAR(12) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    email VARCHAR(50) NOT NULL,
    nombre_usuario VARCHAR(50) UNIQUE NOT NULL,
    contrasena VARCHAR(255) NOT NULL
);

CREATE TABLE Usuario(
    rut VARCHAR(12) PRIMARY KEY,
    FOREIGN KEY (rut) REFERENCES Persona(rut)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Administrador(
    rut VARCHAR(12) PRIMARY KEY,
    FOREIGN KEY (rut) REFERENCES Persona(rut)
        ON DELETE CASCADE ON UPDATE CASCADE
);


DELIMITER //

--triggers para impedir que un usuario sea administrador y tambien que un administrador sea usuario
CREATE TRIGGER trg_usuario BEFORE INSERT ON Usuario FOR EACH ROW 
BEGIN 
    IF EXISTS (SELECT 1 FROM Administrador WHERE rut = NEW.rut) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RUT ya detectado en un administrador, no es posible usarlo';
    END IF;
END;
//

CREATE TRIGGER trg_administrador BEFORE INSERT ON Administrador FOR EACH ROW 
BEGIN 
    IF EXISTS (SELECT 1 FROM Usuario WHERE rut = NEW.rut) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RUT ya detectado en un usuario, no es posible usarlo';
    END IF;
END;
//

DELIMITER ;

--tabla de gestion de compra
CREATE TABLE GestionErrores(
    id INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(100) UNIQUE NOT NULL,
    descripcion VARCHAR(200) NOT NULL,
    fecha_publicacion DATE NOT NULL,
    topico_id INT NOT NULL,
    autor_rut VARCHAR(12) NOT NULL,
    estado_id INT NOT NULL,
    FOREIGN KEY (topico_id) REFERENCES Topicos(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (autor_rut) REFERENCES Usuario(rut) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (estado_id) REFERENCES Estado(id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE Resena_Error(
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_error INT NOT NULL,
    rut_administrador VARCHAR(12) NOT NULL,
    observacion TEXT NOT NULL,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_error) REFERENCES GestionErrores(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (rut_administrador) REFERENCES Administrador(rut) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_error, rut_administrador) REFERENCES Asignacion_Error(id_error, rut_administrador) ON DELETE CASCADE ON UPDATE CASCADE
);

--procedimiento de registrar una persona
DELIMITER //

CREATE PROCEDURE registrar_persona(IN p_rut VARCHAR(12), IN p_nombre VARCHAR(50), IN p_email VARCHAR(50), IN p_nombre_usuario VARCHAR(50), IN p_contrasena VARCHAR(255), IN p_rol VARCHAR(20)) 
BEGIN 
    INSERT INTO Persona (rut, nombre, email, nombre_usuario, contrasena) VALUES (p_rut, p_nombre, p_email, p_nombre_usuario, p_contrasena);
    IF p_rol = 'usuario' THEN INSERT INTO Usuario (rut) VALUES (p_rut);
    ELSEIF p_rol = 'administrador' THEN INSERT INTO Administrador (rut) VALUES (p_rut);
    ELSE SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Rol incorrecto, debe ser usuario o administrador';
    END IF;
END;
//

-- funcion para validar el loggin
CREATE FUNCTION validador_login (p_nombre_usuario VARCHAR(50), p_contrasena VARCHAR(255)) RETURNS VARCHAR(20) DETERMINISTIC 
BEGIN 
    DECLARE v_rut VARCHAR(12); 
    DECLARE v_rol VARCHAR(20);
    SELECT rut INTO v_rut FROM Persona WHERE nombre_usuario = p_nombre_usuario AND contrasena = p_contrasena;
    IF v_rut IS NULL THEN RETURN 'No existe';
    END IF;
    IF EXISTS (SELECT 1 FROM Administrador WHERE rut = v_rut) THEN SET v_rol = 'Administrador';
    ELSEIF EXISTS (SELECT 1 FROM Usuario WHERE rut = v_rut) THEN SET v_rol = 'Usuario';
    ELSE SET v_rol = 'SinRol';
    END IF;
    RETURN v_rol;
END;
//

--procedimentos CRUD para las funcinalidades

-- PROCEDIMIENTROS CRUD DE LAS SOLICITUDES


--procedimiento para CREATE del error
CREATE PROCEDURE registrar_error(IN p_titulo VARCHAR(100), IN p_descripcion VARCHAR(200), IN p_autor_rut VARCHAR(12), IN p_topico_id INT, IN p_estado_id INT)
BEGIN
    IF CHAR_LENGTH(p_descripcion) > 200 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El maximo de caracteres en la descripcion es 200';
    END IF;
    INSERT INTO GestionErrores (titulo, descripcion, fecha_publicacion, topico_id, autor_rut, estado_id) VALUES (p_titulo, p_descripcion, CURDATE(), p_topico_id, p_autor_rut, p_estado_id);
END;
//

--procedimiento para el READ del error

CREATE PROCEDURE leer_error_usuario(IN p_id_error INT, IN p_autor_rut VARCHAR(12))
BEGIN
    IF NOT EXISTS (SELECT 1 FROM GestionErrores WHERE id = p_id_error AND autor_rut = p_autor_rut) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error no encontrado o no tiene permisos para verlo';
    END IF;

    SELECT  ge.id, ge.titulo, ge.descripcion, t.nombre AS topico, t.id AS topico_id, e.nombre AS estado, e.id AS estado_id, ge.fecha_publicacion, p.nombre AS autor, ge.autor_rut
    FROM GestionErrores ge
    JOIN Topicos t ON ge.topico_id = t.id
    JOIN Estado e ON ge.estado_id = e.id
    JOIN Persona p ON ge.autor_rut = p.rut
    WHERE ge.id = p_id_error;
END;
//

-- procedimineto para el UPDATE de errores
CREATE PROCEDURE actualizar_error(IN p_id_error INT, IN p_titulo VARCHAR(100), IN p_descripcion VARCHAR(200), IN p_estado_id INT, IN p_autor_rut VARCHAR(12))
BEGIN
    DECLARE v_estado_actual VARCHAR(50);
    IF CHAR_LENGTH(p_descripcion) > 200 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El máximo de caracteres en la descripción es 200';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM GestionErrores WHERE id = p_id_error AND autor_rut = p_autor_rut) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error no encontrado o no tiene permisos para modificarlo';
    END IF;

    SELECT e.nombre INTO v_estado_actual FROM GestionErrores ge JOIN Estado e ON ge.estado_id = e.id WHERE ge.id = p_id_error;
    IF v_estado_actual = 'En Progreso' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede modificar un error en estado "En Progreso"';
    END IF;

    UPDATE GestionErrores 
    SET titulo = p_titulo, descripcion = p_descripcion, estado_id = p_estado_id WHERE id = p_id_error;
END;
//

--proceso para el DELETE de error

CREATE PROCEDURE eliminar_error(IN p_id_error INT, IN p_autor_rut VARCHAR(12))
BEGIN
    DECLARE v_estado_actual VARCHAR(50);
    IF NOT EXISTS (SELECT 1 FROM GestionErrores WHERE id = p_id_error AND autor_rut = p_autor_rut) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error no encontrado o no tiene permisos para eliminarlo';
    END IF;

    SELECT e.nombre INTO v_estado_actual FROM GestionErrores ge JOIN Estado e ON ge.estado_id = e.id WHERE ge.id = p_id_error;
    IF v_estado_actual = 'En Progreso' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar un error en estado "En Progreso"';
    END IF;

    DELETE FROM GestionErrores WHERE id = p_id_error;
END;
//


DELIMITER ;
--vista para todas las compras de un usuario
CREATE VIEW Vista_Compras_Usuario AS SELECT u.rut AS rut_usuario, p.nombre AS nombre_usuario, 'Funcionalidad' AS tipo, sf.id AS id_elemento, sf.titulo AS titulo, sf.resumen AS descripcion, t.nombre AS topico, e.nombre AS estado, sf.fecha_creacion AS fecha
FROM SolicitudesFuncionalidad sf
JOIN Usuario u ON sf.solicitante_rut = u.rut
JOIN Persona p ON u.rut = p.rut
JOIN Topicos t ON sf.topico_id = t.id
JOIN Estado e ON sf.estado_id = e.id
UNION ALL
SELECT u.rut AS rut_usuario, p.nombre AS nombre_usuario, 'Error' AS tipo, ge.id AS id_elemento, ge.titulo AS titulo, ge.descripcion AS descripcion, NULL AS ambiente, t.nombre AS topico, e.nombre AS estado, ge.fecha_publicacion AS fecha
FROM GestionErrores ge
JOIN Usuario u ON ge.autor_rut = u.rut
JOIN Persona p ON u.rut = p.rut
JOIN Topicos t ON ge.topico_id = t.id
JOIN Estado e ON ge.estado_id = e.id;

INSERT INTO `Topicos` (`id`, `nombre`) VALUES
(1, 'Hardware'),
(2, 'Software'),
(3, 'UX/UI');

INSERT INTO `Estado` (`id`, `nombre`) VALUES
(1, 'En logistica'),
(2, 'En camino'),
(3, 'Recibido');
(4, 'Confirmado'),

-- ==== USUARIOS ====
CALL registrar_persona('11111111-1', 'Carlos Peña', 'carlos.pena@example.com', 'cpena', '1234', 'usuario') ;
CALL registrar_persona('11111112-2', 'María Soto', 'maria.soto@example.com', 'msoto', '1234', 'usuario') ;
CALL registrar_persona('11111113-3', 'Luis Herrera', 'luis.herrera@example.com', 'lherrera', '1234', 'usuario') ;
CALL registrar_persona('11111114-4', 'Ana Fuentes', 'ana.fuentes@example.com', 'afuentes', '1234', 'usuario') ;
CALL registrar_persona('11111115-5', 'Pedro Rojas', 'pedro.rojas@example.com', 'projas', '1234', 'usuario') ;
CALL registrar_persona('11111116-6', 'Camila Díaz', 'camila.diaz@example.com', 'cdiaz', '1234', 'usuario') ;
CALL registrar_persona('11111117-7', 'Francisco Muñoz', 'francisco.munoz@example.com', 'fmunoz', '1234', 'usuario') ;
CALL registrar_persona('11111118-8', 'Paula González', 'paula.gonzalez@example.com', 'pgonzalez', '1234', 'usuario') ;
CALL registrar_persona('11111119-9', 'Diego Vargas', 'diego.vargas@example.com', 'dvargas', '1234', 'usuario') ;
CALL registrar_persona('11111120-K', 'Rosa Castillo', 'rosa.castillo@example.com', 'rcastillo', '1234', 'usuario') ;
CALL registrar_persona('11111121-1', 'Nicolás Pino', 'nicolas.pino@example.com', 'npino', '1234', 'usuario') ;
CALL registrar_persona('11111122-2', 'Isabel Bravo', 'isabel.bravo@example.com', 'ibravo', '1234', 'usuario') ;
CALL registrar_persona('11111123-3', 'Tomás Leiva', 'tomas.leiva@example.com', 'tleiva', '1234', 'usuario') ;
CALL registrar_persona('11111124-4', 'Valentina Pérez', 'valentina.perez@example.com', 'vperez', '1234', 'usuario') ;
CALL registrar_persona('11111125-5', 'Matías Castro', 'matias.castro@example.com', 'mcastro', '1234', 'usuario') ;
CALL registrar_persona('11111126-6', 'Fernanda Torres', 'fernanda.torres@example.com', 'ftorres', '1234', 'usuario') ;
CALL registrar_persona('11111127-7', 'Javier Reyes', 'javier.reyes@example.com', 'jreyes', '1234', 'usuario') ;
CALL registrar_persona('11111128-8', 'Sofía Navarro', 'sofia.navarro@example.com', 'snavarro', '1234', 'usuario') ;
CALL registrar_persona('11111129-9', 'Ignacio Cabrera', 'ignacio.cabrera@example.com', 'icabrera', '1234', 'usuario') ;
CALL registrar_persona('11111130-K', 'Daniela Morales', 'daniela.morales@example.com', 'dmorales', '1234', 'usuario') ;

-- ==== INGENIEROS ====
CALL registrar_persona('22222221-1', 'Rodrigo López', 'rodrigo.lopez@example.com', 'rlopez', '1234', 'administrador') ;
CALL registrar_persona('22222222-2', 'María Contreras', 'maria.contreras@example.com', 'mcontreras', '1234', 'administrador') ;
CALL registrar_persona('22222223-3', 'Felipe Navarro', 'felipe.navarro@example.com', 'fnavarro', '1234', 'administrador') ;
CALL registrar_persona('22222224-4', 'Carolina Vega', 'carolina.vega@example.com', 'cvega', '1234', 'administrador') ;
CALL registrar_persona('22222225-5', 'Jorge Díaz', 'jorge.diaz@example.com', 'jdiaz', '1234', 'administrador') ;
CALL registrar_persona('22222226-6', 'Francisca Romero', 'francisca.romero@example.com', 'fromero', '1234', 'administrador') ;
CALL registrar_persona('22222227-7', 'Ricardo Pérez', 'ricardo.perez@example.com', 'rperez', '1234', 'administrador') ;
CALL registrar_persona('22222228-8', 'Natalia Fuentes', 'natalia.fuentes@example.com', 'nfuentes', '1234', 'administrador') ;
CALL registrar_persona('22222229-9', 'Claudio Ramírez', 'claudio.ramirez@example.com', 'cramirez', '1234', 'administrador') ;
CALL registrar_persona('22222230-K', 'Beatriz Silva', 'beatriz.silva@example.com', 'bsilva', '1234', 'administrador') ;
CALL registrar_persona('22222231-1', 'Gonzalo Torres', 'gonzalo.torres@example.com', 'gtorres', '1234', 'administrador') ;
CALL registrar_persona('22222232-2', 'Andrea Paredes', 'andrea.paredes@example.com', 'aparedes', '1234', 'administrador') ;
CALL registrar_persona('22222233-3', 'Cristóbal Herrera', 'cristobal.herrera@example.com', 'cherrera', '1234', 'administrador') ;
CALL registrar_persona('22222234-4', 'Camila Vargas', 'camila.vargas@example.com', 'cvargas', '1234', 'administrador') ;
CALL registrar_persona('22222235-5', 'Sebastián Reyes', 'sebastian.reyes@example.com', 'sreyes', '1234', 'administrador') ;
CALL registrar_persona('22222236-6', 'Patricia Orellana', 'patricia.orellana@example.com', 'porellana', '1234', 'administrador') ;
CALL registrar_persona('22222237-7', 'Mauricio Salazar', 'mauricio.salazar@example.com', 'msalazar', '1234', 'administrador') ;
CALL registrar_persona('22222238-8', 'Constanza Leiva', 'constanza.leiva@example.com', 'cleiva', '1234', 'administrador') ;
CALL registrar_persona('22222239-9', 'Álvaro Bravo', 'alvaro.bravo@example.com', 'abravo', '1234', 'administrador') ;
CALL registrar_persona('22222240-K', 'Lucía Cornejo', 'lucia.cornejo@example.com', 'lcornejo', '1234', 'administrador') ;