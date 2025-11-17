import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_application_hola/src/services/api_inventory__service.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class InventoryScreen extends StatefulWidget {
  final int userId;
  final String userRole;

  const InventoryScreen({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Reactivo> _reactivos = [];
  List<Categoria> _categorias = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoriaFiltro;
  bool _showFab = true;
  late ScrollController _scrollController;
  bool _isProcessing = false; // Control para evitar múltiples procesos

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (_showFab) setState(() => _showFab = false);
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!_showFab) setState(() => _showFab = true);
      }
    });
  }

  Future<void> _fetchData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final reactivos = await ApiService.getReactivos();
      final categorias = await ApiService.getCategorias();
      setState(() {
        _reactivos = reactivos.map((r) => Reactivo.fromJson(r)).toList();
        _categorias = categorias.map((c) => Categoria.fromJson(c)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar datos: $e';
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reactivosBajos = _reactivos.where((r) => r.cantidad < r.minimo).toList();
    final reactivosDisponibles = _reactivos.where((r) => r.cantidad >= r.minimo).toList();
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Inventario de Reactivos',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.indigo[900],
        elevation: 4,
        shadowColor: Colors.black26,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _fetchData,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _buildInventoryTab(reactivosBajos, reactivosDisponibles, _categorias, screenWidth),
    );
  }

  Widget _buildInventoryTab(List<Reactivo> reactivosBajos, List<Reactivo> reactivosDisponibles, List<Categoria> categorias, double screenWidth) {
    final filteredReactivos = _reactivos.where((r) {
      final matchesSearch = r.nombre.toLowerCase().contains(_searchQuery) ||
          r.categoria.toLowerCase().contains(_searchQuery);
      final matchesCategoria = _selectedCategoriaFiltro == null || r.categoria == _selectedCategoriaFiltro;
      return matchesSearch && matchesCategoria;
    }).toList();

    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    _buildCategoryFilter(categorias),
                    const SizedBox(height: 24),
                    PieChartWidget(bajos: reactivosBajos.length, disponibles: reactivosDisponibles.length),
                    const SizedBox(height: 24),
                    // CARDS EN HORIZONTAL RESPONSIVE
                    SizedBox(
                      height: 100,
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              title: 'Por agotarse',
                              value: reactivosBajos.length.toString(),
                              color: Colors.amber[700]!,
                              icon: Icons.warning_amber_outlined,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryCard(
                              title: 'Disponibles',
                              value: reactivosDisponibles.length.toString(),
                              color: Colors.green[600]!,
                              icon: Icons.check_circle_outlined,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryCard(
                              title: 'Total',
                              value: _reactivos.length.toString(),
                              color: Colors.indigo[900]!,
                              icon: Icons.science_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (reactivosBajos.isNotEmpty) ...[
                      _buildSectionTitle('Reactivos por Agotarse', Colors.amber[800]!),
                      ...reactivosBajos.map((r) => ReactivoCard(
                        reactivo: r, 
                        isLow: true, 
                        onQuantityUpdated: _fetchData,
                        isProcessing: _isProcessing,
                        onProcessingChange: (processing) {
                          setState(() {
                            _isProcessing = processing;
                          });
                        },
                      )),
                      const SizedBox(height: 24),
                    ],
                    _buildSectionTitle('Reactivos por Categoría', Colors.indigo[800]!),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final categoria = categorias[index];
                  final reactivosCategoria = filteredReactivos.where((r) => r.categoria == categoria.nombre).toList();
                  return CategorySectionWidget(
                    categoria: categoria,
                    reactivos: reactivosCategoria,
                    onQuantityUpdated: _fetchData,
                    isProcessing: _isProcessing,
                    onProcessingChange: (processing) {
                      setState(() {
                        _isProcessing = processing;
                      });
                    },
                  );
                },
                childCount: categorias.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
        if (_isProcessing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Procesando...',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryCard({required String title, required String value, required Color color, required IconData icon}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold, 
                color: color
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar reactivo o categoría...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
          prefixIcon: Icon(Icons.search, color: Colors.indigo[400], size: 24),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(List<Categoria> categorias) {
    return DropdownButtonFormField<String?>(
      value: _selectedCategoriaFiltro,
      decoration: InputDecoration(
        hintText: 'Filtrar por categoría',
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
        prefixIcon: Icon(Icons.filter_list, color: Colors.indigo[400], size: 24),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.indigo[600]!, width: 1.5)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('Todas las categorías', style: TextStyle(fontSize: 16))),
        ...categorias.map((categoria) => DropdownMenuItem<String>(value: categoria.nombre, child: Text(categoria.nombre, style: const TextStyle(fontSize: 16)))),
      ],
      onChanged: (value) {
        setState(() {
          _selectedCategoriaFiltro = value;
        });
      },
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class PieChartWidget extends StatelessWidget {
  final int bajos;
  final int disponibles;

  const PieChartWidget({super.key, required this.bajos, required this.disponibles});

  @override
  Widget build(BuildContext context) {
    final data = [
      _ChartData('Por agotarse', bajos, const Color(0xFFFFA000)),
      _ChartData('Disponibles', disponibles, const Color(0xFF43A047)),
    ];

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo[50]!,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            Text(
              'Estado del Inventario', 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.indigo[900])
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: SfCircularChart(
                palette: const [
                  Color(0xFFFFA000),
                  Color(0xFF43A047),
                ],
                series: <CircularSeries>[
                  PieSeries<_ChartData, String>(
                    dataSource: data,
                    xValueMapper: (_ChartData data, _) => data.label,
                    yValueMapper: (_ChartData data, _) => data.value,
                    pointColorMapper: (_ChartData data, _) => data.color,
                    dataLabelMapper: (_ChartData data, _) => '${data.value}',
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.inside,
                      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    radius: '80%',
                    animationDuration: 800,
                  ),
                ],
                legend: Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                  overflowMode: LegendItemOverflowMode.wrap,
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  orientation: LegendItemOrientation.horizontal,
                ),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  format: 'point.x : point.y reactivos',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReactivoCard extends StatelessWidget {
  final Reactivo reactivo;
  final bool isLow;
  final VoidCallback onQuantityUpdated;
  final bool isProcessing;
  final Function(bool) onProcessingChange;

  const ReactivoCard({
    super.key, 
    required this.reactivo, 
    required this.isLow, 
    required this.onQuantityUpdated,
    required this.isProcessing,
    required this.onProcessingChange,
  });

  void _showUseDialog(BuildContext context) {
    // Si ya hay un proceso en curso, no permitir otro
    if (isProcessing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya hay una operación en curso. Por favor espera.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final TextEditingController cantidadController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Usar ${reactivo.nombre}',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo[900]),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cantidad actual: ${reactivo.cantidad} ${reactivo.unidad}', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            Text('Mínimo requerido: ${reactivo.minimo} ${reactivo.unidad}', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            TextField(
              controller: cantidadController,
              decoration: InputDecoration(
                labelText: 'Cantidad a usar',
                labelStyle: TextStyle(fontSize: 16),
                hintText: 'Ej: 5.0 (máximo: ${reactivo.cantidad})',
                hintStyle: TextStyle(fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Ejemplo: Si necesitas 2.5 ${reactivo.unidad} para tu experimento, ingresa 2.5',
              style: TextStyle(fontSize: 14, color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => _confirmUse(context, cantidadController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[600],
            ),
            child: const Text('Continuar', style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmUse(BuildContext context, String cantidadText) {
    final cantidad = double.tryParse(cantidadText);
    
    // Validaciones
    if (cantidad == null || cantidad <= 0) {
      _showErrorDialog(context, 'Cantidad inválida', 'Por favor ingresa una cantidad válida mayor a 0.');
      return;
    }
    
    if (cantidad > reactivo.cantidad) {
      _showErrorDialog(
        context, 
        'Cantidad insuficiente', 
        'No puedes usar más de ${reactivo.cantidad} ${reactivo.unidad}. La cantidad disponible es insuficiente.'
      );
      return;
    }

    // Mostrar diálogo de confirmación
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirmar uso',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo[900]),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Estás seguro de que deseas usar $cantidad ${reactivo.unidad} de ${reactivo.nombre}?',
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Cantidad después del uso: ${reactivo.cantidad - cantidad} ${reactivo.unidad}',
                style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            if (reactivo.cantidad - cantidad < reactivo.minimo) ...[
              const SizedBox(height: 8),
              Text(
                '⚠️ Esta cantidad está por debajo del mínimo requerido',
                style: TextStyle(fontSize: 14, color: Colors.amber[700], fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => _processUse(context, cantidad),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
            ),
            child: const Text('Confirmar uso', style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _processUse(BuildContext context, double cantidad) async {
    // Iniciar procesamiento
    onProcessingChange(true);
    
    try {
      // Cerrar diálogos anteriores
      if (context.mounted) {
        Navigator.pop(context); // Cerrar diálogo de confirmación
        Navigator.pop(context); // Cerrar diálogo principal
      }

      // Realizar la actualización
      await ApiService.updateReactivo(
        idReactivo: reactivo.idReactivo,
        nombre: reactivo.nombre,
        cantidad: reactivo.cantidad - cantidad,
        unidad: reactivo.unidad,
        minimo: reactivo.minimo,
        ubicacion: reactivo.ubicacion,
        idCategoria: reactivo.idCategoria,
      );

      // Mostrar mensaje de éxito
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Se usaron $cantidad ${reactivo.unidad} de ${reactivo.nombre}'),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Actualizar la lista
      onQuantityUpdated();

    } catch (e) {
      // Mostrar error
      if (context.mounted) {
        _showErrorDialog(
          context, 
          'Error al procesar', 
          'Ocurrió un error al intentar usar el reactivo: $e'
        );
      }
    } finally {
      // Siempre detener el procesamiento, incluso si hay error
      onProcessingChange(false);
    }
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red[700])),
        content: Text(message, style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final porcentaje = (reactivo.cantidad / reactivo.minimo).clamp(0.0, 1.0);
    final cantidadText = reactivo.cantidad == 0 ? 'AGOTADO' : '${reactivo.cantidad} ${reactivo.unidad}';
    final cantidadColor = reactivo.cantidad == 0 ? Colors.red : (isLow ? Colors.amber[800] : Colors.green[800]);
    final backgroundColor = reactivo.cantidad == 0 ? Colors.red[100] : (isLow ? Colors.amber[100] : Colors.green[100]);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    reactivo.nombre,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.indigo[900]),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cantidadText,
                    style: TextStyle(
                      color: cantidadColor,
                      fontWeight: FontWeight.w600,
                      fontSize: reactivo.cantidad == 0 ? 14 : 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.category_outlined, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reactivo.categoria,
                    style: TextStyle(color: Colors.grey[700], fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                Icon(Icons.location_on_outlined, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reactivo.ubicacion,
                    style: TextStyle(color: Colors.grey[700], fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nivel: ${reactivo.cantidad == 0 ? 'AGOTADO' : '${(porcentaje * 100).toStringAsFixed(0)}%'}',
                      style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.w500, 
                        color: reactivo.cantidad == 0 ? Colors.red : Colors.grey[700]
                      ),
                    ),
                    Text(
                      'Mínimo: ${reactivo.minimo} ${reactivo.unidad}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: reactivo.cantidad == 0 ? 0 : porcentaje,
                  backgroundColor: Colors.grey[200],
                  color: reactivo.cantidad == 0 ? Colors.red : (isLow ? Colors.amber[600] : Colors.green[600]),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // BOTÓN DE USAR - DESHABILITADO SI ESTÁ AGOTADO O EN PROCESO
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (reactivo.cantidad == 0 || isProcessing) ? null : () => _showUseDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: reactivo.cantidad == 0 ? Colors.grey[400] : Colors.indigo[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: Icon(
                  reactivo.cantidad == 0 ? Icons.block : Icons.science_outlined, 
                  size: 18
                ),
                label: Text(
                  reactivo.cantidad == 0 ? 'AGOTADO' : 
                  isProcessing ? 'Procesando...' : 'Usar Reactivo',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategorySectionWidget extends StatelessWidget {
  final Categoria categoria;
  final List<Reactivo> reactivos;
  final VoidCallback onQuantityUpdated;
  final bool isProcessing;
  final Function(bool) onProcessingChange;

  const CategorySectionWidget({
    super.key,
    required this.categoria,
    required this.reactivos,
    required this.onQuantityUpdated,
    required this.isProcessing,
    required this.onProcessingChange,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ExpansionTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  categoria.nombre,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.indigo[800]),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.indigo[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${reactivos.length}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.indigo[800]),
                ),
              ),
            ],
          ),
          subtitle: categoria.descripcion != null ? Text(categoria.descripcion!, style: const TextStyle(fontSize: 14)) : null,
          iconColor: Colors.indigo[600],
          collapsedIconColor: Colors.indigo[400],
          childrenPadding: const EdgeInsets.all(16),
          children: reactivos.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No hay reactivos en esta categoría',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600], fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ]
              : reactivos.map((r) => ReactivoCard(
                    reactivo: r, 
                    isLow: r.cantidad < r.minimo, 
                    onQuantityUpdated: onQuantityUpdated,
                    isProcessing: isProcessing,
                    onProcessingChange: onProcessingChange,
                  )).toList(),
        ),
      ),
    );
  }
}

class Reactivo {
  final int idReactivo;
  final String nombre;
  final double cantidad;
  final String unidad;
  final double minimo;
  final String categoria;
  final String ubicacion;
  final int idCategoria;

  const Reactivo({
    required this.idReactivo,
    required this.nombre,
    required this.cantidad,
    required this.unidad,
    required this.minimo,
    required this.categoria,
    required this.ubicacion,
    required this.idCategoria,
  });

  factory Reactivo.fromJson(Map<String, dynamic> json) {
    return Reactivo(
      idReactivo: json['id_reactivo'],
      nombre: json['nombre'],
      cantidad: (json['cantidad'] as num).toDouble(),
      unidad: json['unidad'],
      minimo: (json['minimo'] as num).toDouble(),
      categoria: json['categoria']['nombre'],
      ubicacion: json['ubicacion'],
      idCategoria: json['id_categoria'],
    );
  }
}

class Categoria {
  final int idCategoria;
  final String nombre;
  final String? descripcion;

  const Categoria({
    required this.idCategoria,
    required this.nombre,
    this.descripcion,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      idCategoria: json['id_categoria'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
    );
  }
}

class _ChartData {
  final String label;
  final int value;
  final Color color;

  const _ChartData(this.label, this.value, this.color);
}