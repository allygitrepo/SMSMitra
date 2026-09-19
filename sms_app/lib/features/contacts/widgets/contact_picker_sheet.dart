import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../data/models/contact_model.dart';
import '../../../data/services/contact_service.dart';

/// Modal bottom sheet widget supporting both Single-Select and Multi-Select
/// for device contacts with live search filtering, select all, and avatar initials.
class ContactPickerSheet extends StatefulWidget {
  final bool isMultiSelect;
  final void Function(DeviceContact contact)? onSingleSelected;
  final void Function(List<DeviceContact> contacts)? onMultiSelected;
  final Set<String>? initiallySelectedPhones;

  const ContactPickerSheet({
    super.key,
    this.isMultiSelect = false,
    this.onSingleSelected,
    this.onMultiSelected,
    this.initiallySelectedPhones,
  });

  /// Opens single-select contact picker bottom sheet
  static Future<DeviceContact?> showSingle(BuildContext context) async {
    DeviceContact? selected;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ContactPickerSheet(
        isMultiSelect: false,
        onSingleSelected: (c) {
          selected = c;
        },
      ),
    );
    return selected;
  }

  /// Opens multi-select contact picker bottom sheet
  static Future<List<DeviceContact>?> showMulti(
    BuildContext context, {
    Set<String>? initiallySelectedPhones,
  }) async {
    List<DeviceContact>? selectedList;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ContactPickerSheet(
        isMultiSelect: true,
        initiallySelectedPhones: initiallySelectedPhones,
        onMultiSelected: (list) {
          selectedList = list;
        },
      ),
    );
    return selectedList;
  }

  @override
  State<ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<ContactPickerSheet> {
  final ContactService _contactService = ContactService();
  final TextEditingController _searchController = TextEditingController();

  List<DeviceContact> _allContacts = [];
  List<DeviceContact> _filteredContacts = [];
  final Set<String> _selectedPhoneSet = {};
  bool _isLoading = true;
  String? _errorMessage;
  bool _isPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    if (widget.initiallySelectedPhones != null) {
      _selectedPhoneSet.addAll(widget.initiallySelectedPhones!);
    }
    _loadContacts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = List.from(_allContacts);
      } else {
        _filteredContacts = _allContacts.where((c) {
          final matchesName = c.name.toLowerCase().contains(query);
          final matchesPhone = c.phone.replaceAll(RegExp(r'[^0-9]'), '').contains(query);
          return matchesName || matchesPhone;
        }).toList();
      }
    });
  }

  Future<void> _loadContacts({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isPermissionDenied = false;
    });

    try {
      final contacts = await _contactService.getContacts(forceRefresh: forceRefresh);
      if (!mounted) return;

      setState(() {
        _allContacts = contacts;
        _filteredContacts = contacts;
        _isLoading = false;
      });
      _onSearchChanged();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      setState(() {
        _isLoading = false;
        _errorMessage = msg;
        _isPermissionDenied = msg.toLowerCase().contains('permission');
      });
    }
  }

  void _toggleContact(DeviceContact contact) {
    setState(() {
      if (_selectedPhoneSet.contains(contact.phone)) {
        _selectedPhoneSet.remove(contact.phone);
      } else {
        _selectedPhoneSet.add(contact.phone);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_isAllFilteredSelected) {
        // Deselect all filtered
        for (final c in _filteredContacts) {
          _selectedPhoneSet.remove(c.phone);
        }
      } else {
        // Select all filtered
        for (final c in _filteredContacts) {
          _selectedPhoneSet.add(c.phone);
        }
      }
    });
  }

  bool get _isAllFilteredSelected =>
      _filteredContacts.isNotEmpty &&
      _filteredContacts.every((c) => _selectedPhoneSet.contains(c.phone));

  void _handleDoneMultiSelect() {
    final selectedContacts = _allContacts
        .where((c) => _selectedPhoneSet.contains(c.phone))
        .toList();

    widget.onMultiSelected?.call(selectedContacts);
    Navigator.pop(context);
  }

  Color _getAvatarColor(String name) {
    const colors = [
      Colors.blue,
      Colors.purple,
      Colors.teal,
      Colors.orange,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
      Colors.deepOrange,
    ];
    final hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);

    return Material(
      color: theme.scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: mediaQuery.size.height * 0.88,
        child: Column(
          children: [
            // Drag Handle
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.contacts_rounded, color: colorScheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isMultiSelect ? 'Select Contacts' : 'Choose Contact',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.isMultiSelect
                              ? '${_selectedPhoneSet.length} selected of ${_allContacts.length}'
                              : '${_allContacts.length} contacts found',
                          style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh Contacts',
                    onPressed: () => _loadContacts(forceRefresh: true),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or mobile number...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                ),
              ),
            ),

            // Multi-Select Action Bar (Select All / Deselect All)
            if (widget.isMultiSelect && !_isLoading && _errorMessage == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: _filteredContacts.isEmpty ? null : _toggleSelectAll,
                      icon: Icon(
                        _isAllFilteredSelected
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        size: 18,
                      ),
                      label: Text(
                        _isAllFilteredSelected ? 'Deselect All' : 'Select All Filtered',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (_selectedPhoneSet.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(() => _selectedPhoneSet.clear()),
                        child: const Text(
                          'Clear Selection',
                          style: TextStyle(fontSize: 12.5, color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),

            const Divider(height: 16),

            // Body Content
            Expanded(
              child: _buildBody(theme, colorScheme),
            ),

            // Multi-Select Bottom Confirmation Button
            if (widget.isMultiSelect && !_isLoading && _errorMessage == null)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: ElevatedButton.icon(
                    onPressed: _selectedPhoneSet.isEmpty ? null : _handleDoneMultiSelect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.done_all_rounded),
                    label: Text(
                      _selectedPhoneSet.isEmpty
                          ? 'Select Contacts to Import'
                          : 'Import ${_selectedPhoneSet.length} Selected Contact(s)',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading contacts from device...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isPermissionDenied ? Icons.lock_outline_rounded : Icons.error_outline_rounded,
                size: 48,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                _isPermissionDenied ? 'Contacts Permission Required' : 'Failed to Load Contacts',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color),
              ),
              const SizedBox(height: 20),
              if (_isPermissionDenied)
                ElevatedButton.icon(
                  onPressed: () async {
                    await openAppSettings();
                  },
                  icon: const Icon(Icons.settings_rounded, size: 18),
                  label: const Text('Open App Settings'),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => _loadContacts(forceRefresh: true),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try Again'),
                ),
            ],
          ),
        ),
      );
    }

    if (_filteredContacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_search_rounded, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                _searchController.text.isNotEmpty
                    ? 'No contacts matching "${_searchController.text}"'
                    : 'No contacts found on device',
                style: TextStyle(fontSize: 14, color: theme.textTheme.bodySmall?.color),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      itemCount: _filteredContacts.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        final isSelected = _selectedPhoneSet.contains(contact.phone);
        final avatarColor = _getAvatarColor(contact.name);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          selected: isSelected,
          selectedTileColor: colorScheme.primary.withValues(alpha: 0.08),
          leading: CircleAvatar(
            backgroundColor: avatarColor.withValues(alpha: 0.18),
            foregroundColor: avatarColor,
            radius: 22,
            child: Text(
              contact.initials,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          title: Text(
            contact.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
          ),
          subtitle: Text(
            contact.phone,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          trailing: widget.isMultiSelect
              ? Checkbox(
                  value: isSelected,
                  activeColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (_) => _toggleContact(contact),
                )
              : Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey.withValues(alpha: 0.6),
                ),
          onTap: () {
            if (widget.isMultiSelect) {
              _toggleContact(contact);
            } else {
              widget.onSingleSelected?.call(contact);
              Navigator.pop(context, contact);
            }
          },
        );
      },
    );
  }
}
