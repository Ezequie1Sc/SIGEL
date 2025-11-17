-- =============================================
-- SISTEMA DE GESTIÓN DE LABORATORIOS (SIGEL)
-- Script de inicialización de Base de Datos
-- =============================================

-- Crear extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- TABLA: usuarios (Sistema principal)
-- =============================================
CREATE TABLE IF NOT EXISTS usuarios (
    id_usuario SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    hash_contraseña VARCHAR(255) NOT NULL,
    rol VARCHAR(20) NOT NULL CHECK (rol IN ('admin', 'docente', 'alumno')),
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- TABLA: categorias
-- =============================================
CREATE TABLE IF NOT EXISTS categorias (
    id_categoria SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    descripcion VARCHAR(255)
);

-- =============================================
-- TABLA: reactivos (corregido nombre - era 'resctivos')
-- =============================================
CREATE TABLE IF NOT EXISTS reactivos (
    id_reactivo SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    cantidad NUMERIC(10,2) NOT NULL,
    unidad VARCHAR(10) NOT NULL,
    minimo NUMERIC(10,2) NOT NULL,
    ubicacion VARCHAR(100) NOT NULL,
    id_categoria INTEGER REFERENCES categorias(id_categoria),
    creado_por INTEGER REFERENCES usuarios(id_usuario),
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- TABLA: solicitudes
-- =============================================
CREATE TABLE IF NOT EXISTS solicitudes (
    id_solicitud SERIAL PRIMARY KEY,
    id_reactivo INTEGER REFERENCES reactivos(id_reactivo),
    cantidad NUMERIC(10,2) NOT NULL,
    proyecto VARCHAR(255) NOT NULL,
    es_proyecto BOOLEAN NOT NULL,
    id_usuario INTEGER REFERENCES usuarios(id_usuario),
    fecha_solicitud TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- TABLA: tareas
-- =============================================
CREATE TABLE IF NOT EXISTS tareas (
    id SERIAL PRIMARY KEY,
    titulo VARCHAR(255) NOT NULL,
    descripcion TEXT,
    fecha_entrega DATE,
    hora_cierre TIME,
    creado_por INTEGER REFERENCES usuarios(id_usuario) ON DELETE SET NULL,
    archivo_ruta VARCHAR(255),
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- TABLA: entregas
-- =============================================
CREATE TABLE IF NOT EXISTS entregas (
    id SERIAL PRIMARY KEY,
    id_tarea INTEGER REFERENCES tareas(id) ON DELETE CASCADE,
    id_alumno INTEGER REFERENCES usuarios(id_usuario),
    archivo_ruta VARCHAR(255),
    fecha_entrega TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    calificacion NUMERIC(5,2),
    observaciones TEXT
);

-- =============================================
-- TABLA: codigos_recuperacion
-- =============================================
CREATE TABLE IF NOT EXISTS codigos_recuperacion (
    id SERIAL PRIMARY KEY,
    email VARCHAR(100) NOT NULL,
    codigo VARCHAR(6) NOT NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    usado BOOLEAN DEFAULT FALSE
);

-- =============================================
-- TABLA: Usuarios (Sistema de reservas - diferente tabla)
-- =============================================
CREATE TABLE IF NOT EXISTS Usuarios (
    IdUser SERIAL PRIMARY KEY,
    Usuario VARCHAR(100) NOT NULL,
    Nombre VARCHAR(100) NOT NULL,
    Apellido VARCHAR(100) NOT NULL,
    Email VARCHAR(250) UNIQUE NOT NULL,
    Telefono VARCHAR(10),
    Password VARCHAR(100) NOT NULL
);

-- =============================================
-- TABLA: Reservaciones
-- =============================================
CREATE TABLE IF NOT EXISTS Reservaciones (
    IdReserva SERIAL PRIMARY KEY,
    IdUser INTEGER REFERENCES Usuarios(IdUser),
    Servicio VARCHAR(100) NOT NULL,
    Fecha DATE NOT NULL,
    Hora TIME NOT NULL,
    ParaOtraPersona BOOLEAN DEFAULT FALSE,
    NombrePersona VARCHAR(100),
    Estado VARCHAR(50) DEFAULT 'pendiente',
    FechaCreacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- ÍNDICES PARA MEJOR RENDIMIENTO
-- =============================================

-- Índices para usuarios
CREATE INDEX IF NOT EXISTS idx_usuarios_username ON usuarios(username);
CREATE INDEX IF NOT EXISTS idx_usuarios_email ON usuarios(email);
CREATE INDEX IF NOT EXISTS idx_usuarios_rol ON usuarios(rol);

CREATE INDEX IF NOT EXISTS idx_Usuarios_sistema_email ON Usuarios(Email);
CREATE INDEX IF NOT EXISTS idx_Usuarios_sistema_usuario ON Usuarios(Usuario);

-- Índices para reactivos
CREATE INDEX IF NOT EXISTS idx_reactivos_categoria ON reactivos(id_categoria);
CREATE INDEX IF NOT EXISTS idx_reactivos_creado_por ON reactivos(creado_por);
CREATE INDEX IF NOT EXISTS idx_reactivos_ubicacion ON reactivos(ubicacion);

-- Índices para solicitudes
CREATE INDEX IF NOT EXISTS idx_solicitudes_reactivo ON solicitudes(id_reactivo);
CREATE INDEX IF NOT EXISTS idx_solicitudes_usuario ON solicitudes(id_usuario);
CREATE INDEX IF NOT EXISTS idx_solicitudes_fecha ON solicitudes(fecha_solicitud);

-- Índices para tareas
CREATE INDEX IF NOT EXISTS idx_tareas_creado_por ON tareas(creado_por);
CREATE INDEX IF NOT EXISTS idx_tareas_fecha_entrega ON tareas(fecha_entrega);
CREATE INDEX IF NOT EXISTS idx_tareas_fecha_creacion ON tareas(fecha_creacion);

-- Índices para entregas
CREATE INDEX IF NOT EXISTS idx_entregas_tarea ON entregas(id_tarea);
CREATE INDEX IF NOT EXISTS idx_entregas_alumno ON entregas(id_alumno);
CREATE INDEX IF NOT EXISTS idx_entregas_fecha ON entregas(fecha_entrega);

-- Índices para códigos de recuperación
CREATE INDEX IF NOT EXISTS idx_codigos_email ON codigos_recuperacion(email);
CREATE INDEX IF NOT EXISTS idx_codigos_usado ON codigos_recuperacion(usado);

-- Índices para reservaciones
CREATE INDEX IF NOT EXISTS idx_reservaciones_usuario ON Reservaciones(IdUser);
CREATE INDEX IF NOT EXISTS idx_reservaciones_fecha ON Reservaciones(Fecha);
CREATE INDEX IF NOT EXISTS idx_reservaciones_estado ON Reservaciones(Estado);

-- =============================================
-- DATOS INICIALES
-- =============================================

-- Insertar categorías de reactivos
INSERT INTO categorias (nombre, descripcion) VALUES
('Reactivos Químicos', 'Productos químicos para experimentos y análisis'),
('Material de Laboratorio', 'Instrumentos y equipos de laboratorio'),
('Consumibles', 'Materiales de un solo uso'),
('Equipos de Seguridad', 'Equipos de protección personal'),
('Vidriería', 'Material de vidrio para laboratorio')
ON CONFLICT (id_categoria) DO NOTHING;

-- Insertar usuarios del sistema principal
INSERT INTO usuarios (username, nombre, apellido, email, hash_contraseña, rol) VALUES
('admin', 'Administrador', 'Sistema', 'admin@sigel.edu', 'admin123', 'admin'),
('profesor1', 'Carlos', 'Martínez', 'carlos.martinez@sigel.edu', 'prof123', 'docente'),
('profesor2', 'Ana', 'García', 'ana.garcia@sigel.edu', 'prof456', 'docente'),
('alumno1', 'Luis', 'Hernández', 'luis.hernandez@sigel.edu', 'alum123', 'alumno'),
('alumno2', 'María', 'López', 'maria.lopez@sigel.edu', 'alum456', 'alumno')
ON CONFLICT (username) DO NOTHING;

-- Insertar usuarios del sistema de reservas
INSERT INTO Usuarios (Usuario, Nombre, Apellido, Email, Telefono, Password) VALUES
('reserva.admin', 'Admin Reservas', 'Sistema', 'reservas@sigel.edu', '5551234567', 'reserva123'),
('juan.perez', 'Juan', 'Pérez', 'juan.perez@sigel.edu', '5557654321', 'user123')
ON CONFLICT (Email) DO NOTHING;

-- Insertar reactivos de ejemplo
INSERT INTO reactivos (nombre, cantidad, unidad, minimo, ubicacion, id_categoria, creado_por) VALUES
('Ácido Clorhídrico', 2.5, 'L', 0.5, 'Estante A1', 1, 1),
('Hidróxido de Sodio', 1.0, 'kg', 0.2, 'Estante B2', 1, 1),
('Sulfato de Cobre', 500.0, 'g', 100.0, 'Estante C3', 1, 2),
('Agua Destilada', 10.0, 'L', 2.0, 'Estante D4', 1, 1),
('Tubos de Ensayo', 50.0, 'pz', 10.0, 'Gabinete 1', 2, 2)
ON CONFLICT (id_reactivo) DO NOTHING;

-- Insertar tareas de ejemplo
INSERT INTO tareas (titulo, descripcion, fecha_entrega, hora_cierre, creado_por) VALUES
('Práctica de Química Orgánica', 'Realizar los experimentos de la guía práctica', '2024-12-15', '23:59:00', 2),
('Análisis de Reactivos', 'Presentar reporte de análisis de pureza', '2024-12-20', '18:00:00', 3),
('Seguridad en Laboratorio', 'Investigación sobre normas de seguridad', '2024-12-10', '20:00:00', 2)
ON CONFLICT (id) DO NOTHING;

-- Insertar solicitudes de ejemplo
INSERT INTO solicitudes (id_reactivo, cantidad, proyecto, es_proyecto, id_usuario) VALUES
(1, 0.5, 'Práctica de Química General', true, 4),
(3, 50.0, 'Investigación de Cristales', true, 5),
(2, 0.1, 'Preparación de Soluciones', false, 4)
ON CONFLICT (id_solicitud) DO NOTHING;

-- Insertar reservaciones de ejemplo
INSERT INTO Reservaciones (IdUser, Servicio, Fecha, Hora, ParaOtraPersona, NombrePersona, Estado) VALUES
(1, 'Uso de Espectrómetro', '2024-12-15', '10:00:00', false, NULL, 'confirmada'),
(2, 'Microscopio Electrónico', '2024-12-16', '14:30:00', true, 'Dr. Roberto Sánchez', 'pendiente')
ON CONFLICT (IdReserva) DO NOTHING;

-- =============================================
-- VISTAS ÚTILES
-- =============================================

-- Vista para reactivos bajos en inventario
CREATE OR REPLACE VIEW reactivos_bajos_inventario AS
SELECT 
    r.id_reactivo,
    r.nombre,
    r.cantidad,
    r.minimo,
    r.unidad,
    r.ubicacion,
    c.nombre as categoria
FROM reactivos r
JOIN categorias c ON r.id_categoria = c.id_categoria
WHERE r.cantidad <= r.minimo;

-- Vista para tareas pendientes por alumno
CREATE OR REPLACE VIEW tareas_pendientes AS
SELECT 
    t.id,
    t.titulo,
    t.fecha_entrega,
    t.hora_cierre,
    u.nombre || ' ' || u.apellido as creador,
    COUNT(e.id) as entregas_realizadas
FROM tareas t
JOIN usuarios u ON t.creado_por = u.id_usuario
LEFT JOIN entregas e ON t.id = e.id_tarea
GROUP BY t.id, t.titulo, t.fecha_entrega, t.hora_cierre, u.nombre, u.apellido;

-- =============================================
-- FUNCIONES Y TRIGGERS
-- =============================================

-- Función para actualizar fecha de modificación
CREATE OR REPLACE FUNCTION actualizar_fecha_modificacion()
RETURNS TRIGGER AS $$
BEGIN
    NEW.fecha_creacion = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para códigos de recuperación
CREATE OR REPLACE TRIGGER tr_codigos_fecha_creacion
    BEFORE INSERT ON codigos_recuperacion
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_fecha_modificacion();

-- Función para validar email
CREATE OR REPLACE FUNCTION validar_email(email VARCHAR)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN email ~ '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$';
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- PERMISOS Y ROLES
-- =============================================

-- Comentarios para documentación
COMMENT ON TABLE usuarios IS 'Usuarios del sistema principal de gestión de laboratorio';
COMMENT ON TABLE reactivos IS 'Inventario de reactivos y materiales del laboratorio';
COMMENT ON TABLE solicitudes IS 'Solicitudes de reactivos por parte de usuarios';
COMMENT ON TABLE tareas IS 'Tareas asignadas a estudiantes';
COMMENT ON TABLE entregas IS 'Entregas de tareas por parte de estudiantes';
COMMENT ON TABLE categorias IS 'Categorías para clasificar reactivos';
COMMENT ON TABLE codigos_recuperacion IS 'Códigos para recuperación de contraseñas';
COMMENT ON TABLE Usuarios IS 'Usuarios del sistema de reservas (tabla separada)';
COMMENT ON TABLE Reservaciones IS 'Reservaciones de equipos y servicios del laboratorio';

COMMENT ON COLUMN usuarios.rol IS 'Roles: admin, docente, alumno';
COMMENT ON COLUMN reactivos.minimo IS 'Cantidad mínima antes de alertar';
COMMENT ON COLUMN solicitudes.es_proyecto IS 'True si es para proyecto, False para práctica';
COMMENT ON COLUMN Reservaciones.Estado IS 'Estados: pendiente, confirmada, cancelada, completada';

-- =============================================
-- MENSAJE DE ÉXITO
-- =============================================
DO $$ 
BEGIN
    RAISE NOTICE 'Base de datos SIGEL inicializada correctamente';
    RAISE NOTICE 'Tablas creadas: usuarios, categorias, reactivos, solicitudes, tareas, entregas, codigos_recuperacion, Usuarios, Reservaciones';
    RAISE NOTICE 'Datos de ejemplo insertados';
    RAISE NOTICE 'Índices y vistas creados';
END $$;