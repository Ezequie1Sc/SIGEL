import 'package:flutter/material.dart';
import 'package:flutter_application_hola/src/services/api_inventory__service.dart';

class AddrecScreen extends StatefulWidget {
  const AddrecScreen({super.key});

  @override
  State<AddrecScreen> createState() => _AddrecScreenState();
}

class _AddrecScreenState extends State<AddrecScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _unidadController = TextEditingController();
  final TextEditingController _minimoController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();
  int? _selectedCategoriaId;
  List<Map<String, dynamic>> _categorias = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCategorias();
  }

  Future<void> _fetchCategorias() async {
    try {
      final response = await ApiService.getCategorias();
      setState(() {
        _categorias = response.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar categorías: ${e.toString().replaceAll('Exception: ', '')}';
      });
    }
  }

  Future<void> _addReactivo() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      try {
        await ApiService.createReactivo(
          nombre: _nombreController.text,
          cantidad: double.parse(_cantidadController.text),
          unidad: _unidadController.text,
          minimo: double.parse(_minimoController.text),
          ubicacion: _ubicacionController.text,
          idCategoria: _selectedCategoriaId!,
          creadoPor: 1,
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Reactivo agregado exitosamente'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: Colors.green[600],
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error al agregar reactivo: ${e.toString().replaceAll('Exception: ', '')}';
        });
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Nuevo Reactivo', 
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo[800],
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              shadowColor: Colors.indigo.withOpacity(0.2),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Información del Reactivo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        _nombreController, 
                        'Nombre del reactivo', 
                        Icons.science,
                        hintText: 'Ej: Ácido clorhídrico',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildTextField(
                              _cantidadController, 
                              'Cantidad', 
                              Icons.format_list_numbered,
                              keyboardType: TextInputType.number,
                              hintText: '0.00',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: _buildTextField(
                              _unidadController, 
                              'Unidad', 
                              Icons.scale,
                              hintText: 'ml, g, etc.',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        _minimoController, 
                        'Cantidad mínima', 
                        Icons.warning_amber_rounded,
                        keyboardType: TextInputType.number,
                        hintText: '0.00',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        _ubicacionController, 
                        'Ubicación en almacén', 
                        Icons.place_outlined,
                        hintText: 'Ej: Estante A-2',
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(),
                      const SizedBox(height: 32),
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red[800]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_errorMessage != null) const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _addReactivo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          shadowColor: Colors.indigo.withOpacity(0.4),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'GUARDAR REACTIVO',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_categorias.isEmpty && _errorMessage == null)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String label, 
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.indigo[400]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.indigo[400]!, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        labelStyle: TextStyle(color: Colors.grey[600]),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      keyboardType: keyboardType,
      validator: (value) => value!.isEmpty || (keyboardType == TextInputType.number && double.tryParse(value) == null)
          ? 'Campo requerido'
          : null,
      style: const TextStyle(fontSize: 15),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedCategoriaId,
      decoration: InputDecoration(
        labelText: 'Categoría',
        prefixIcon: Icon(Icons.category_outlined, color: Colors.indigo[400]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.indigo[400]!, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      ),
      items: _categorias
          .map((categoria) => DropdownMenuItem<int>(
                value: categoria['id_categoria'],
                child: Text(
                  categoria['nombre'],
                  style: const TextStyle(fontSize: 15),
                ),
              ))
          .toList(),
      onChanged: (value) => setState(() => _selectedCategoriaId = value),
      validator: (value) => value == null ? 'Seleccione una categoría' : null,
      dropdownColor: Colors.white,
      isExpanded: true,
      icon: Icon(Icons.arrow_drop_down, color: Colors.indigo[400]),
      style: const TextStyle(color: Colors.black87),
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
    );
  }
}