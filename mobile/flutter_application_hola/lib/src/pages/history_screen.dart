import 'package:flutter/material.dart';
import 'package:flutter_application_hola/src/pages/Teacher/teacheriventory_screen.dart';

/*class HistoryScreen extends StatefulWidget {
  final List<Request> solicitudes;

  const HistoryScreen({super.key, required this.solicitudes});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filtroEstado = 'Todos';
  String _orden = 'Recientes';

  List<Request> get _solicitudesFiltradas {
    List<Request> resultado = widget.solicitudes.where((s) => s.estado != 'Pendiente').toList();

    if (_filtroEstado == 'Aprobadas') {
      resultado = resultado.where((s) => s.estado == 'Aprobada').toList();
    } else if (_filtroEstado == 'Rechazadas') {
      resultado = resultado.where((s) => s.estado == 'Rechazada').toList();
    }

    if (_orden == 'Recientes') {
      resultado.sort((a, b) => b.fecha.compareTo(a.fecha));
    } else {
      resultado.sort((a, b) => a.fecha.compareTo(b.fecha));
    }

    return resultado;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              backgroundColor: Colors.indigo,
              title: const Text(
                'Historial de Solicitudes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 22,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.filter_alt, color: Colors.white),
                  onPressed: _mostrarOpcionesFiltrado,
                  tooltip: 'Filtrar',
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: _solicitudesFiltradas.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmptyState())
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final solicitud = _solicitudesFiltradas[index];
                          return _buildSolicitudCard(solicitud);
                        },
                        childCount: _solicitudesFiltradas.length,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 80,
            color: Colors.indigo,
          ),
          const SizedBox(height: 16),
          Text(
            _filtroEstado == 'Todos'
                ? 'No hay solicitudes en el historial'
                : 'No hay solicitudes ${_filtroEstado.toLowerCase()}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Colors.indigo,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSolicitudCard(Request solicitud) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 8,
        shadowColor: Colors.indigo,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _mostrarDetallesSolicitud(solicitud),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            solicitud.reactivoNombre,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Solicitante: ${solicitud.solicitante}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: solicitud.estado == 'Aprobada'
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        solicitud.estado,
                        style: TextStyle(
                          color: solicitud.estado == 'Aprobada'
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 1),
                _buildDetailRow('Cantidad:', '${solicitud.cantidad} ${solicitud.unidad}'),
                _buildDetailRow('Proyecto:', solicitud.proyecto),
                _buildDetailRow(
                  'Fecha:',
                  '${solicitud.fecha.day}/${solicitud.fecha.month}/${solicitud.fecha.year} '
                  '${solicitud.fecha.hour}:${solicitud.fecha.minute.toString().padLeft(2, '0')}',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.indigo,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarOpcionesFiltrado() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Filtrar y Ordenar',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 20),
              _buildFilterOption(
                'Estado',
                ['Todos', 'Aprobadas', 'Rechazadas'],
                _filtroEstado,
                (value) => setState(() => _filtroEstado = value),
              ),
              const Divider(height: 30),
              _buildFilterOption(
                'Orden',
                ['Recientes', 'Antiguas'],
                _orden,
                (value) => setState(() => _orden = value),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Aplicar Filtros',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String title, List<String> options, String currentValue, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.indigo,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: options.map((option) {
            return ChoiceChip(
              label: Text(
                option,
                style: TextStyle(
                  color: currentValue == option ? Colors.white : Colors.indigo,
                  fontWeight: FontWeight.w500,
                ),
              ),
              selected: currentValue == option,
              selectedColor: Colors.white,
              backgroundColor: Colors.teal.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onSelected: (selected) {
                if (selected) onChanged(option);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  void _mostrarDetallesSolicitud(Request solicitud) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Detalles de la solicitud',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.indigo),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDialogDetail('Reactivo:', solicitud.reactivoNombre),
                  _buildDialogDetail('Solicitante:', solicitud.solicitante),
                  _buildDialogDetail('Estado:', solicitud.estado),
                  _buildDialogDetail('Cantidad:', '${solicitud.cantidad} ${solicitud.unidad}'),
                  _buildDialogDetail('Proyecto:', solicitud.proyecto),
                  _buildDialogDetail(
                    'Fecha:',
                    '${solicitud.fecha.day}/${solicitud.fecha.month}/${solicitud.fecha.year} '
                    '${solicitud.fecha.hour}:${solicitud.fecha.minute.toString().padLeft(2, '0')}',
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cerrar',
                        style: TextStyle(
                          color: Colors.indigo,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.indigo,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
} */