import os
from flask import Flask, request, send_file
from flask_sqlalchemy import SQLAlchemy
from flask_restx import Api, Resource, fields
from werkzeug.exceptions import NotFound
from werkzeug.utils import secure_filename
from flask_cors import CORS
from sqlalchemy import func
from datetime import datetime, time

app = Flask(__name__)
CORS(app)

# Configuración para la carpeta de uploads
UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'}
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # Límite de 16MB para archivos

# Crear la carpeta de uploads si no existe
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

# Función para verificar extensiones permitidas
def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://postgres:root@localhost:5432/SigelDB'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)
api = Api(app, version='1.0', title='API SIGEL', description='API para gestión de laboratorio')

# Modelos de la base de datos
class Usuario(db.Model):
    __tablename__ = 'usuarios'
    id_usuario = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(50), unique=True, nullable=False)
    nombre = db.Column(db.String(50), nullable=False)
    apellido = db.Column(db.String(50), nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=False)
    hash_contraseña = db.Column(db.String(255), nullable=False)
    rol = db.Column(db.String(20), nullable=False)
    def __repr__(self):
        return f'<Usuario {self.username}>'

class Categoria(db.Model):
    __tablename__ = 'categorias'
    id_categoria = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(100), nullable=False)
    descripcion = db.Column(db.String(255))
    def __repr__(self):
        return f'<Categoria {self.nombre}>'

class Reactivo(db.Model):
    __tablename__ = 'reactivos'
    id_reactivo = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(100), nullable=False)
    cantidad = db.Column(db.Numeric(10, 2), nullable=False)
    unidad = db.Column(db.String(10), nullable=False)
    minimo = db.Column(db.Numeric(10, 2), nullable=False)
    ubicacion = db.Column(db.String(100), nullable=False)
    id_categoria = db.Column(db.Integer, db.ForeignKey('categorias.id_categoria'), nullable=False)
    creado_por = db.Column(db.Integer, db.ForeignKey('usuarios.id_usuario'))
    fecha_creacion = db.Column(db.TIMESTAMP, server_default=db.func.current_timestamp())
    categoria = db.relationship('Categoria', backref='reactivos')
    usuario = db.relationship('Usuario', backref='reactivos_creados')
    def __repr__(self):
        return f'<Reactivo {self.nombre}>'

class Solicitud(db.Model):
    __tablename__ = 'solicitudes'
    id_solicitud = db.Column(db.Integer, primary_key=True)
    id_reactivo = db.Column(db.Integer, db.ForeignKey('reactivos.id_reactivo'), nullable=False)
    cantidad = db.Column(db.Numeric(10, 2), nullable=False)
    proyecto = db.Column(db.String(255), nullable=False)
    es_proyecto = db.Column(db.Boolean, nullable=False)
    id_usuario = db.Column(db.Integer, db.ForeignKey('usuarios.id_usuario'), nullable=False)
    fecha_solicitud = db.Column(db.TIMESTAMP, server_default=db.func.current_timestamp())
    reactivo = db.relationship('Reactivo', backref='solicitudes')
    usuario = db.relationship('Usuario', backref='solicitudes')
    def __repr__(self):
        return f'<Solicitud {self.id_solicitud}>'

class Tarea(db.Model):
    __tablename__ = 'tareas'
    id = db.Column(db.Integer, primary_key=True)
    titulo = db.Column(db.String(255), nullable=False)
    descripcion = db.Column(db.Text)
    fecha_entrega = db.Column(db.Date)
    hora_cierre = db.Column(db.Time)
    creado_por = db.Column(db.Integer, db.ForeignKey('usuarios.id_usuario', ondelete='SET NULL'))
    archivo_ruta = db.Column(db.String(255))
    fecha_creacion = db.Column(db.TIMESTAMP, server_default=db.func.current_timestamp())
    creador = db.relationship('Usuario', backref='tareas_creadas')
    entregas = db.relationship('Entrega', backref='tarea', cascade='all, delete-orphan')
    def __repr__(self):
        return f'<Tarea {self.titulo}>'

class Entrega(db.Model):
    __tablename__ = 'entregas'
    id = db.Column(db.Integer, primary_key=True)
    id_tarea = db.Column(db.Integer, db.ForeignKey('tareas.id'), nullable=False)
    id_alumno = db.Column(db.Integer, db.ForeignKey('usuarios.id_usuario'), nullable=False)
    archivo_ruta = db.Column(db.String(255))
    fecha_entrega = db.Column(db.TIMESTAMP, server_default=db.func.current_timestamp())
    calificacion = db.Column(db.Numeric(5, 2))
    observaciones = db.Column(db.Text)
    alumno = db.relationship('Usuario', backref='entregas')
    def __repr__(self):
        return f'<Entrega {self.id}>'

class Aviso(db.Model):
    __tablename__ = 'avisos'
    id_aviso = db.Column(db.Integer, primary_key=True)
    id_usuario = db.Column(db.Integer, db.ForeignKey('usuarios.id_usuario'), nullable=False)
    fecha_hora = db.Column(db.TIMESTAMP, server_default=db.func.current_timestamp(), nullable=False)
    titulo = db.Column(db.String(255), nullable=False, default='Sin título')
    texto = db.Column(db.Text, nullable=False)
    usuario = db.relationship('Usuario', backref='avisos')
    def __repr__(self):
        return f'<Aviso {self.id_aviso}>'

# Modelos para la API
usuario_model = api.model('Usuario', {
    'id_usuario': fields.Integer(readonly=True),
    'username': fields.String(required=True),
    'nombre': fields.String(required=True),
    'apellido': fields.String(required=True),
    'email': fields.String(required=True),
    'rol': fields.String(required=True, enum=['admin', 'docente', 'alumno'])
})

usuario_input = api.model('UsuarioInput', {
    'username': fields.String(required=True),
    'nombre': fields.String(required=True),
    'apellido': fields.String(required=True),
    'email': fields.String(required=True),
    'hash_contraseña': fields.String(required=True),
    'rol': fields.String(required=True, enum=['admin', 'docente', 'alumno'])
})

login_input = api.model('LoginInput', {
    'username': fields.String(required=True),
    'hash_contraseña': fields.String(required=True),
})

categoria_model = api.model('Categoria', {
    'id_categoria': fields.Integer(readonly=True),
    'nombre': fields.String(required=True),
    'descripcion': fields.String
})

reactivo_model = api.model('Reactivo', {
    'id_reactivo': fields.Integer(readonly=True),
    'nombre': fields.String(required=True),
    'cantidad': fields.Float(required=True),
    'unidad': fields.String(required=True),
    'minimo': fields.Float(required=True),
    'ubicacion': fields.String(required=True),
    'id_categoria': fields.Integer(required=True),
    'creado_por': fields.Integer,
    'fecha_creacion': fields.DateTime(readonly=True),
    'categoria': fields.Nested(categoria_model)
})

reactivo_input = api.model('ReactivoInput', {
    'nombre': fields.String(required=True),
    'cantidad': fields.Float(required=True),
    'unidad': fields.String(required=True),
    'minimo': fields.Float(required=True),
    'ubicacion': fields.String(required=True),
    'id_categoria': fields.Integer(required=True),
    'creado_por': fields.Integer
})

solicitud_model = api.model('Solicitud', {
    'id_solicitud': fields.Integer(readonly=True),
    'id_reactivo': fields.Integer(required=True),
    'cantidad': fields.Float(required=True),
    'proyecto': fields.String(required=True),
    'es_proyecto': fields.Boolean(required=True),
    'id_usuario': fields.Integer(required=True),
    'fecha_solicitud': fields.DateTime(readonly=True),
    'reactivo': fields.Nested(reactivo_model),
    'usuario': fields.Nested(usuario_model)
})

solicitud_input = api.model('SolicitudInput', {
    'id_reactivo': fields.Integer(required=True),
    'cantidad': fields.Float(required=True),
    'proyecto': fields.String(required=True),
    'es_proyecto': fields.Boolean(required=True),
    'id_usuario': fields.Integer(required=True)
})

tarea_model = api.model('Tarea', {
    'id': fields.Integer(readonly=True),
    'titulo': fields.String(required=True),
    'descripcion': fields.String,
    'fecha_entrega': fields.Date,
    'hora_cierre': fields.String(attribute=lambda x: x.hora_cierre.isoformat() if x.hora_cierre else None),
    'creado_por': fields.Integer,
    'archivo_ruta': fields.String,
    'fecha_creacion': fields.DateTime(readonly=True),
    'creador': fields.Nested(usuario_model),
    'status': fields.String(readonly=True)
})

tarea_input = api.model('TareaInput', {
    'titulo': fields.String(required=True),
    'descripcion': fields.String,
    'fecha_entrega': fields.Date,
    'hora_cierre': fields.String,
    'creado_por': fields.Integer(required=True),
    'archivo_ruta': fields.String
})

entrega_model = api.model('Entrega', {
    'id': fields.Integer(readonly=True),
    'id_tarea': fields.Integer(required=True),
    'id_alumno': fields.Integer(required=True),
    'archivo_ruta': fields.String,
    'fecha_entrega': fields.DateTime(readonly=True),
    'calificacion': fields.Float,
    'observaciones': fields.String,
    'alumno': fields.Nested(usuario_model),
    'tarea': fields.Nested(tarea_model)
})

entrega_input = api.model('EntregaInput', {
    'id_tarea': fields.Integer(required=True),
    'id_alumno': fields.Integer(required=True),
    'archivo_ruta': fields.String,
    'calificacion': fields.Float,
    'observaciones': fields.String
})

aviso_model = api.model('Aviso', {
    'id_aviso': fields.Integer(readonly=True),
    'id_usuario': fields.Integer(required=True),
    'fecha_hora': fields.DateTime(readonly=True),
    'titulo': fields.String(required=True, default='Sin título'),
    'texto': fields.String(required=True),
    'usuario': fields.Nested(usuario_model)
})

aviso_input = api.model('AvisoInput', {
    'id_usuario': fields.Integer(required=True),
    'titulo': fields.String(required=True, default='Sin título'),
    'texto': fields.String(required=True)
})

# Namespaces
usuarios_ns = api.namespace('usuarios', description='Operaciones con usuarios')
categorias_ns = api.namespace('categorias', description='Operaciones con categorías')
reactivos_ns = api.namespace('reactivos', description='Operaciones con reactivos')
solicitudes_ns = api.namespace('solicitudes', description='Operaciones con solicitudes')
tareas_ns = api.namespace('tareas', description='Operaciones con tareas')
entregas_ns = api.namespace('entregas', description='Operaciones con entregas')
avisos_ns = api.namespace('avisos', description='Operaciones con avisos')

# Endpoints de Usuarios
@usuarios_ns.route('/')
class UsuarioList(Resource):
    @usuarios_ns.marshal_list_with(usuario_model)
    def get(self):
        return Usuario.query.all()

    @usuarios_ns.expect(usuario_input)
    @usuarios_ns.marshal_with(usuario_model, code=201)
    def post(self):
        data = request.get_json()
        if not data or not all(key in data for key in ['username', 'nombre', 'apellido', 'email', 'hash_contraseña', 'rol']):
            return {'error': 'Faltan campos requeridos'}, 400
        nuevo_usuario = Usuario(
            username=data['username'].strip().lower(),
            nombre=data['nombre'].strip(),
            apellido=data['apellido'].strip(),
            email=data['email'].strip(),
            hash_contraseña=data['hash_contraseña'],
            rol=data['rol']
        )
        db.session.add(nuevo_usuario)
        db.session.commit()
        return nuevo_usuario, 201

@usuarios_ns.route('/<int:id_usuario>')
class UsuarioResource(Resource):
    @usuarios_ns.marshal_with(usuario_model)
    def get(self, id_usuario):
        usuario = Usuario.query.get(id_usuario)
        if not usuario:
            raise NotFound("Usuario no encontrado")
        return usuario

    def delete(self, id_usuario):
        usuario = Usuario.query.get(id_usuario)
        if not usuario:
            raise NotFound("Usuario no encontrado")
        db.session.delete(usuario)
        db.session.commit()
        return {'mensaje': 'Usuario eliminado'}

@api.route('/login')
class Login(Resource):
    @api.expect(login_input)
    @api.marshal_with(usuario_model)
    def post(self):
        data = request.get_json()
        if not data or 'username' not in data or 'hash_contraseña' not in data:
            return {'error': 'Faltan campos requeridos'}, 400
        username = data['username'].strip().lower()
        hash_contraseña = data['hash_contraseña']
        usuario = Usuario.query.filter(func.lower(Usuario.username) == username).first()
        if not usuario or usuario.hash_contraseña != hash_contraseña:
            return {'error': 'Usuario o contraseña incorrectos'}, 401
        return usuario, 200

# Endpoints de Categorías
@categorias_ns.route('/')
class CategoriaList(Resource):
    @categorias_ns.marshal_list_with(categoria_model)
    def get(self):
        return Categoria.query.all()

    @categorias_ns.expect(categoria_model)
    @categorias_ns.marshal_with(categoria_model, code=201)
    def post(self):
        data = request.get_json()
        nueva_categoria = Categoria(
            nombre=data['nombre'],
            descripcion=data.get('descripcion', '')
        )
        db.session.add(nueva_categoria)
        db.session.commit()
        return nueva_categoria, 201

@categorias_ns.route('/<int:id_categoria>')
class CategoriaResource(Resource):
    @categorias_ns.marshal_with(categoria_model)
    def get(self, id_categoria):
        categoria = Categoria.query.get(id_categoria)
        if not categoria:
            raise NotFound("Categoría no encontrada")
        return categoria

    def delete(self, id_categoria):
        categoria = Categoria.query.get(id_categoria)
        if not categoria:
            raise NotFound("Categoría no encontrada")
        db.session.delete(categoria)
        db.session.commit()
        return {'mensaje': 'Categoría eliminada'}

# Endpoints de Reactivos
@reactivos_ns.route('/')
class ReactivoList(Resource):
    @reactivos_ns.marshal_list_with(reactivo_model)
    def get(self):
        return Reactivo.query.join(Categoria).all()

    @reactivos_ns.expect(reactivo_input)
    @reactivos_ns.marshal_with(reactivo_model, code=201)
    def post(self):
        data = request.get_json()
        nuevo_reactivo = Reactivo(
            nombre=data['nombre'],
            cantidad=data['cantidad'],
            unidad=data['unidad'],
            minimo=data['minimo'],
            ubicacion=data['ubicacion'],
            id_categoria=data['id_categoria'],
            creado_por=data.get('creado_por')
        )
        db.session.add(nuevo_reactivo)
        db.session.commit()
        return nuevo_reactivo, 201

@reactivos_ns.route('/<int:id_reactivo>')
class ReactivoResource(Resource):
    @reactivos_ns.marshal_with(reactivo_model)
    def get(self, id_reactivo):
        reactivo = Reactivo.query.get(id_reactivo)
        if not reactivo:
            raise NotFound("Reactivo no encontrado")
        return reactivo

    @reactivos_ns.expect(reactivo_input)
    @reactivos_ns.marshal_with(reactivo_model)
    def put(self, id_reactivo):
        reactivo = Reactivo.query.get(id_reactivo)
        if not reactivo:
            raise NotFound("Reactivo no encontrado")
        data = request.get_json()
        reactivo.nombre = data['nombre']
        reactivo.cantidad = data['cantidad']
        reactivo.unidad = data['unidad']
        reactivo.minimo = data['minimo']
        reactivo.ubicacion = data['ubicacion']
        reactivo.id_categoria = data['id_categoria']
        db.session.commit()
        return reactivo

    def delete(self, id_reactivo):
        reactivo = Reactivo.query.get(id_reactivo)
        if not reactivo:
            raise NotFound("Reactivo no encontrado")
        db.session.delete(reactivo)
        db.session.commit()
        return {'mensaje': 'Reactivo eliminado'}

# Endpoints de Solicitudes
@solicitudes_ns.route('/')
class SolicitudList(Resource):
    @solicitudes_ns.marshal_list_with(solicitud_model)
    def get(self):
        return Solicitud.query.join(Reactivo).join(Usuario).all()

    @solicitudes_ns.expect(solicitud_input)
    @solicitudes_ns.marshal_with(solicitud_model, code=201)
    def post(self):
        data = request.get_json()
        nueva_solicitud = Solicitud(
            id_reactivo=data['id_reactivo'],
            cantidad=data['cantidad'],
            proyecto=data['proyecto'],
            es_proyecto=data['es_proyecto'],
            id_usuario=data['id_usuario']
        )
        reactivo = Reactivo.query.get(data['id_reactivo'])
        if not reactivo:
            return {'error': 'Reactivo no encontrado'}, 404
        if reactivo.cantidad < data['cantidad']:
            return {'error': 'Cantidad insuficiente del reactivo'}, 400
        reactivo.cantidad -= data['cantidad']
        db.session.add(nueva_solicitud)
        db.session.commit()
        return nueva_solicitud, 201

@solicitudes_ns.route('/<int:id_solicitud>')
class SolicitudResource(Resource):
    @solicitudes_ns.marshal_with(solicitud_model)
    def get(self, id_solicitud):
        solicitud = Solicitud.query.get(id_solicitud)
        if not solicitud:
            raise NotFound("Solicitud no encontrada")
        return solicitud

    def delete(self, id_solicitud):
        solicitud = Solicitud.query.get(id_solicitud)
        if not solicitud:
            raise NotFound("Solicitud no encontrada")
        reactivo = Reactivo.query.get(solicitud.id_reactivo)
        if reactivo:
            reactivo.cantidad += solicitud.cantidad
        db.session.delete(solicitud)
        db.session.commit()
        return {'mensaje': 'Solicitud eliminada'}

# Endpoints de Tareas
@tareas_ns.route('/')
class TareaList(Resource):
    @tareas_ns.marshal_list_with(tarea_model)
    def get(self):
        user_id = request.args.get('user_id', type=int)
        tasks = Tarea.query.join(Usuario, Tarea.creado_por == Usuario.id_usuario, isouter=True).all()
        if user_id:
            entregas = Entrega.query.filter_by(id_alumno=user_id).all()
            entregadas_ids = {entrega.id_tarea for entrega in entregas}
            for task in tasks:
                task.status = 'completed' if task.id in entregadas_ids else 'pending'
        return tasks

    @tareas_ns.expect(tarea_input)
    @tareas_ns.marshal_with(tarea_model, code=201)
    def post(self):
        file = request.files.get('file')
        data = request.form

        if not data or 'titulo' not in data or 'creado_por' not in data:
            return {'error': 'Faltan campos requeridos'}, 400

        file_path = None
        if file and file.filename:
            if not allowed_file(file.filename):
                return {'error': 'Tipo de archivo no permitido. Use: ' + ', '.join(ALLOWED_EXTENSIONS)}, 400
            filename = secure_filename(file.filename)
            unique_filename = f"{int(datetime.now().timestamp())}_{filename}"
            file_path = os.path.join(app.config['UPLOAD_FOLDER'], unique_filename)
            try:
                file.save(file_path)
            except Exception as e:
                return {'error': f'Error al guardar el archivo: {str(e)}'}, 500

        hora_cierre = None
        if 'hora_cierre' in data and data['hora_cierre']:
            try:
                hora_parts = list(map(int, data['hora_cierre'].split(':')))
                hora_cierre = time(*hora_parts)
            except (ValueError, AttributeError):
                return {'error': 'Formato de hora inválido. Use HH:MM o HH:MM:SS'}, 400

        nueva_tarea = Tarea(
            titulo=data['titulo'],
            descripcion=data.get('descripcion'),
            fecha_entrega=data.get('fecha_entrega'),
            hora_cierre=hora_cierre,
            creado_por=data['creado_por'],
            archivo_ruta=file_path
        )
        db.session.add(nueva_tarea)
        db.session.commit()
        return nueva_tarea, 201

@tareas_ns.route('/<int:id_tarea>')
class TareaResource(Resource):
    @tareas_ns.marshal_with(tarea_model)
    def get(self, id_tarea):
        tarea = Tarea.query.get(id_tarea)
        if not tarea:
            raise NotFound("Tarea no encontrada")
        return tarea

    @tareas_ns.expect(tarea_input)
    @tareas_ns.marshal_with(tarea_model)
    def put(self, id_tarea):
        tarea = Tarea.query.get(id_tarea)
        if not tarea:
            raise NotFound("Tarea no encontrada")
        data = request.form
        file = request.files.get('file')

        file_path = tarea.archivo_ruta
        if file and file.filename:
            if not allowed_file(file.filename):
                return {'error': 'Tipo de archivo no permitido. Use: ' + ', '.join(ALLOWED_EXTENSIONS)}, 400
            filename = secure_filename(file.filename)
            unique_filename = f"{int(datetime.now().timestamp())}_{filename}"
            file_path = os.path.join(app.config['UPLOAD_FOLDER'], unique_filename)
            try:
                file.save(file_path)
            except Exception as e:
                return {'error': f'Error al guardar el archivo: {str(e)}'}, 500

        hora_cierre = None
        if 'hora_cierre' in data and data['hora_cierre']:
            try:
                hora_parts = list(map(int, data['hora_cierre'].split(':')))
                hora_cierre = time(*hora_parts)
            except (ValueError, AttributeError):
                return {'error': 'Formato de hora inválido. Use HH:MM o HH:MM:SS'}, 400

        tarea.titulo = data['titulo']
        tarea.descripcion = data.get('descripcion')
        tarea.fecha_entrega = data.get('fecha_entrega')
        tarea.hora_cierre = hora_cierre
        tarea.archivo_ruta = file_path
        db.session.commit()
        return tarea

    def delete(self, id_tarea):
        tarea = Tarea.query.get(id_tarea)
        if not tarea:
            raise NotFound("Tarea no encontrada")
        if tarea.archivo_ruta and os.path.exists(tarea.archivo_ruta):
            os.remove(tarea.archivo_ruta)
        db.session.delete(tarea)
        db.session.commit()
        return {'mensaje': 'Tarea eliminada'}

# Endpoints de Entregas
@entregas_ns.route('/')
class EntregaList(Resource):
    @entregas_ns.marshal_list_with(entrega_model)
    def get(self):
        return Entrega.query.join(Usuario).join(Tarea).all()

    @entregas_ns.expect(entrega_input)
    @entregas_ns.marshal_with(entrega_model, code=201)
    def post(self):
        file = request.files.get('file')
        data = request.form

        if not data or 'id_tarea' not in data or 'id_alumno' not in data:
            return {'error': 'Faltan campos requeridos'}, 400

        tarea = Tarea.query.get(data['id_tarea'])
        if not tarea:
            return {'error': 'Tarea no encontrada'}, 404
        alumno = Usuario.query.get(data['id_alumno'])
        if not alumno:
            return {'error': 'Alumno no encontrado'}, 404

        file_path = None
        if file and file.filename:
            if not allowed_file(file.filename):
                return {'error': 'Tipo de archivo no permitido. Use: ' + ', '.join(ALLOWED_EXTENSIONS)}, 400
            filename = secure_filename(file.filename)
            unique_filename = f"{int(datetime.now().timestamp())}_{filename}"
            file_path = os.path.join(app.config['UPLOAD_FOLDER'], unique_filename)
            try:
                file.save(file_path)
            except Exception as e:
                return {'error': f'Error al guardar el archivo: {str(e)}'}, 500

        nueva_entrega = Entrega(
            id_tarea=data['id_tarea'],
            id_alumno=data['id_alumno'],
            archivo_ruta=file_path,
            calificacion=data.get('calificacion'),
            observaciones=data.get('observaciones')
        )
        db.session.add(nueva_entrega)
        db.session.commit()
        return nueva_entrega, 201

@entregas_ns.route('/<int:id_entrega>')
class EntregaResource(Resource):
    @entregas_ns.marshal_with(entrega_model)
    def get(self, id_entrega):
        entrega = Entrega.query.get(id_entrega)
        if not entrega:
            raise NotFound("Entrega no encontrada")
        return entrega

    @entregas_ns.expect(entrega_input)
    @entregas_ns.marshal_with(entrega_model)
    def put(self, id_entrega):
        entrega = Entrega.query.get(id_entrega)
        if not entrega:
            raise NotFound("Entrega no encontrada")
        data = request.form
        file = request.files.get('file')

        file_path = entrega.archivo_ruta
        if file and file.filename:
            if not allowed_file(file.filename):
                return {'error': 'Tipo de archivo no permitido. Use: ' + ', '.join(ALLOWED_EXTENSIONS)}, 400
            filename = secure_filename(file.filename)
            unique_filename = f"{int(datetime.now().timestamp())}_{filename}"
            file_path = os.path.join(app.config['UPLOAD_FOLDER'], unique_filename)
            try:
                file.save(file_path)
            except Exception as e:
                return {'error': f'Error al guardar el archivo: {str(e)}'}, 500

        entrega.archivo_ruta = file_path
        entrega.calificacion = data.get('calificacion', entrega.calificacion)
        entrega.observaciones = data.get('observaciones', entrega.observaciones)
        db.session.commit()
        return entrega

    def delete(self, id_entrega):
        entrega = Entrega.query.get(id_entrega)
        if not entrega:
            raise NotFound("Entrega no encontrada")
        if entrega.archivo_ruta and os.path.exists(entrega.archivo_ruta):
            os.remove(entrega.archivo_ruta)
        db.session.delete(entrega)
        db.session.commit()
        return {'mensaje': 'Entrega eliminada'}

# Endpoint para descargar archivos
@api.route('/download/<string:resource_type>/<int:resource_id>')
class DownloadFile(Resource):
    def get(self, resource_type, resource_id):
        if resource_type not in ['tarea', 'entrega']:
            return {'error': 'Tipo de recurso inválido. Use "tarea" o "entrega"'}, 400

        if resource_type == 'tarea':
            resource = Tarea.query.get(resource_id)
            if not resource:
                return {'error': 'Tarea no encontrada'}, 404
        else:
            resource = Entrega.query.get(resource_id)
            if not resource:
                return {'error': 'Entrega no encontrada'}, 404

        if not resource.archivo_ruta or not os.path.exists(resource.archivo_ruta):
            return {'error': 'Archivo no encontrado'}, 404

        try:
            return send_file(
                resource.archivo_ruta,
                as_attachment=True,
                download_name=os.path.basename(resource.archivo_ruta)
            )
        except Exception as e:
            return {'error': f'Error al descargar el archivo: {str(e)}'}, 500

# Endpoint para obtener entregas por tarea
@tareas_ns.route('/<int:id_tarea>/entregas')
class EntregasPorTarea(Resource):
    @tareas_ns.marshal_list_with(entrega_model)
    def get(self, id_tarea):
        tarea = Tarea.query.get(id_tarea)
        if not tarea:
            raise NotFound("Tarea no encontrada")
        return tarea.entregas

# Endpoint para obtener entregas por alumno
@usuarios_ns.route('/<int:id_usuario>/entregas')
class EntregasPorAlumno(Resource):
    @usuarios_ns.marshal_list_with(entrega_model)
    def get(self, id_usuario):
        usuario = Usuario.query.get(id_usuario)
        if not usuario:
            raise NotFound("Usuario no encontrado")
        return usuario.entregas

# Endpoints de Avisos
@avisos_ns.route('/')
class AvisoList(Resource):
    @avisos_ns.marshal_list_with(aviso_model)
    def get(self):
        return Aviso.query.join(Usuario).all()

    @avisos_ns.expect(aviso_input)
    @avisos_ns.marshal_with(aviso_model, code=201)
    def post(self):
        data = request.get_json()
        if not data or not all(key in data for key in ['id_usuario', 'titulo', 'texto']):
            return {'error': 'Faltan campos requeridos'}, 400
        usuario = Usuario.query.get(data['id_usuario'])
        if not usuario:
            return {'error': 'Usuario no encontrado'}, 404
        nuevo_aviso = Aviso(
            id_usuario=data['id_usuario'],
            titulo=data.get('titulo', 'Sin título'),
            texto=data['texto']
        )
        db.session.add(nuevo_aviso)
        db.session.commit()
        return nuevo_aviso, 201

@avisos_ns.route('/<int:id_aviso>')
class AvisoResource(Resource):
    @avisos_ns.marshal_with(aviso_model)
    def get(self, id_aviso):
        aviso = Aviso.query.get(id_aviso)
        if not aviso:
            raise NotFound("Aviso no encontrado")
        return aviso

    @avisos_ns.expect(aviso_input)
    @avisos_ns.marshal_with(aviso_model)
    def put(self, id_aviso):
        aviso = Aviso.query.get(id_aviso)
        if not aviso:
            raise NotFound("Aviso no encontrado")
        data = request.get_json()
        usuario = Usuario.query.get(data['id_usuario'])
        if not usuario:
            return {'error': 'Usuario no encontrado'}, 404
        aviso.id_usuario = data['id_usuario']
        aviso.titulo = data.get('titulo', aviso.titulo)
        aviso.texto = data['texto']
        db.session.commit()
        return aviso

    def delete(self, id_aviso):
        aviso = Aviso.query.get(id_aviso)
        if not aviso:
            raise NotFound("Aviso no encontrado")
        db.session.delete(aviso)
        db.session.commit()
        return {'mensaje': 'Aviso eliminado'}

@app.route('/healthcheck')
def healthcheck():
    try:
        db.session.execute('SELECT 1')
        return {'status': 'OK', 'database': 'connected'}
    except Exception as e:
        return {'status': 'Error', 'message': str(e)}, 500

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(debug=True, host='0.0.0.0', port=5000)