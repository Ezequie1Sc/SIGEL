# SIGEL - Sistema de Gestión de Laboratorio
- API REST para la gestión de laboratorio académico, desarrollada con Flask, Flask-RESTX y - PostgreSQL.
# ✨ Características
- Gestión de Usuarios: Sistema de roles (admin, docente, alumno)
- Inventario de Reactivos: Control de existencias, categorías y ubicaciones
- Gestión de Tareas: Asignación y entrega de trabajos académicos
- Sistema de Avisos: Comunicaciones internas del laboratorio
- Subida de Archivos: Soporte para documentos y imágenes

# 🛠 Tecnologías Utilizadas
- Backend: Python 3.8+, Flask
- Base de Datos: - PostgreSQL
- ORM: SQLAlchem
- API: Flask-RESTX
- CORS: Flask-CORS
- Validación: Werkzeug

# 📋 Requisitos Previos
- Python 3.8 o superior
- - PostgreSQL 12 o superior
- pp (gestor de paquetes de Python)

# 🚀 Instalación
- Clonar o Crear el Proyecto
# Si tienes el código en un repositorio
git clone <https://github.com/Ezequie1Sc/SIGEL>
cd sigel-backend

# O crear directorio del proyecto
mkdir sigel-backend
cd sigel-backend

# 2. Instalar Python
# Windows:
- Descargar desde python.org
- Durante la instalación, marcar "Add Python to PATH"

# Linux (Ubuntu/Debian):
sudo apt update
sudo apt install python3 python3-pip
# macOS:

# Usando Homebrew
brew install python

 # Instalar Dependencias
Usar el archivo requirements.txt:

# Instalar dependencias:
pip install -r requirements.txt


🚀 Ejecutar la Aplicación
1. Inicializar la Base de Datos
bash
# Asegúrate de que - PostgreSQL esté ejecutándose
# En Windows: Servico - PostgreSQL
# En Linux: sudo systemcl start - postgresql
# Ejecutar la aplicación (crea las tablas automáticamente)
python app.py

# Verificar la Instalación
1. La aplicación estará disponible en:

- API: http://localhost:5000

- Documentación Swagger: http://localhost:5000

2. Health Check

- curl http://localhost:5000/healthcheck

# 📚 Endpoints de la API
1. Autenticación
- - POST /login - Iniciar sesión
2. Usuarios
- - GET /usuarios/ - Listar usuarios
- PST /usuarios/ - Crear usuario
- - GET /usuarios/{id} - Obtener usuario
- DLETE /usuarios/{id} - Eliminar usuario
- 
3. Reactivos
- - GET /reactivos/ - Listar reactivos
- PST /reactivos/ - Crear reactivo
- - PUT /reactivos/{id} - Actualizar reactivo
- DELETE /reactivos/{id} - Eliminar reactivo
- 
4. Solicitudes
- - GET /solicitudes/ - Listar solicitudes
- PST /solicitudes/ - Crear solicitud 
- DELETE /solicitudes/{id} - Eliminar solicitud

5. Tareas
- GET /tareas/ - Listar tareas
- POST /tareas/ - Crear tarea (con archivo)
- PUT /tareas/{id} - Actualizar tarea 
- DELETE /tareas/{id} - Eliminar tarea

6. Entregas
- GET /entregas/ - Listar entregas
- POST /entregas/ - Crear entrega (con archivo)
- PUT /entregas/{id} - Actualizar entrega 
- DELETE /entregas/{id} - Eliminar entrega

6. Avisos
- GET /avisos/ - Listar avisos
- POST /avisos/ - Crear aviso
- PUT /avisos/{id} - Actualizar aviso 
- DELETE /avisos/{id} - Eliminar aviso

7. Archivos
- - GET /download/{tipo}/{id} - Descargar archivos
- 💡 Ejemplos de Uso
- Crear Usuario
- curl -X - POST http://localhost:5000/usuarios/ \
  -H "Contet-Type: application/json" \
  -d '{
    "username": "profesor1",
    "nombre": "Juan",
    "apellido": "Pérez",
    "email": "juan@universidad.edu",
    "hash_contraseña": "contraseña_segura",
    "rol": "docente"
  }'
- Crear Tarea con Archivo

- curl -X - POST http://localhost:5000/tareas/ \
  -F "titul=Práctica de Laboratorio" \
  -F "descripcion=Realizar los experimentos indicados" \
  -F "fecha_entrega=2024-12-31" \
  -F "hora_cierre=23:59" \
  -F "creado_por=1" \
  -F "file=@/ruta/al/archivo.pdf"

# 🚀 Despliegue
- Para Entorno de Producción
- Desactivar modo debug:

- python
- if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(debug=False, host='0.0.0.0', port=5000)
