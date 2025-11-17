# Base de Datos SIGEL

## Estructura de la Base de Datos

### Tablas Principales
1. **usuarios** - Usuarios del sistema de gestión
2. **reactivos** - Inventario de laboratorio  
3. **solicitudes** - Solicitudes de reactivos
4. **tareas** - Tareas académicas
5. **entregas** - Entregas de estudiantes
6. **categorias** - Categorías de reactivos
7. **codigos_recuperacion** - Recuperación de contraseñas
8. **Usuarios** - Sistema de reservas (separado)
9. **Reservaciones** - Reservas de equipos

## Inicialización

```bash
# Con Docker
cd database
docker-compose -f docker-compose.db.yml up -d

# Script manual
psql -h localhost -U sigel_user -d sigeldb -f init.sql


Credenciales por Defecto
Sistema Principal
Admin: admin / admin123

Docente: profesor1 / prof123

Estudiante: alumno1 / alum123

Sistema de Reservas
Admin: reserva.admin / reserva123

Usuario: juan.perez / user123