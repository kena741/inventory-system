import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/supabase_utils.dart';

class RoleUsersView extends StatefulWidget {
  final String role;

  const RoleUsersView({super.key, required this.role});

  @override
  State<RoleUsersView> createState() => _RoleUsersViewState();
}

class _RoleUsersViewState extends State<RoleUsersView> {
  final _client = Supabase.instance.client;
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = true;
  String _error = '';
  List<Map<String, dynamic>> _users = const [];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _roleNormalized => widget.role.trim().toLowerCase();

  Future<void> _load() async {
    try {
      setState(() {
        _loading = true;
        _error = '';
      });

      final rows = await _client
          .from('users')
          .select('id, first_name, last_name, email, phone_number, role, created_at')
          .eq('role', _roleNormalized)
          .order('first_name', ascending: true);

      setState(() {
        _users = (rows as List).cast<Map<String, dynamic>>();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _users
        : _users.where((u) {
            final fn = (u['first_name']?.toString() ?? '').toLowerCase();
            final ln = (u['last_name']?.toString() ?? '').toLowerCase();
            final email = (u['email']?.toString() ?? '').toLowerCase();
            final phone = (u['phone_number']?.toString() ?? '').toLowerCase();
            return fn.contains(query) ||
                ln.contains(query) ||
                email.contains(query) ||
                phone.contains(query);
          }).toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('${_titleCase(_roleNormalized)}s'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_users_${widget.role}',
        onPressed: () async {
          final created = await _showCreateUserDialog(context);
          if (created == true) await _load();
        },
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Create'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search name, phone, email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        onPressed: () => _searchCtrl.clear(),
                        icon: const Icon(Icons.close),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SummaryPill(
              icon: Icons.group_outlined,
              label:
                  '${filtered.length} ${_titleCase(_roleNormalized)}${filtered.length == 1 ? '' : 's'}',
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 64),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error.isNotEmpty)
              _ErrorState(message: _error, onRetry: _load)
            else if (filtered.isEmpty)
              const _EmptyState(
                title: 'No users found',
                subtitle: 'Tap Create to add a new account.',
                icon: Icons.inbox_outlined,
              )
            else
              ...[
                for (final u in filtered) ...[
                  _UserCard(user: u),
                  const SizedBox(height: 10),
                ],
              ],
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showCreateUserDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _CreateUserDialog(role: _roleNormalized);
      },
    );
  }
}

class _CreateUserDialog extends StatefulWidget {
  final String role;

  const _CreateUserDialog({required this.role});

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Email is required';
    if (!s.contains('@') || !s.contains('.')) return 'Enter a valid email';
    return null;
  }

  String? _validateRequired(String? v, String label) {
    if ((v ?? '').trim().isEmpty) return '$label is required';
    return null;
  }

  String? _validatePassword(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Password is required';
    if (s.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await SupabaseUtils.createUserWithProfileKeepingSession(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        role: widget.role,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('Create ${_titleCase(widget.role)}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _firstNameCtrl,
                decoration: const InputDecoration(labelText: 'First name'),
                textInputAction: TextInputAction.next,
                validator: (v) => _validateRequired(v, 'First name'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _lastNameCtrl,
                decoration: const InputDecoration(labelText: 'Last name'),
                textInputAction: TextInputAction.next,
                validator: (v) => _validateRequired(v, 'Last name'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (v) => _validateRequired(v, 'Phone'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: _validateEmail,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: _validatePassword,
                onFieldSubmitted: (_) => _onSave(),
              ),
              const SizedBox(height: 4),
              Text(
                'All fields are required.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _onSave,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fn = (user['first_name']?.toString() ?? '').trim();
    final ln = (user['last_name']?.toString() ?? '').trim();
    final name = [fn, ln].where((e) => e.isNotEmpty).join(' ').trim();
    final email = (user['email']?.toString() ?? '').trim();
    final phone = (user['phone_number']?.toString() ?? '').trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.10),
            child: Icon(Icons.person_outline, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Unnamed' : name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.70),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (phone.isNotEmpty)
                  Text(
                    phone,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 32, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

String _titleCase(String v) {
  final s = v.trim();
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}

