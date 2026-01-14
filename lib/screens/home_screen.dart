import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/handy_service.dart';
import '../utils/constants.dart';
import '../widgets/member_avatar.dart';
import '../widgets/ptt_button.dart';
import '../widgets/mini_map.dart';
import '../widgets/event_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    // Escuchar alertas
    HandyService.alertStream.listen((alert) {
      if (alert['type'] == 'panic') {
        _showPanicDialog(alert);
      }
    });
  }

  void _showPanicDialog(Map<String, dynamic> alert) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(AppColors.danger),
        title: const Row(
          children: [
            Text('🆘', style: TextStyle(fontSize: 32)),
            SizedBox(width: 12),
            Text('EMERGENCIA', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          '${alert['memberName']} activó el botón de pánico',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Ir al mapa con la ubicación
              Navigator.pushNamed(context, AppRoutes.map);
            },
            child: const Text(
              'VER UBICACIÓN',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 32),
            const SizedBox(width: 10),
            const Text('SHACKLEFORD'),
          ],
        ),
        actions: [
          // Badge de notificaciones
          Consumer<AppProvider>(
            builder: (context, provider, _) {
              final count = provider.unreadCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.events),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(AppColors.danger),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          count > 9 ? '9+' : count.toString(),
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Estado de conexión
          StreamBuilder<ConnectionState>(
            stream: HandyService.stateStream,
            builder: (context, snapshot) {
              final state = snapshot.data ?? HandyService.state;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  state == ConnectionState.connected
                      ? Icons.wifi
                      : Icons.wifi_off,
                  color: state == ConnectionState.connected
                      ? const Color(AppColors.success)
                      : const Color(AppColors.danger),
                  size: 20,
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AppProvider>().refreshData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Miembros
              _buildMembersSection(),
              const SizedBox(height: 20),

              // Mapa mini (solo admins)
              Consumer<AppProvider>(
                builder: (context, provider, _) {
                  if (!provider.isAdmin) return const SizedBox.shrink();
                  return Column(
                    children: [
                      _buildSectionHeader('Ubicaciones', onTap: () {
                        Navigator.pushNamed(context, AppRoutes.map);
                      }),
                      const SizedBox(height: 12),
                      const MiniMap(),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),

              // Eventos recientes
              _buildSectionHeader('Eventos Recientes', onTap: () {
                Navigator.pushNamed(context, AppRoutes.events);
              }),
              const SizedBox(height: 12),
              _buildEventsSection(),
            ],
          ),
        ),
      ),

      // Botón PTT flotante
      floatingActionButton: const PttButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      // Bottom navigation
      bottomNavigationBar: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);
              switch (index) {
                case 0:
                  break; // Ya estamos en home
                case 1:
                  Navigator.pushNamed(context, AppRoutes.handy);
                  break;
                case 2:
                  if (provider.isAdmin) {
                    Navigator.pushNamed(context, AppRoutes.map);
                  }
                  break;
                case 3:
                  Navigator.pushNamed(context, AppRoutes.settings);
                  break;
              }
            },
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Inicio',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.radio_outlined),
                activeIcon: Icon(Icons.radio),
                label: 'Handy',
              ),
              if (provider.isAdmin)
                const BottomNavigationBarItem(
                  icon: Icon(Icons.map_outlined),
                  activeIcon: Icon(Icons.map),
                  label: 'Mapa',
                ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Config',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (onTap != null)
          TextButton(
            onPressed: onTap,
            child: const Text('Ver todo →'),
          ),
      ],
    );
  }

  Widget _buildMembersSection() {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final members = provider.members;
        if (members.isEmpty) {
          return const Center(child: Text('Cargando miembros...'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Familia',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  final location = provider.getMemberLocation(member.id);
                  final isOnline = HandyService.isMemberOnline(member.id);

                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: MemberAvatar(
                      member: member,
                      location: location,
                      isOnline: isOnline,
                      onTap: () {
                        // Abrir handy directo con este miembro
                        Navigator.pushNamed(
                          context,
                          AppRoutes.handy,
                          arguments: member,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEventsSection() {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final events = provider.events.take(5).toList();
        if (events.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(AppColors.secondaryBlack),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(AppColors.borderGray)),
            ),
            child: const Center(
              child: Text('Sin eventos recientes'),
            ),
          );
        }

        return Column(
          children: events.map((event) => EventCard(event: event)).toList(),
        );
      },
    );
  }
}
