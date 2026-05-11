import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin_remote_datasource.dart';
import '../admin_controller.dart';

const _adminRed = Color(0xFFE53935);
const _adminOrange = Color(0xFFFF6F00);
const _adminBg = Color(0xFF0F0F0F);
const _adminSurface = Color(0xFF1C1C1E);
const _adminCard = Color(0xFF252528);

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  Map<String, dynamic>? _stats;
  bool _statsLoading = false;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminControllerProvider.notifier).loadDashboard();
      _loadStats();
    });
  }

  Future<void> _loadStats() async {
    setState(() => _statsLoading = true);
    try {
      final data = await ref.read(adminRemoteDatasourceProvider).getStats();
      setState(() {
        _stats = data;
        _statsLoading = false;
      });
    } catch (e) {
      setState(() => _statsLoading = false);
    }
  }

  void _logout() {
    ref.read(adminControllerProvider.notifier).logout();
    context.go('/admin');
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_adminRed.withValues(alpha: 0.9), _adminOrange],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.shield, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Betooth Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                onPressed: _logout,
                tooltip: 'Sair',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavTabs() {
    final tabs = [
      (Icons.dashboard_outlined, 'Dashboard'),
      (Icons.people_outline, 'Usuários'),
      (Icons.music_note_outlined, 'Músicas'),
      (Icons.flag_outlined, 'Denúncias'),
    ];

    return Container(
      color: _adminSurface,
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final i = entry.key;
          final (icon, label) = entry.value;
          final selected = _selectedTab == i;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected ? _adminRed : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        color: selected ? _adminRed : Colors.white54, size: 20),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        color: selected ? _adminRed : Colors.white54,
                        fontSize: 10,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminControllerProvider);
    final dashboard = adminState.dashboard;

    return Scaffold(
      backgroundColor: _adminBg,
      body: Column(
        children: [
          _buildHeader(),
          _buildNavTabs(),
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _DashboardTab(dashboard: dashboard, stats: _stats, statsLoading: _statsLoading),
                const AdminUsersTab(),
                const AdminTracksTab(),
                const AdminReportsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard tab
// ---------------------------------------------------------------------------

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({this.dashboard, this.stats, this.statsLoading = false});

  final Map<String, dynamic>? dashboard;
  final Map<String, dynamic>? stats;
  final bool statsLoading;

  @override
  Widget build(BuildContext context) {
    if (dashboard == null) {
      return const Center(
        child: CircularProgressIndicator(color: _adminRed),
      );
    }

    return RefreshIndicator(
      color: _adminRed,
      onRefresh: () async {},
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Visão geral',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _StatCard(
                  icon: Icons.people,
                  label: 'Usuários',
                  value: '${dashboard?['totalUsers'] ?? 0}',
                  color: Colors.blue,
                ),
                _StatCard(
                  icon: Icons.music_note,
                  label: 'Músicas',
                  value: '${dashboard?['totalTracks'] ?? 0}',
                  color: Colors.purple,
                ),
                _StatCard(
                  icon: Icons.cloud_upload,
                  label: 'Uploads hoje',
                  value: '${dashboard?['uploadsToday'] ?? 0}',
                  color: Colors.teal,
                ),
                _StatCard(
                  icon: Icons.public,
                  label: 'Públicas',
                  value: '${dashboard?['publicTracks'] ?? 0}',
                  color: Colors.green,
                ),
                _StatCard(
                  icon: Icons.lock_outline,
                  label: 'Privadas',
                  value: '${dashboard?['privateTracks'] ?? 0}',
                  color: Colors.orange,
                ),
                _StatCard(
                  icon: Icons.person_pin,
                  label: 'Ativos (7d)',
                  value: '${dashboard?['activeUsers7d'] ?? 0}',
                  color: Colors.cyan,
                ),
                _StatCard(
                  icon: Icons.flag,
                  label: 'Denúncias',
                  value: '${dashboard?['pendingReports'] ?? 0}',
                  color: _adminRed,
                ),
                _StatCard(
                  icon: Icons.pending,
                  label: 'Uploads pend.',
                  value: '${dashboard?['pendingUploads'] ?? 0}',
                  color: Colors.amber,
                ),
              ],
            ),
            if (stats != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Top artistas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...(stats!['topArtists'] as List? ?? []).take(5).map((a) {
                final artist = a as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _adminCard,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Colors.white54, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${artist['name']}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${artist['trackCount']} músicas',
                          style: const TextStyle(color: Colors.purple, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _adminCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Users tab
// ---------------------------------------------------------------------------

class AdminUsersTab extends ConsumerStatefulWidget {
  const AdminUsersTab({super.key});

  @override
  ConsumerState<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<AdminUsersTab> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = false;
  String _search = '';
  String? _statusFilter;
  int _page = 1;
  bool _hasMore = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final p = refresh ? 1 : _page;
      final data = await ref.read(adminRemoteDatasourceProvider).getUsers(
            page: p,
            search: _search,
            status: _statusFilter,
          );
      final list = (data['users'] as List?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [];
      final pagination = data['pagination'] as Map<String, dynamic>?;
      setState(() {
        _users = refresh ? list : [..._users, ...list];
        _page = p + 1;
        _hasMore = pagination?['hasMore'] as bool? ?? false;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _blockUser(String id) async {
    try {
      await ref.read(adminRemoteDatasourceProvider).blockUser(id);
      _load(refresh: true);
    } catch (e) {
      _showError('$e');
    }
  }

  Future<void> _unblockUser(String id) async {
    try {
      await ref.read(adminRemoteDatasourceProvider).unblockUser(id);
      _load(refresh: true);
    } catch (e) {
      _showError('$e');
    }
  }

  Future<void> _deleteUser(String id) async {
    final confirmed = await _confirm('Excluir usuário?');
    if (!confirmed) return;
    try {
      await ref.read(adminRemoteDatasourceProvider).deleteUser(id);
      _load(refresh: true);
    } catch (e) {
      _showError('$e');
    }
  }

  Future<bool> _confirm(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: _adminCard,
            title: Text(message, style: const TextStyle(color: Colors.white)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: _adminRed),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: _adminRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar usuários...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    filled: true,
                    fillColor: _adminSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (v) {
                    _search = v;
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (_search == v) _load(refresh: true);
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Todos',
                selected: _statusFilter == null,
                onTap: () {
                  setState(() => _statusFilter = null);
                  _load(refresh: true);
                },
              ),
              const SizedBox(width: 4),
              _FilterChip(
                label: 'Suspensos',
                selected: _statusFilter == 'SUSPENDED',
                onTap: () {
                  setState(() => _statusFilter = 'SUSPENDED');
                  _load(refresh: true);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading && _users.isEmpty
              ? const Center(child: CircularProgressIndicator(color: _adminRed))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _users.length + (_hasMore ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i == _users.length) {
                      return Center(
                        child: TextButton(
                          onPressed: () => _load(),
                          child: const Text('Carregar mais'),
                        ),
                      );
                    }
                    final user = _users[i];
                    final isSuspended = user['status'] == 'SUSPENDED';
                    final isDeleted = user['status'] == 'DELETED';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _adminCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: _adminRed.withValues(alpha: 0.2),
                            child: Text(
                              '${user['displayName']}'
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(color: _adminRed),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${user['displayName']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${user['email']}',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                                _StatusBadge(status: '${user['status']}'),
                              ],
                            ),
                          ),
                          if (!isDeleted)
                            PopupMenuButton<String>(
                              color: _adminCard,
                              icon: const Icon(Icons.more_vert, color: Colors.white54),
                              onSelected: (v) {
                                if (v == 'block') _blockUser('${user['id']}');
                                if (v == 'unblock') _unblockUser('${user['id']}');
                                if (v == 'delete') _deleteUser('${user['id']}');
                              },
                              itemBuilder: (_) => [
                                if (!isSuspended)
                                  const PopupMenuItem(
                                    value: 'block',
                                    child: Text(
                                      'Bloquear',
                                      style: TextStyle(color: Colors.orange),
                                    ),
                                  ),
                                if (isSuspended)
                                  const PopupMenuItem(
                                    value: 'unblock',
                                    child: Text(
                                      'Desbloquear',
                                      style: TextStyle(color: Colors.green),
                                    ),
                                  ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    'Excluir',
                                    style: TextStyle(color: _adminRed),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tracks tab
// ---------------------------------------------------------------------------

class AdminTracksTab extends ConsumerStatefulWidget {
  const AdminTracksTab({super.key});

  @override
  ConsumerState<AdminTracksTab> createState() => _AdminTracksTabState();
}

class _AdminTracksTabState extends ConsumerState<AdminTracksTab> {
  List<Map<String, dynamic>> _tracks = [];
  bool _loading = false;
  String? _privacyFilter;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final data = await ref.read(adminRemoteDatasourceProvider).getTracks(
            privacy: _privacyFilter,
            status: _statusFilter,
          );
      final list = (data['tracks'] as List?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [];
      setState(() {
        _tracks = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _blockTrack(String id) async {
    try {
      await ref.read(adminRemoteDatasourceProvider).blockTrack(id);
      _load(refresh: true);
    } catch (e) {
      _showError('$e');
    }
  }

  Future<void> _deleteTrack(String id) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: _adminCard,
            title: const Text('Excluir música?', style: TextStyle(color: Colors.white)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: _adminRed),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await ref.read(adminRemoteDatasourceProvider).deleteTrack(id);
      _load(refresh: true);
    } catch (e) {
      _showError('$e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: _adminRed));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 6,
            children: [
              _FilterChip(
                label: 'Todos',
                selected: _privacyFilter == null,
                onTap: () {
                  setState(() => _privacyFilter = null);
                  _load(refresh: true);
                },
              ),
              _FilterChip(
                label: 'Públicos',
                selected: _privacyFilter == 'public',
                onTap: () {
                  setState(() => _privacyFilter = 'public');
                  _load(refresh: true);
                },
              ),
              _FilterChip(
                label: 'Privados',
                selected: _privacyFilter == 'private',
                onTap: () {
                  setState(() => _privacyFilter = 'private');
                  _load(refresh: true);
                },
              ),
              _FilterChip(
                label: 'Bloqueados',
                selected: _statusFilter == 'BLOCKED',
                onTap: () {
                  setState(() {
                    _statusFilter = _statusFilter == 'BLOCKED' ? null : 'BLOCKED';
                    _privacyFilter = null;
                  });
                  _load(refresh: true);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading && _tracks.isEmpty
              ? const Center(child: CircularProgressIndicator(color: _adminRed))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _tracks.length,
                  itemBuilder: (ctx, i) {
                    final track = _tracks[i];
                    final artist = track['artist'] as Map<String, dynamic>?;
                    final isBlocked = track['status'] == 'BLOCKED';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _adminCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.music_note, color: Colors.purple, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${track['title']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${artist?['name'] ?? 'Artista desconhecido'}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                                _StatusBadge(status: '${track['status']}'),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            color: _adminCard,
                            icon: const Icon(Icons.more_vert, color: Colors.white54),
                            onSelected: (v) {
                              if (v == 'block') _blockTrack('${track['id']}');
                              if (v == 'delete') _deleteTrack('${track['id']}');
                            },
                            itemBuilder: (_) => [
                              if (!isBlocked)
                                const PopupMenuItem(
                                  value: 'block',
                                  child: Text('Bloquear', style: TextStyle(color: Colors.orange)),
                                ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Excluir', style: TextStyle(color: _adminRed)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Reports tab
// ---------------------------------------------------------------------------

class AdminReportsTab extends ConsumerStatefulWidget {
  const AdminReportsTab({super.key});

  @override
  ConsumerState<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends ConsumerState<AdminReportsTab> {
  List<Map<String, dynamic>> _reports = [];
  bool _loading = false;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ref.read(adminRemoteDatasourceProvider).getReports(status: _statusFilter);
      final list =
          (data['reports'] as List?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
      setState(() {
        _reports = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _resolveReport(String id) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _adminCard,
        title: const Text('Resolver denúncia', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Motivo (opcional)',
            labelStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Resolver'),
          ),
        ],
      ),
    );
    if (result == null) return;
    try {
      await ref.read(adminRemoteDatasourceProvider).resolveReport(
            id,
            status: 'RESOLVED',
            reason: result.isNotEmpty ? result : null,
          );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: _adminRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _FilterChip(
                label: 'Abertas',
                selected: _statusFilter == 'OPEN',
                onTap: () {
                  setState(() => _statusFilter = _statusFilter == 'OPEN' ? null : 'OPEN');
                  _load();
                },
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Resolvidas',
                selected: _statusFilter == 'RESOLVED',
                onTap: () {
                  setState(() =>
                      _statusFilter = _statusFilter == 'RESOLVED' ? null : 'RESOLVED');
                  _load();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading && _reports.isEmpty
              ? const Center(child: CircularProgressIndicator(color: _adminRed))
              : _reports.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhuma denúncia',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _reports.length,
                      itemBuilder: (ctx, i) {
                        final report = _reports[i];
                        final reporter = report['reporter'] as Map<String, dynamic>?;
                        final track = report['track'] as Map<String, dynamic>?;
                        final isOpen = report['status'] == 'OPEN';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _adminCard,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.flag,
                                    color: isOpen ? _adminRed : Colors.green,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${report['reason']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  _StatusBadge(status: '${report['status']}'),
                                ],
                              ),
                              if (track != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Música: ${track['title']}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                              if (reporter != null) ...[
                                Text(
                                  'Por: ${reporter['displayName']}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                              if (report['message'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${report['message']}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (isOpen) ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _resolveReport('${report['id']}'),
                                    icon: const Icon(Icons.check, size: 14),
                                    label: const Text('Resolver'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  Color _color() {
    return switch (status) {
      'ACTIVE' || 'PUBLISHED' => Colors.green,
      'SUSPENDED' || 'BLOCKED' => Colors.orange,
      'DELETED' || 'ARCHIVED' => Colors.red,
      'PENDING' || 'PROCESSING' => Colors.blue,
      'RESOLVED' => Colors.green,
      'OPEN' => _adminRed,
      _ => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      margin: const EdgeInsets.only(top: 3),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? _adminRed : _adminSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white54,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
