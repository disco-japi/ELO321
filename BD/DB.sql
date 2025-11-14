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

CREATE TABLE Topicos(
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE Estado(
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL
);

DELIMITER //

-- triggers para impedir que un usuario sea administrador y tambien que un administrador sea usuario
CREATE TRIGGER trg_usuario BEFORE INSERT ON Usuario FOR EACH ROW 
BEGIN 
    IF EXISTS (SELECT 1 FROM Administrador WHERE rut = NEW.rut) THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RUT ya detectado en un administrador, no es posible usarlo';
    END IF;
END;
//

CREATE TRIGGER trg_administrador BEFORE INSERT ON Administrador FOR EACH ROW 
BEGIN 
    IF EXISTS (SELECT 1 FROM Usuario WHERE rut = NEW.rut) THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RUT ya detectado en un usuario, no es posible usarlo';
    END IF;
END;
//

DELIMITER ;

-- tabla de gestion de compra
CREATE TABLE Item(
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion VARCHAR(200) NOT NULL,
    topico_id INT NOT NULL,
    disponible INT NOT NULL,
    precio INT NOT NULL,
    FOREIGN KEY (topico_id) REFERENCES Topicos(id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE GestionCompras(
    id INT AUTO_INCREMENT PRIMARY KEY,    
    id_item INT NOT NULL,
    fecha_publicacion DATE NOT NULL,
    usuario_rut VARCHAR(12) NOT NULL,
    estado_id INT NOT NULL,
    FOREIGN KEY (id_item) REFERENCES Item(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (usuario_rut) REFERENCES Usuario(rut) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (estado_id) REFERENCES Estado(id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE Resena_Item(
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_item INT NOT NULL,
    rut_usuario VARCHAR(12) NOT NULL,
    comentario TEXT NOT NULL,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_item) REFERENCES Item(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (rut_usuario) REFERENCES Usuario(rut) ON DELETE CASCADE ON UPDATE CASCADE
);

-- procedimiento de registrar una persona
DELIMITER //

CREATE PROCEDURE registrar_item(
    IN p_nombre VARCHAR(50),
    IN p_descripcion TEXT,
    IN p_id_topico INT,
    IN p_stock INT
    IN p_precio INT
) 
BEGIN 
    INSERT INTO Item (nombre, descripcion, topico_id, disponible, precio) 
    VALUES (p_nombre, p_descripcion, p_id_topico, p_stock, p_precio);
END;
//

CREATE PROCEDURE registrar_persona(
    IN p_rut VARCHAR(12),
    IN p_nombre VARCHAR(50),
    IN p_email VARCHAR(50),
    IN p_nombre_usuario VARCHAR(50),
    IN p_contrasena VARCHAR(255),
    IN p_rol VARCHAR(20)
) 
BEGIN 
    INSERT INTO Persona (rut, nombre, email, nombre_usuario, contrasena) 
    VALUES (p_rut, p_nombre, p_email, p_nombre_usuario, p_contrasena);
    IF p_rol = 'usuario' THEN 
        INSERT INTO Usuario (rut) VALUES (p_rut);
    ELSEIF p_rol = 'administrador' THEN 
        INSERT INTO Administrador (rut) VALUES (p_rut);
    ELSE 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Rol incorrecto, debe ser usuario o administrador';
    END IF;
END;
//

-- funcion para validar el login
CREATE FUNCTION validador_login (p_nombre_usuario VARCHAR(50), p_contrasena VARCHAR(255)) RETURNS VARCHAR(20) DETERMINISTIC 
BEGIN 
    DECLARE v_rut VARCHAR(12); 
    DECLARE v_rol VARCHAR(20);
    SELECT rut INTO v_rut FROM Persona WHERE nombre_usuario = p_nombre_usuario AND contrasena = p_contrasena;
    IF v_rut IS NULL THEN 
        RETURN 'No existe';
    END IF;
    IF EXISTS (SELECT 1 FROM Administrador WHERE rut = v_rut) THEN 
        SET v_rol = 'Administrador';
    ELSEIF EXISTS (SELECT 1 FROM Usuario WHERE rut = v_rut) THEN 
        SET v_rol = 'Usuario';
    ELSE 
        SET v_rol = 'SinRol';
    END IF;
    RETURN v_rol;
END;
//

-- PROCEDIMIENTOS CRUD DE LAS COMPRAS

-- procedimiento para CREATE de la compra
CREATE PROCEDURE registrar_compra(
    IN p_id_item INT, 
    IN p_usuario_rut VARCHAR(12), 
    IN p_estado_id INT
)
BEGIN
    DECLARE v_disponible INT;

    SELECT disponible INTO v_disponible
    FROM Item
    WHERE id = p_id_item;

    IF v_disponible IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Item no encontrado';
    ELSEIF v_disponible <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay existencias';
    ELSE
        INSERT INTO GestionCompras (id_item, fecha_publicacion, usuario_rut, estado_id)
        VALUES (p_id_item, CURDATE(), p_usuario_rut, p_estado_id);

        UPDATE Item
        SET disponible = disponible - 1
        WHERE id = p_id_item;
    END IF;
END;
//

-- procedimiento para el READ de la compra
CREATE PROCEDURE leer_compra_usuario(IN p_id_compra INT)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM GestionCompras WHERE id = p_id_compra) THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error no encontrado o no tiene permisos para verlo';
    END IF;

    SELECT  ge.id,
            ge.id_item,
            i.nombre AS nombre_item,
            e.nombre AS estado,
            e.id AS estado_id,
            ge.fecha_publicacion,
            p.nombre AS usuario,
            ge.usuario_rut
    FROM GestionCompras ge
    JOIN Item i ON ge.id_item = i.id
    JOIN Estado e ON ge.estado_id = e.id
    JOIN Persona p ON ge.usuario_rut = p.rut
    WHERE ge.id = p_id_compra;
END;
//

-- procedimiento para el UPDATE de compras
CREATE PROCEDURE actualizar_compra(IN p_id_compra INT, IN p_estado_id INT)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM GestionCompras WHERE id = p_id_compra) THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Compra no encontrada o sin permisos para modificarla';
    END IF;
    UPDATE GestionCompras 
    SET estado_id = p_estado_id 
    WHERE id = p_id_compra;
END;
//

-- proceso para el DELETE de compra
CREATE PROCEDURE eliminar_compra(IN p_id_compra INT)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM GestionCompras WHERE id = p_id_compra) THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Compra no encontrada o sin permisos para eliminarla';
    END IF;

    DELETE FROM GestionCompras WHERE id = p_id_compra;
END;
//

-- proceso para INSERT de comentario
CREATE PROCEDURE crear_resena_item(IN p_id_item INT, IN p_rut_usuario VARCHAR(12), IN p_comentario TEXT)
BEGIN
    INSERT INTO Resena_Item (id_item, rut_usuario, comentario) VALUES (p_id_item, p_rut_usuario, p_comentario);
END;
//

DELIMITER ;

-- vista para todas las compras de un usuario
CREATE VIEW Vista_Compras_Usuario AS 
SELECT ge.id AS id_compra,
       u.rut AS rut_usuario,
       p.nombre AS nombre_usuario,
       ge.id_item,
       i.nombre AS nombre_item,
       e.nombre AS estado,
       ge.fecha_publicacion AS fecha
FROM GestionCompras ge
JOIN Item i ON ge.id_item = i.id
JOIN Usuario u ON ge.usuario_rut = u.rut
JOIN Persona p ON u.rut = p.rut
JOIN Estado e ON ge.estado_id = e.id;

INSERT INTO Topicos (id, nombre) VALUES
(1, 'Hardware'),
(2, 'Software'),
(3, 'Consumo'),
(4, 'Electronica de desarrollo');

INSERT INTO Estado (id, nombre) VALUES
(1, 'En logistica'),
(2, 'En camino'),
(3, 'Entregado'),
(4, 'Confirmado');

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

-- ==== ADMINISTRADORES ====
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

-- ==== ITEMS (5 por tópico) ====
-- Topico 1: Hardware
CALL registrar_item('SSD 1TB', 'Unidad de estado sólido SATA 1TB, 2.5\"', 1, 12, 39990);
CALL registrar_item('Memoria RAM 16GB', 'DDR4 3200MHz, módulo 16GB', 1, 7, 14990);
CALL registrar_item('Fuente ATX 650W', 'Fuente certificada 80+ Bronze, 650W', 1, 4, 59990);
CALL registrar_item('Placa madre ATX', 'Placa madre compatible Intel/AMD, socket moderno', 1, 0, 89990);
CALL registrar_item('GPU GeForce GTX 1660', 'Tarjeta gráfica para gaming 6GB GDDR5', 1, 2, 119990);

-- Topico 2: Software (pagado)
CALL registrar_item('Licencia Office 365', 'Suscripción anual Microsoft 365 Personal', 2, 9, 39990);
CALL registrar_item('Antivirus Pro McAfee', 'Licencia 1 año para 1 equipo, soporte técnico', 2, 3, 19990);
CALL registrar_item('IDE Profesional', 'Licencia de IDE con herramientas avanzadas', 2, 6,49990);
CALL registrar_item('Suite Diseño Pro', 'Suite de diseño gráfico y edición profesional', 2, 5,89990);
CALL registrar_item('ERP Pyme', 'Licencia ERP para pequeñas empresas, 1 usuario', 2, 1,139990);

-- Topico 3: Electrónica de consumo
CALL registrar_item('Auriculares Bluetooth', 'In-ear Bluetooth con cancelación de ruido', 3, 14,34990);
CALL registrar_item('Smartwatch', 'Reloj inteligente con pulsómetro y GPS', 3, 5,129990);
CALL registrar_item('Cámara 4K', 'Cámara compacta 4K para video y fotos', 3, 229990);
CALL registrar_item('Altavoz Bluetooth', 'Altavoz portátil con batería de larga duración', 3, 8,49990);
CALL registrar_item('Tablet 10\"', 'Tablet 10 pulgadas, pantalla HD, 32GB', 3, 0,150990);

-- Topico 4: Electrónica de desarrollo
CALL registrar_item('Protoboard 400 puntos', 'Protoboard para prototipado, 400 puntos', 4, 11,4990);
CALL registrar_item('Kit Arduino Uno', 'Placa Arduino Uno R3 + cables y LEDs', 4, 8,20990);
CALL registrar_item('Pack sensores', 'Sensor temperatura, ultrasonido y luz', 4, 0,10990);
CALL registrar_item('Módulo ESP32', 'Módulo ESP32 WiFi/Bluetooth para desarrollo', 4, 13,2990);
CALL registrar_item('Kit jumper y cableado', 'Juego de cables jumper macho-macho, 75 unidades', 4, 6,2990);