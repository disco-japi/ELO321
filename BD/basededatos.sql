-- se borra la DB si existia para hacer facil las pruebas y se crea una nueva llamada basesita
DROP DATABASE IF EXISTS basesita;
CREATE DATABASE basesita;
USE basesita;

-- importante rellenar estas tablas primero para el correcto funcionamiento de todo
-- como pasamos de posrgre a mysql, se decio crear estas tablas para almacenar los topicos y los ambientes
CREATE TABLE Ambientes(
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(30) UNIQUE NOT NULL
);

CREATE TABLE Topicos(
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE Estado(
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL
);

-- Se decidio crear la super entidad persona y las subentidades usuario e ingeniero haciendo uso de herencia
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

CREATE TABLE Ingeniero(
    rut VARCHAR(12) PRIMARY KEY,
    FOREIGN KEY (rut) REFERENCES Persona(rut)
        ON DELETE CASCADE ON UPDATE CASCADE
);


DELIMITER //

--triggers para impedir que un usuario sea ingeniero y tambien que un ingeniero sea usuario
CREATE TRIGGER trg_usuario BEFORE INSERT ON Usuario FOR EACH ROW 
BEGIN 
    IF EXISTS (SELECT 1 FROM Ingeniero WHERE rut = NEW.rut) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RUT ya detectado en un ingeniero, no es posible usarlo';
    END IF;
END;
//

CREATE TRIGGER trg_ingeniero BEFORE INSERT ON Ingeniero FOR EACH ROW 
BEGIN 
    IF EXISTS (SELECT 1 FROM Usuario WHERE rut = NEW.rut) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RUT ya detectado en un usuario, no es posible usarlo';
    END IF;
END;
//

DELIMITER ;

-- tabla de union entre Ingeniero y Topico
CREATE TABLE Ingeniero_Topico(
    rut_ingeniero VARCHAR(12) NOT NULL,
    id_topico INT NOT NULL,
    PRIMARY KEY (rut_ingeniero, id_topico),
    FOREIGN KEY (rut_ingeniero) REFERENCES Ingeniero(rut) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_topico) REFERENCES Topicos(id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- tablas de funcionalidad
CREATE TABLE SolicitudesFuncionalidad(
    id INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(100) UNIQUE NOT NULL,
    ambiente_id INT NOT NULL,
    resumen VARCHAR(150) NOT NULL,
    topico_id INT NOT NULL,
    solicitante_rut VARCHAR(12) NOT NULL,
    estado_id INT NOT NULL,
    fecha_creacion DATE NOT NULL,
    FOREIGN KEY (ambiente_id) REFERENCES Ambientes(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (topico_id) REFERENCES Topicos(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (estado_id) REFERENCES Estado(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (solicitante_rut) REFERENCES Usuario(rut) ON DELETE CASCADE ON UPDATE CASCADE
);

--tabla para hacer cumplir lo de los criterios de aceptacion
CREATE TABLE CriteriosAceptacion(
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_funcionalidad INT NOT NULL,
    descripcion VARCHAR(150) NOT NULL,
    FOREIGN KEY (id_funcionalidad) REFERENCES SolicitudesFuncionalidad(id) ON DELETE CASCADE ON UPDATE CASCADE
);

--tabla de gestion de errores
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

-- tablas de asignacion de funcionalidades y errores, resultado de la normalizacion de Asignacion
CREATE TABLE Asignacion_Funcionalidad(
    id_funcionalidad INT NOT NULL,
    rut_ingeniero VARCHAR(12) NOT NULL,
    fecha_asignacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_funcionalidad, rut_ingeniero),
    FOREIGN KEY (id_funcionalidad) REFERENCES SolicitudesFuncionalidad(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (rut_ingeniero) REFERENCES Ingeniero(rut) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Asignacion_Error(
    id_error INT NOT NULL,
    rut_ingeniero VARCHAR(12) NOT NULL,
    fecha_asignacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_error, rut_ingeniero),
    FOREIGN KEY (id_error) REFERENCES GestionErrores(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (rut_ingeniero) REFERENCES Ingeniero(rut) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Resena_Funcionalidad(
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_funcionalidad INT NOT NULL,
    rut_ingeniero VARCHAR(12) NOT NULL,
    observacion TEXT NOT NULL,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_funcionalidad) REFERENCES SolicitudesFuncionalidad(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (rut_ingeniero) REFERENCES Ingeniero(rut) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_funcionalidad, rut_ingeniero) REFERENCES Asignacion_Funcionalidad(id_funcionalidad, rut_ingeniero) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Resena_Error(
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_error INT NOT NULL,
    rut_ingeniero VARCHAR(12) NOT NULL,
    observacion TEXT NOT NULL,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_error) REFERENCES GestionErrores(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (rut_ingeniero) REFERENCES Ingeniero(rut) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_error, rut_ingeniero) REFERENCES Asignacion_Error(id_error, rut_ingeniero) ON DELETE CASCADE ON UPDATE CASCADE
);


DELIMITER //

--se crean estos triggers y funciones para hacer cumplir lo indicado en la tarea 1
-- 1. se asignaran maximo 3 ingenieros por funcionalidad/error
-- 2. un ingeniero puede tener maximo 20 asignaciones
-- 3. un usuario puede publicar un maximo de 25 errores y funcionalidades


-- se crea esta funcion para usarla en los triggers de limites de 20 asignaciones a cada ingeniero en total sumando funcionalidades y errores
CREATE FUNCTION limitante_asignacion(p_rut VARCHAR(12)) RETURNS BOOLEAN DETERMINISTIC 
BEGIN 
    DECLARE total INT;
    SELECT ((SELECT COUNT(*) FROM Asignacion_Funcionalidad WHERE rut_ingeniero = p_rut) +
            (SELECT COUNT(*) FROM Asignacion_Error WHERE rut_ingeniero = p_rut)) INTO total;
    RETURN total >= 20;
END;
//

-- esta funcion sirve para contar la cantidad de ingeniros asignados a un error o solicitud y usarlo en los triggers de trg_maximo_tres_ingenieros_funcionalidad y trg_maximo_tres_ingenieros_error
CREATE FUNCTION contador_ingenieros(p_tipo VARCHAR(20), p_id INT) RETURNS INT DETERMINISTIC 
BEGIN 
    DECLARE total INT DEFAULT 0;
    IF p_tipo = 'funcionalidad' THEN SELECT COUNT(*) INTO total FROM Asignacion_Funcionalidad WHERE id_funcionalidad = p_id;
    ELSEIF p_tipo = 'error' THEN SELECT COUNT(*) INTO total FROM Asignacion_Error WHERE id_error = p_id;
    END IF;
    RETURN total;
END;
//

-- trigger para cumplir el limite de 20 asignaciones veindo la tabla de funcionalidades
CREATE TRIGGER trg_maximo_funcionalidad BEFORE INSERT ON Asignacion_Funcionalidad FOR EACH ROW 
BEGIN 
    IF limitante_asignacion(NEW.rut_ingeniero) THEN  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Limite de asignaciones por ingeniero alcanzado (20)';
    END IF;
END;
//

-- lo mismo que la anterior pero para las errores
CREATE TRIGGER trg_maximo_error BEFORE INSERT ON Asignacion_Error FOR EACH ROW 
BEGIN 
    IF limitante_asignacion(NEW.rut_ingeniero) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Limite de asignaciones por ingeniero alcanzado (20)';
    END IF;
END;
//

-- trigger para el maximo de 25 de funcionalidades por usuario
CREATE TRIGGER trg_maximo_funcionalidades_usuarios BEFORE INSERT ON SolicitudesFuncionalidad FOR EACH ROW 
BEGIN 
    DECLARE num_func INT;
    SELECT COUNT(*) INTO num_func FROM SolicitudesFuncionalidad WHERE solicitante_rut = NEW.solicitante_rut AND DATE(fecha_creacion) = DATE(NEW.fecha_creacion);
    IF num_func >= 25 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'maximo de solicitudes de funcionalidades por usuario alcanzado (25)';
    END IF;
END;
//

-- lo mismo que la anterior pero para los 25 errores
CREATE TRIGGER trg_maximo_errores_usuario BEFORE INSERT ON GestionErrores FOR EACH ROW 
BEGIN 
    DECLARE num_err INT;
    SELECT COUNT(*) INTO num_err FROM GestionErrores WHERE autor_rut = NEW.autor_rut AND DATE(fecha_publicacion) = DATE(NEW.fecha_publicacion);
    IF num_err >= 25 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'maximo de solicitudes de errores por usuario alcanzado (25)';
    END IF;
END;
//

--procedimento para asignar automaticamente a una funcionalidad un ingeniero
CREATE PROCEDURE asignar_ingenieros_funcionalidad(IN p_id_funcionalidad INT)
BEGIN 
    DECLARE v_topico INT; 
    SELECT topico_id INTO v_topico FROM SolicitudesFuncionalidad WHERE id = p_id_funcionalidad;
    INSERT INTO Asignacion_Funcionalidad (id_funcionalidad, rut_ingeniero) SELECT p_id_funcionalidad, e.rut FROM Ingeniero e JOIN Ingeniero_Topico it ON e.rut = it.rut_ingeniero WHERE it.id_topico = v_topico ORDER BY ((SELECT COUNT(*) FROM Asignacion_Funcionalidad af WHERE af.rut_ingeniero = e.rut) + (SELECT COUNT(*) FROM Asignacion_Error ae WHERE ae.rut_ingeniero = e.rut)), RAND()LIMIT 3;
END;
//
--lo mismo que el de arriba pero para los errores
CREATE PROCEDURE asignar_ingenieros_error(IN p_id_error INT)
BEGIN 
    DECLARE v_topico INT;
    SELECT topico_id INTO v_topico FROM GestionErrores WHERE id = p_id_error;
    INSERT INTO Asignacion_Error (id_error, rut_ingeniero) SELECT p_id_error, e.rut FROM Ingeniero e JOIN Ingeniero_Topico it ON e.rut = it.rut_ingeniero WHERE it.id_topico = v_topico ORDER BY ((SELECT COUNT(*) FROM Asignacion_Funcionalidad af WHERE af.rut_ingeniero = e.rut) + (SELECT COUNT(*) FROM Asignacion_Error ae WHERE ae.rut_ingeniero = e.rut)), RAND() LIMIT 3;
END;
//

--ahora el trigger para hacer uso del procedimiento de autoasignado de funcionalidades 
CREATE TRIGGER trg_auto_asignar_funcionalidad AFTER INSERT ON SolicitudesFuncionalidad FOR EACH ROW 
BEGIN 
    CALL asignar_ingenieros_funcionalidad(NEW.id);
END;
//

--lo mismo que arriba pero para autoasginar en errores
CREATE TRIGGER trg_auto_asignar_error AFTER INSERT ON GestionErrores FOR EACH ROW 
BEGIN 
    CALL asignar_ingenieros_error(NEW.id);
END;
//

-- trigger para el maximo de 3 ingenieros asignados a una funcion
CREATE TRIGGER trg_maximo_tres_ingenieros_funcionalidad AFTER INSERT ON Asignacion_Funcionalidad FOR EACH ROW 
BEGIN
    IF contador_ingenieros('funcionalidad', NEW.id_funcionalidad) > 3 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El maximo por funcionalidad son 3 ingenieros';
    END IF;
END;
//

--lo mismo que el trigger anterior pero en los errores
CREATE TRIGGER trg_maximo_tres_ingenieros_error AFTER INSERT ON Asignacion_Error FOR EACH ROW 
BEGIN
    IF contador_ingenieros('error', NEW.id_error) > 3 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El maximo por error es 3 ingenieros';
    END IF;
END;
//

DELIMITER ;

--procedimiento de registrar una persona
DELIMITER //

CREATE PROCEDURE registrar_persona(IN p_rut VARCHAR(12), IN p_nombre VARCHAR(50), IN p_email VARCHAR(50), IN p_nombre_usuario VARCHAR(50), IN p_contrasena VARCHAR(255), IN p_rol VARCHAR(20)) 
BEGIN 
    INSERT INTO Persona (rut, nombre, email, nombre_usuario, contrasena) VALUES (p_rut, p_nombre, p_email, p_nombre_usuario, p_contrasena);
    IF p_rol = 'usuario' THEN INSERT INTO Usuario (rut) VALUES (p_rut);
    ELSEIF p_rol = 'ingeniero' THEN INSERT INTO Ingeniero (rut) VALUES (p_rut);
    ELSE SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Rol incorrecto, debe ser usuario o ingeniero';
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
    IF EXISTS (SELECT 1 FROM Ingeniero WHERE rut = v_rut) THEN SET v_rol = 'Ingeniero';
    ELSEIF EXISTS (SELECT 1 FROM Usuario WHERE rut = v_rut) THEN SET v_rol = 'Usuario';
    ELSE SET v_rol = 'SinRol';
    END IF;
    RETURN v_rol;
END;
//

--procedimentos CRUD para las funcinalidades

-- procediemento de creacion o registro
CREATE PROCEDURE registrar_funcionalidad(IN p_titulo VARCHAR(100), IN p_descripcion TEXT, IN p_solicitante_rut VARCHAR(12), IN p_ambiente_id INT, IN p_topico_id INT, IN p_estado_id INT, IN p_criterio1 VARCHAR(150), IN p_criterio2 VARCHAR(150), IN p_criterio3 VARCHAR(150))
BEGIN
    DECLARE v_id_funcionalidad INT;
    INSERT INTO SolicitudesFuncionalidad (titulo, resumen, fecha_creacion, solicitante_rut, ambiente_id, topico_id, estado_id) VALUES (p_titulo, p_descripcion, CURDATE(), p_solicitante_rut, p_ambiente_id, p_topico_id, p_estado_id);
    SET v_id_funcionalidad = LAST_INSERT_ID();
    INSERT INTO CriteriosAceptacion (id_funcionalidad, descripcion) VALUES (v_id_funcionalidad, p_criterio1), (v_id_funcionalidad, p_criterio2), (v_id_funcionalidad, p_criterio3);
END;
//

-- PROCEDIMIENTROS CRUD DE LAS SOLICITUDES

--procedimiento para el READ o lectura de funcionalidad
CREATE PROCEDURE leer_funcionalidad_usuario(
    IN p_id_funcionalidad INT,
    IN p_solicitante_rut VARCHAR(12)
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM SolicitudesFuncionalidad  WHERE id = p_id_funcionalidad AND solicitante_rut = p_solicitante_rut) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Funcionalidad no encontrada o no tiene permisos para verla';
    END IF;

    SELECT sf.id, sf.titulo, sf.resumen, a.nombre AS ambiente, a.id AS ambiente_id, t.nombre AS topico, t.id AS topico_id, e.nombre AS estado, e.id AS estado_id, sf.fecha_creacion, p.nombre AS solicitante, sf.solicitante_rut
    FROM SolicitudesFuncionalidad sf
    JOIN Ambientes a ON sf.ambiente_id = a.id
    JOIN Topicos t ON sf.topico_id = t.id
    JOIN Estado e ON sf.estado_id = e.id
    JOIN Persona p ON sf.solicitante_rut = p.rut
    WHERE sf.id = p_id_funcionalidad;
    SELECT id, descripcion FROM CriteriosAceptacion WHERE id_funcionalidad = p_id_funcionalidad ORDER BY id;
END;
//

--procediimeinto para el UPDATE o modificacion de funcionalidad
CREATE PROCEDURE modificar_funcionalidad(IN p_id_funcionalidad INT, IN p_solicitante_rut VARCHAR(12), IN p_titulo VARCHAR(100), IN p_descripcion TEXT, IN p_ambiente_id INT, IN p_estado_id INT, IN p_criterio1 VARCHAR(150), IN p_criterio2 VARCHAR(150), IN p_criterio3 VARCHAR(150))
BEGIN
    DECLARE v_estado_nombre VARCHAR(50);
    IF NOT EXISTS (SELECT 1 FROM SolicitudesFuncionalidad WHERE id = p_id_funcionalidad AND solicitante_rut = p_solicitante_rut) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No puede modificar una solicitud que no le pertenece.';
    END IF;

    SELECT E.nombre INTO v_estado_nombre FROM SolicitudesFuncionalidad SF JOIN Estado E ON SF.estado_id = E.id WHERE SF.id = p_id_funcionalidad;
    IF v_estado_nombre = 'En Progreso' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Esta prohibido modificar una solicitud en progreso.';
    END IF;

    UPDATE SolicitudesFuncionalidad
    SET titulo = p_titulo, resumen = p_descripcion, ambiente_id = p_ambiente_id, estado_id = p_estado_id WHERE id = p_id_funcionalidad;

    DELETE FROM CriteriosAceptacion WHERE id_funcionalidad = p_id_funcionalidad;
    INSERT INTO CriteriosAceptacion (id_funcionalidad, descripcion) VALUES (p_id_funcionalidad, p_criterio1), (p_id_funcionalidad, p_criterio2), (p_id_funcionalidad, p_criterio3);
END;
//

--prodecimiento para el DELETE o eliminacion de funcionalidad
CREATE PROCEDURE eliminar_funcionalidad(IN p_id_funcionalidad INT, IN p_solicitante_rut VARCHAR(12))
BEGIN
    DECLARE v_estado_nombre VARCHAR(50);
    IF NOT EXISTS (SELECT 1 FROM SolicitudesFuncionalidad WHERE id = p_id_funcionalidad AND solicitante_rut = p_solicitante_rut) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No puede eliminar una solicitud que no le pertenece.';
    END IF;

    SELECT E.nombre INTO v_estado_nombre FROM SolicitudesFuncionalidad SF JOIN Estado E ON SF.estado_id = E.id WHERE SF.id = p_id_funcionalidad;
    IF v_estado_nombre = 'En Progreso' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Imposible de eliminar, la funcionalidad se encuebntra en progreso.';
    END IF;

    DELETE FROM CriteriosAceptacion WHERE id_funcionalidad = p_id_funcionalidad;
    DELETE FROM SolicitudesFuncionalidad WHERE id = p_id_funcionalidad;
END;
//


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

-- procedimiento para CREATE reseña de funcionalidad
CREATE PROCEDURE crear_resena_funcionalidad(IN p_id_funcionalidad INT, IN p_rut_ingeniero VARCHAR(12), IN p_observacion TEXT)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Asignacion_Funcionalidad WHERE id_funcionalidad = p_id_funcionalidad AND rut_ingeniero = p_rut_ingeniero) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No tiene permisos para agregar reseñas a esta funcionalidad';
    END IF;
    INSERT INTO Resena_Funcionalidad (id_funcionalidad, rut_ingeniero, observacion) VALUES (p_id_funcionalidad, p_rut_ingeniero, p_observacion);
END;
//

--procedimiento para UPDATE reseña de funcionalidad
CREATE PROCEDURE actualizar_resena_funcionalidad(IN p_id_resena INT, IN p_rut_ingeniero VARCHAR(12), IN p_nueva_observacion TEXT)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Resena_Funcionalidad WHERE id = p_id_resena AND rut_ingeniero = p_rut_ingeniero) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reseña no encontrada o no tiene permisos para modificarla';
    END IF;
    
    UPDATE Resena_Funcionalidad 
    SET observacion = p_nueva_observacion, fecha_actualizacion = CURRENT_TIMESTAMP WHERE id = p_id_resena;
END;
//

-- procedimiento para DELETE reseña de funcionalidad
CREATE PROCEDURE eliminar_resena_funcionalidad(IN p_id_resena INT, IN p_rut_ingeniero VARCHAR(12))
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Resena_Funcionalidad WHERE id = p_id_resena AND rut_ingeniero = p_rut_ingeniero) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reseña no encontrada o no tiene permisos para eliminarla';
    END IF;
    DELETE FROM Resena_Funcionalidad WHERE id = p_id_resena;
END;
//

-- procedimiento para CREATE resena error
CREATE PROCEDURE crear_resena_error(IN p_id_error INT, IN p_rut_ingeniero VARCHAR(12), IN p_observacion TEXT)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Asignacion_Error WHERE id_error = p_id_error AND rut_ingeniero = p_rut_ingeniero) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No tiene permisos para agregar reseñas a este error';
    END IF;
    INSERT INTO Resena_Error (id_error, rut_ingeniero, observacion) VALUES (p_id_error, p_rut_ingeniero, p_observacion);
END;
//

-- procedimiento para ACTUALIZAR reseña de un error
CREATE PROCEDURE actualizar_resena_error(IN p_id_resena INT, IN p_rut_ingeniero VARCHAR(12), IN p_nueva_observacion TEXT)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Resena_Error WHERE id = p_id_resena AND rut_ingeniero = p_rut_ingeniero) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reseña no encontrada o no tiene permisos para modificarla';
    END IF;
    
    UPDATE Resena_Error 
    SET observacion = p_nueva_observacion, fecha_actualizacion = CURRENT_TIMESTAMP WHERE id = p_id_resena;
END;
//

-- Procedimiento para ELIMINAR reseña en error
CREATE PROCEDURE eliminar_resena_error(IN p_id_resena INT, IN p_rut_ingeniero VARCHAR(12))
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Resena_Error WHERE id = p_id_resena AND rut_ingeniero = p_rut_ingeniero) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reseña no encontrada o no tiene permisos para eliminarla';
    END IF;
    DELETE FROM Resena_Error WHERE id = p_id_resena;
END;
//


DELIMITER ;

--vista para todas las asignaciones de un ingeniero
CREATE VIEW Vista_Asignaciones_Ingeniero AS SELECT i.rut AS rut_ingeniero, p.nombre AS nombre_ingeniero, 'Funcionalidad' AS tipo, sf.id AS id_elemento, sf.titulo AS titulo, sf.resumen AS descripcion, a.nombre AS ambiente, t.nombre AS topico, e.nombre AS estado, af.fecha_asignacion
FROM Asignacion_Funcionalidad af
JOIN Ingeniero i ON af.rut_ingeniero = i.rut
JOIN Persona p ON i.rut = p.rut
JOIN SolicitudesFuncionalidad sf ON af.id_funcionalidad = sf.id
JOIN Ambientes a ON sf.ambiente_id = a.id
JOIN Topicos t ON sf.topico_id = t.id
JOIN Estado e ON sf.estado_id = e.id
UNION ALL
SELECT i.rut AS rut_ingeniero, p.nombre AS nombre_ingeniero, 'Error' AS tipo, ge.id AS id_elemento, ge.titulo AS titulo, ge.descripcion AS descripcion, NULL AS ambiente, t.nombre AS topico, e.nombre AS estado, ae.fecha_asignacion
FROM Asignacion_Error ae
JOIN Ingeniero i ON ae.rut_ingeniero = i.rut
JOIN Persona p ON i.rut = p.rut
JOIN GestionErrores ge ON ae.id_error = ge.id
JOIN Topicos t ON ge.topico_id = t.id
JOIN Estado e ON ge.estado_id = e.id;

--vista para todas las solicitudes creadas por un usuario
CREATE VIEW Vista_Publicaciones_Usuario AS SELECT u.rut AS rut_usuario, p.nombre AS nombre_usuario, 'Funcionalidad' AS tipo, sf.id AS id_elemento, sf.titulo AS titulo, sf.resumen AS descripcion, a.nombre AS ambiente, t.nombre AS topico, e.nombre AS estado, sf.fecha_creacion AS fecha
FROM SolicitudesFuncionalidad sf
JOIN Usuario u ON sf.solicitante_rut = u.rut
JOIN Persona p ON u.rut = p.rut
JOIN Ambientes a ON sf.ambiente_id = a.id
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
(1, 'Backend'),
(2, 'Seguridad'),
(3, 'UX/UI');

INSERT INTO `Estado` (`id`, `nombre`) VALUES
(1, 'Abierto'),
(4, 'Cerrado'),
(2, 'En Progreso'),
(3, 'Resuelto');

INSERT INTO `Ambientes` (`id`, `nombre`) VALUES
(2, 'Movil'),
(1, 'Web');

CALL registrar_persona('1234','user','user@gmail.com','user','user','usuario');
CALL registrar_persona('5678','inge','inge@gmail.com','inge','inge','ingeniero');
INSERT INTO `Ingeniero_Topico` (`rut_ingeniero`, `id_topico`) VALUES ('5678', '1');

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
CALL registrar_persona('22222221-1', 'Rodrigo López', 'rodrigo.lopez@example.com', 'rlopez', '1234', 'ingeniero') ;
INSERT INTO Ingeniero_Topico (rut_ingeniero, id_topico) VALUES ('22222221-1', '1');

CALL registrar_persona('22222222-2', 'María Contreras', 'maria.contreras@example.com', 'mcontreras', '1234', 'ingeniero') ;
INSERT INTO Ingeniero_Topico (rut_ingeniero, id_topico) VALUES ('22222222-2', '2');

CALL registrar_persona('22222223-3', 'Felipe Navarro', 'felipe.navarro@example.com', 'fnavarro', '1234', 'ingeniero') ;
INSERT INTO Ingeniero_Topico (rut_ingeniero, id_topico) VALUES ('22222223-3', '3');

CALL registrar_persona('22222224-4', 'Carolina Vega', 'carolina.vega@example.com', 'cvega', '1234', 'ingeniero') ;
INSERT INTO Ingeniero_Topico (rut_ingeniero, id_topico) VALUES ('22222224-4', '1');

CALL registrar_persona('22222225-5', 'Jorge Díaz', 'jorge.diaz@example.com', 'jdiaz', '1234', 'ingeniero') ;
INSERT INTO Ingeniero_Topico (rut_ingeniero, id_topico) VALUES ('22222225-5', '2');

CALL registrar_persona('22222226-6', 'Francisca Romero', 'francisca.romero@example.com', 'fromero', '1234', 'ingeniero') ;
INSERT INTO Ingeniero_Topico (rut_ingeniero, id_topico) VALUES ('22222226-6', '3');

CALL registrar_persona('22222227-7', 'Ricardo Pérez', 'ricardo.perez@example.com', 'rperez', '1234', 'ingeniero') ;
INSERT INTO Ingeniero_Topico (rut_ingeniero, id_topico) VALUES ('22222227-7', '1');

CALL registrar_persona('22222228-8', 'Natalia Fuentes', 'natalia.fuentes@example.com', 'nfuentes', '1234', 'ingeniero') ;
INSERT INTO Ingeniero_Topico (rut_ingeniero, id_topico) VALUES ('22222228-8', '2');

CALL registrar_persona('22222229-9', 'Claudio Ramírez', 'claudio.ramirez@example.com', 'cramirez', '1234', 'ingeniero') ;
INSERT INTO Ingeniero_Topico (rut_ingeniero, id_topico) VALUES ('22222229-9', '3');

CALL registrar_persona('22222230-K', 'Beatriz Silva', 'beatriz.silva@example.com', 'bsilva', '1234', 'ingeniero') ;
INSERT INTO Ingeniero_Topico (rut_ingeniero, id_topico) VALUES ('22222230-K', '1');

CALL registrar_persona('22222231-1', 'Gonzalo Torres', 'gonzalo.torres@example.com', 'gtorres', '1234', 'ingeniero') ;
INSERT INTO Ingeniero_Topico (rut_ingeniero, id_topico) VALUES ('22222231-1', '2');

CALL registrar_persona('22222232-2', 'Andrea Paredes', 'andrea.paredes@example.com', 'aparedes', '1234', 'ingeniero') ;
INSERT INTO Ingeniero_Topico (rut_ingeniero, id_topico) VALUES ('22222232-2', '3');

CALL registrar_persona('22222233-3', 'Cristóbal Herrera', 'cristobal.herrera@example.com', 'cherrera', '1234', 'ingeniero') ;
INSERT INTO Ingeniero_Topico (rut_ingeniero, id_topico) VALUES ('22222233-3', '1');

CALL registrar_persona('22222234-4', 'Camila Vargas', 'camila.vargas@example.com', 'cvargas', '1234', 'ingeniero') ;
INSERT INTO Ingeniero_Topico (rut_ingeniero, id_topico) VALUES ('22222234-4', '2');

CALL registrar_persona('22222235-5', 'Sebastián Reyes', 'sebastian.reyes@example.com', 'sreyes', '1234', 'ingeniero') ;
INSERT INTO Ingeniero_Topico (rut_ingeniero, id_topico) VALUES ('22222235-5', '3');

CALL registrar_persona('22222236-6', 'Patricia Orellana', 'patricia.orellana@example.com', 'porellana', '1234', 'ingeniero') ;
INSERT INTO Ingeniero_Topico (rut_ingeniero, id_topico) VALUES ('22222236-6', '1');

CALL registrar_persona('22222237-7', 'Mauricio Salazar', 'mauricio.salazar@example.com', 'msalazar', '1234', 'ingeniero') ;
INSERT INTO Ingeniero_Topico (rut_ingeniero, id_topico) VALUES ('22222237-7', '2');

CALL registrar_persona('22222238-8', 'Constanza Leiva', 'constanza.leiva@example.com', 'cleiva', '1234', 'ingeniero') ;
INSERT INTO Ingeniero_Topico (rut_ingeniero, id_topico) VALUES ('22222238-8', '3');

CALL registrar_persona('22222239-9', 'Álvaro Bravo', 'alvaro.bravo@example.com', 'abravo', '1234', 'ingeniero') ;
INSERT INTO Ingeniero_Topico (rut_ingeniero, id_topico) VALUES ('22222239-9', '1');

CALL registrar_persona('22222240-K', 'Lucía Cornejo', 'lucia.cornejo@example.com', 'lcornejo', '1234', 'ingeniero') ;
INSERT INTO Ingeniero_Topico (rut_ingeniero, id_topico) VALUES ('22222240-K', '2');
