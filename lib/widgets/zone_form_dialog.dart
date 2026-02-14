import 'package:flutter/material.dart';
import '../models/warehouse_data.dart';

/// Dialog for adding or editing a zone with X, Y, Width(m), Height(m)
class ZoneFormDialog extends StatefulWidget {
  final StorageZone? existingZone; // null = add new
  final WarehouseFloor floor;
  final double? tapX; // pre-fill from map tap
  final double? tapY;

  const ZoneFormDialog({
    super.key,
    this.existingZone,
    required this.floor,
    this.tapX,
    this.tapY,
  });

  @override
  State<ZoneFormDialog> createState() => _ZoneFormDialogState();
}

class _ZoneFormDialogState extends State<ZoneFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelCtrl;
  late TextEditingController _sectionCtrl;
  late TextEditingController _xCtrl;
  late TextEditingController _yCtrl;
  late TextEditingController _widthCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _occupancyCtrl;
  late TextEditingController _descCtrl;
  late ZoneType _selectedType;
  late ZoneStatus _selectedStatus;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final z = widget.existingZone;
    _labelCtrl = TextEditingController(text: z?.label ?? '');
    _sectionCtrl = TextEditingController(text: z?.section ?? '');
    _xCtrl = TextEditingController(
        text: z != null ? z.x.toStringAsFixed(1) : (widget.tapX?.toStringAsFixed(1) ?? '0.0'));
    _yCtrl = TextEditingController(
        text: z != null ? z.y.toStringAsFixed(1) : (widget.tapY?.toStringAsFixed(1) ?? '0.0'));
    _widthCtrl = TextEditingController(text: z != null ? z.widthM.toStringAsFixed(1) : '2.0');
    _heightCtrl = TextEditingController(text: z != null ? z.heightM.toStringAsFixed(1) : '2.0');
    _occupancyCtrl = TextEditingController(
        text: z != null ? (z.occupancyRate * 100).toStringAsFixed(0) : '0');
    _descCtrl = TextEditingController(text: z?.description ?? '');
    _selectedType = z?.type ?? ZoneType.floorStorage;
    _selectedStatus = z?.status ?? ZoneStatus.empty;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _sectionCtrl.dispose();
    _xCtrl.dispose();
    _yCtrl.dispose();
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _occupancyCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  double get _area =>
      (double.tryParse(_widthCtrl.text) ?? 0) * (double.tryParse(_heightCtrl.text) ?? 0);

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingZone != null;
    final theme = Theme.of(context);

    final screenW = MediaQuery.of(context).size.width;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: screenW < 520 ? screenW - 40 : 480,
        constraints: const BoxConstraints(maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(isEditing ? Icons.edit_location_alt : Icons.add_location_alt,
                      color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Modifier la Zone' : 'Ajouter une Zone',
                    style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label + Section
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildField('Nom / Label', _labelCtrl, Icons.label,
                                validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField('Section', _sectionCtrl, Icons.category),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Position header
                      _sectionHeader('Position (mètres)'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildNumberField('X (m)', _xCtrl, Icons.swap_horiz)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildNumberField('Y (m)', _yCtrl, Icons.swap_vert)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Dimensions header
                      _sectionHeader('Dimensions (m²)'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildNumberField('Largeur (m)', _widthCtrl, Icons.width_normal)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildNumberField('Hauteur (m)', _heightCtrl, Icons.height)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Area display
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF90CAF9)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.square_foot, color: Color(0xFF1565C0), size: 20),
                            const SizedBox(width: 8),
                            Text('Surface: ', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                            Text(
                              '${_area.toStringAsFixed(1)} m²',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Type & Status
                      _sectionHeader('Type & Statut'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<ZoneType>(
                              value: _selectedType,
                              isExpanded: true,
                              decoration: _inputDeco('Type', Icons.warehouse),
                              items: ZoneType.values.map((t) => DropdownMenuItem(
                                value: t, child: Text('${t.icon} ${t.label}', style: const TextStyle(fontSize: 13)),
                              )).toList(),
                              onChanged: (v) => setState(() => _selectedType = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<ZoneStatus>(
                              value: _selectedStatus,
                              isExpanded: true,
                              decoration: _inputDeco('Statut', Icons.info_outline),
                              items: ZoneStatus.values.map((s) => DropdownMenuItem(
                                value: s,
                                child: Row(
                                  children: [
                                    Container(width: 10, height: 10,
                                      decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                                    const SizedBox(width: 6),
                                    Text(s.label, style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              )).toList(),
                              onChanged: (v) => setState(() => _selectedStatus = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Occupancy
                      _buildNumberField('Taux d\'occupation (%)', _occupancyCtrl, Icons.battery_std),
                      const SizedBox(height: 16),

                      // Description
                      _buildField('Description (optionnel)', _descCtrl, Icons.description,
                          maxLines: 2),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_errorMessage!,
                                  style: TextStyle(color: Colors.red.shade700, fontSize: 12))),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  if (isEditing)
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context, 'DELETE'),
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                      label: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: Icon(isEditing ? Icons.save : Icons.add, size: 18),
                    label: Text(isEditing ? 'Enregistrer' : 'Ajouter'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title, style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF455A64)));
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon,
      {String? Function(String?)? validator, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      decoration: _inputDeco(label, icon),
      validator: validator,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildNumberField(String label, TextEditingController ctrl, IconData icon) {
    return TextFormField(
      controller: ctrl,
      decoration: _inputDeco(label, icon),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Requis';
        if (double.tryParse(v) == null) return 'Nombre invalide';
        return null;
      },
      onChanged: (_) => setState(() {}),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final x = double.parse(_xCtrl.text);
    final y = double.parse(_yCtrl.text);
    final w = double.parse(_widthCtrl.text);
    final h = double.parse(_heightCtrl.text);
    final occ = (double.tryParse(_occupancyCtrl.text) ?? 0).clamp(0, 100) / 100.0;

    // Validate boundaries
    if (!widget.floor.fitsInFloor(x, y, w, h)) {
      setState(() => _errorMessage =
          'La zone dépasse les limites de l\'étage (${widget.floor.totalWidthM}m × ${widget.floor.totalHeightM}m)');
      return;
    }

    // Check overlaps
    if (widget.floor.hasOverlap(x, y, w, h, excludeId: widget.existingZone?.id)) {
      setState(() => _errorMessage = 'Cette zone chevauche une zone existante !');
      return;
    }

    final zone = StorageZone(
      id: widget.existingZone?.id,
      label: _labelCtrl.text,
      section: _sectionCtrl.text,
      x: x,
      y: y,
      widthM: w,
      heightM: h,
      type: _selectedType,
      status: _selectedStatus,
      occupancyRate: occ,
      description: _descCtrl.text.isNotEmpty ? _descCtrl.text : '',
      createdAt: widget.existingZone?.createdAt,
    );

    Navigator.pop(context, zone);
  }
}
