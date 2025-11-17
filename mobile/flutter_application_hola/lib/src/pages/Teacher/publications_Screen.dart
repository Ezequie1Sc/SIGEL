import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PublicationsScreen extends StatefulWidget {
  const PublicationsScreen({super.key});

  @override
  State<PublicationsScreen> createState() => _PublicationsScreenState();
}

class _PublicationsScreenState extends State<PublicationsScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _publications = [];
  String _selectedGroup = 'Todos';
  final List<String> _groups = ['Todos', 'Equipo A', 'Equipo B', 'Equipo C'];
  bool _isEditing = false;
  int? _editingIndex;
  bool _isDarkMode = false;
  bool _isSearchActive = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _fabScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _addOrUpdatePublication() {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) return;

    setState(() {
      if (_isEditing && _editingIndex != null) {
        _publications[_editingIndex!] = {
          'title': _titleController.text,
          'content': _contentController.text,
          'date': DateTime.now().toString(),
          'group': _selectedGroup,
        };
      } else {
        _publications.insert(0, {
          'title': _titleController.text,
          'content': _contentController.text,
          'date': DateTime.now().toString(),
          'group': _selectedGroup,
        });
      }
      _titleController.clear();
      _contentController.clear();
      _selectedGroup = 'Todos';
      _isEditing = false;
      _editingIndex = null;
    });

    FocusScope.of(context).unfocus();
  }

  void _editPublication(int index) {
    setState(() {
      _titleController.text = _publications[index]['title'];
      _contentController.text = _publications[index]['content'];
      _selectedGroup = _publications[index]['group'];
      _isEditing = true;
      _editingIndex = index;
    });
    _scrollToTop();
  }

  void _deletePublication(int index) {
    setState(() {
      _publications.removeAt(index);
    });
  }

  void _scrollToTop() {
    PrimaryScrollController.of(context)?.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('dd MMM yyyy, hh:mm a', 'es').format(date);
  }

  Color _getGroupColor(String group) {
    switch (group) {
      case 'Equipo A':
        return Colors.indigo[300]!;
      case 'Equipo B':
        return Colors.indigo[500]!;
      case 'Equipo C':
        return Colors.indigo[700]!;
      default:
        return Colors.indigo[200]!;
    }
  }

  IconData _getGroupIcon(String group) {
    switch (group) {
      case 'Equipo A':
        return Icons.group;
      case 'Equipo B':
        return Icons.group_add;
      case 'Equipo C':
        return Icons.groups;
      default:
        return Icons.all_inclusive;
    }
  }

  List<Map<String, dynamic>> _filteredPublications() {
    String query = _searchController.text.toLowerCase();
    return _publications.where((publication) {
      bool matchesGroup = _selectedGroup == 'Todos' || publication['group'] == _selectedGroup;
      bool matchesSearch = query.isEmpty ||
          publication['title'].toLowerCase().contains(query) ||
          publication['content'].toLowerCase().contains(query);
      return matchesGroup && matchesSearch;
    }).toList();
  }

  int _getGroupCount(String group) {
    if (group == 'Todos') return _publications.length;
    return _publications.where((pub) => pub['group'] == group).length;
  }

  @override
  Widget build(BuildContext context) {
    final filteredPublications = _filteredPublications();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _isDarkMode ? Colors.indigo[900] : Colors.indigo[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            floating: false,
            pinned: true,
            backgroundColor: Colors.indigo[800],
            flexibleSpace: FlexibleSpaceBar(
              title: FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Avisos',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(1, 1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isDarkMode
                        ? [Colors.indigo[900]!, Colors.indigo[700]!]
                        : [Colors.indigo[800]!, Colors.indigo[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isSearchActive ? Icons.close : Icons.search,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () {
                  setState(() {
                    _isSearchActive = !_isSearchActive;
                    if (!_isSearchActive) _searchController.clear();
                  });
                },
              ),
              Switch(
                value: _isDarkMode,
                onChanged: (value) {
                  setState(() {
                    _isDarkMode = value;
                  });
                },
                activeColor: Colors.indigo[200],
                inactiveThumbColor: Colors.grey[400],
              ),
            ],
          ),
          if (_isSearchActive)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: _isDarkMode ? Colors.grey[800] : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.indigo[900]),
                      decoration: InputDecoration(
                        labelText: 'Buscar avisos',
                        labelStyle: TextStyle(
                          color: _isDarkMode ? Colors.grey[400] : Colors.indigo[700],
                          fontSize: 16,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: _isDarkMode ? Colors.grey[400] : Colors.indigo[600],
                        ),
                        border: InputBorder.none,
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: _isDarkMode ? Colors.grey[800] : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _titleController,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: _isDarkMode ? Colors.white : Colors.indigo[900],
                            ),
                            decoration: InputDecoration(
                              labelText: _isEditing ? 'Editar título' : 'Título del aviso',
                              labelStyle: TextStyle(
                                color: _isDarkMode ? Colors.grey[400] : Colors.indigo[700],
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: _isDarkMode ? Colors.grey[700] : Colors.indigo[50],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              suffixIcon: _titleController.text.isNotEmpty
                                  ? Icon(Icons.check_circle, color: Colors.green[400], size: 20)
                                  : null,
                            ),
                            onChanged: (value) => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _contentController,
                            maxLines: 3,
                            style: TextStyle(
                              fontSize: 16,
                              color: _isDarkMode ? Colors.white : Colors.indigo[900],
                            ),
                            decoration: InputDecoration(
                              labelText: 'Contenido',
                              labelStyle: TextStyle(
                                color: _isDarkMode ? Colors.grey[400] : Colors.indigo[700],
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: _isDarkMode ? Colors.grey[700] : Colors.indigo[50],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              suffixIcon: _contentController.text.isNotEmpty
                                  ? Icon(Icons.check_circle, color: Colors.green[400], size: 20)
                                  : null,
                            ),
                            onChanged: (value) => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedGroup,
                                  decoration: InputDecoration(
                                    labelText: 'Grupo',
                                    labelStyle: TextStyle(
                                      color: _isDarkMode ? Colors.grey[400] : Colors.indigo[700],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    filled: true,
                                    fillColor: _isDarkMode ? Colors.grey[700] : Colors.indigo[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                  items: _groups.map((String group) {
                                    return DropdownMenuItem<String>(
                                      value: group,
                                      child: Text(
                                        group,
                                        style: TextStyle(
                                          color: _isDarkMode ? Colors.white : Colors.indigo[900],
                                          fontSize: 16,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedGroup = newValue!;
                                    });
                                  },
                                  dropdownColor: _isDarkMode ? Colors.grey[800] : Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Material(
                                elevation: 4,
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: _addOrUpdatePublication,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.indigo[700]!, Colors.indigo[500]!],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _isEditing ? Icons.check : Icons.send,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _isEditing ? 'Guardar' : 'Publicar',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lista de Avisos',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : Colors.indigo[900],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isDarkMode ? Colors.grey[800] : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_list,
                            size: 20,
                            color: _isDarkMode ? Colors.grey[400] : Colors.indigo[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Filtro',
                            style: TextStyle(
                              color: _isDarkMode ? Colors.grey[400] : Colors.indigo[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onSelected: (String value) {
                      setState(() {
                        _selectedGroup = value;
                      });
                    },
                    itemBuilder: (BuildContext context) {
                      return _groups.map((String group) {
                        return PopupMenuItem<String>(
                          value: group,
                          child: Row(
                            children: [
                              Text(
                                group,
                                style: TextStyle(
                                  color: _isDarkMode ? Colors.white : Colors.indigo[900],
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getGroupColor(group).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _getGroupCount(group).toString(),
                                  style: TextStyle(
                                    color: _getGroupColor(group),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList();
                    },
                    color: _isDarkMode ? Colors.grey[800] : Colors.white,
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (filteredPublications.isEmpty) {
                  return Container(
                    height: MediaQuery.of(context).size.height - 300,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.announcement_outlined,
                          size: 60,
                          color: _isDarkMode ? Colors.grey[400] : Colors.indigo[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No hay avisos aún',
                          style: TextStyle(
                            fontSize: 18,
                            color: _isDarkMode ? Colors.grey[400] : Colors.indigo[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Publica un nuevo aviso para comenzar',
                          style: TextStyle(
                            fontSize: 16,
                            color: _isDarkMode ? Colors.grey[500] : Colors.indigo[400],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final publication = filteredPublications[index];
                final groupColor = _getGroupColor(publication['group']);
                return Dismissible(
                  key: Key(publication['date']),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(Icons.delete, color: Colors.red[400]),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.white,
                          title: Text(
                            'Confirmar',
                            style: TextStyle(
                              color: _isDarkMode ? Colors.white : Colors.indigo[900],
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: Text(
                            '¿Estás seguro de que deseas eliminar este aviso?',
                            style: TextStyle(
                              color: _isDarkMode ? Colors.grey[400] : Colors.indigo[700],
                              fontSize: 16,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(
                                'Cancelar',
                                style: TextStyle(
                                  color: _isDarkMode ? Colors.grey[400] : Colors.indigo[700],
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text(
                                'Eliminar',
                                style: TextStyle(color: Colors.red, fontSize: 16),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) => _deletePublication(index),
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: _isDarkMode ? Colors.grey[800] : Colors.white,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _editPublication(index),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: groupColor.withOpacity(0.2),
                                      child: Icon(
                                        _getGroupIcon(publication['group']),
                                        size: 18,
                                        color: groupColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      publication['group'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: groupColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.announcement,
                                  size: 20,
                                  color: _isDarkMode ? Colors.grey[400] : Colors.indigo[500],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              publication['title'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _isDarkMode ? Colors.white : Colors.indigo[900],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              publication['content'],
                              style: TextStyle(
                                fontSize: 16,
                                color: _isDarkMode ? Colors.grey[400] : Colors.indigo[700],
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.event,
                                  size: 16,
                                  color: _isDarkMode ? Colors.grey[400] : Colors.indigo[500],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatDate(publication['date']),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _isDarkMode ? Colors.grey[400] : Colors.indigo[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              childCount: filteredPublications.isEmpty ? 1 : filteredPublications.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: _publications.isNotEmpty
          ? ScaleTransition(
              scale: _fabScaleAnimation,
              child: FloatingActionButton(
                onPressed: _scrollToTop,
                backgroundColor: Colors.indigo[700],
                child: const Icon(Icons.arrow_upward, color: Colors.white),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            )
          : null,
    );
  }
}