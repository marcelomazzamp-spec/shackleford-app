import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/constants.dart';

// ============ MEMBER AVATAR ============

class MemberAvatar extends StatelessWidget {
  final Member member;
  final MemberLocation? location;
  final bool isOnline;
  final VoidCallback? onTap;
  
  const MemberAvatar({
    super.key,
    required this.member,
    this.location,
    this.isOnline = false,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(AppColors.cardBlack),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isOnline 
                        ? const Color(AppColors.success)
                        : const Color(AppColors.borderGray),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    member.avatar,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isOnline 
                        ? const Color(AppColors.success)
                        : const Color(AppColors.textMuted),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(AppColors.primaryBlack),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            member.name.split(' ')[0],
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
          if (location != null) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.battery_std, size: 12, color: Color(AppColors.textMuted)),
                const SizedBox(width: 2),
                Text(
                  '${location!.batteryLevel ?? '?'}%',
                  style: const TextStyle(fontSize: 10, color: Color(AppColors.textMuted)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ============ PTT BUTTON FLOTANTE ============

class PttButton extends StatefulWidget {
  const PttButton({super.key});
  
  @override
  State<PttButton> createState() => _PttButtonState();
}

class _PttButtonState extends State<PttButton> {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.large(
      backgroundColor: const Color(AppColors.accentRed),
      onPressed: () => Navigator.pushNamed(context, AppRoutes.handy),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.radio, size: 32, color: Colors.white),
          Text('PTT', style: TextStyle(fontSize: 10, color: Colors.white)),
        ],
      ),
    );
  }
}

// ============ MINI MAP ============

class MiniMap extends StatelessWidget {
  const MiniMap({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(AppColors.cardBlack),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(AppColors.borderGray)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Placeholder del mapa
            Container(
              color: const Color(0xFF1a2634),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: Color(AppColors.textMuted)),
                    SizedBox(height: 8),
                    Text('Mapa', style: TextStyle(color: Color(AppColors.textMuted))),
                  ],
                ),
              ),
            ),
            // Botón para expandir
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(AppColors.secondaryBlack),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.fullscreen, size: 20),
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.map),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ EVENT CARD ============

class EventCard extends StatelessWidget {
  final AppEvent event;
  
  const EventCard({super.key, required this.event});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: event.isCritical 
            ? const Color(AppColors.danger).withOpacity(0.1)
            : const Color(AppColors.cardBlack),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: event.isCritical
              ? const Color(AppColors.danger).withOpacity(0.5)
              : const Color(AppColors.borderGray),
        ),
      ),
      child: Row(
        children: [
          Text(event.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: event.isCritical 
                        ? const Color(AppColors.danger)
                        : const Color(AppColors.textPrimary),
                  ),
                ),
                if (event.memberName != null)
                  Text(
                    event.memberName!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            _formatEventTime(event.createdAt),
            style: const TextStyle(
              fontSize: 11,
              color: Color(AppColors.textMuted),
            ),
          ),
          if (!event.isRead)
            Container(
              margin: const EdgeInsets.only(left: 8),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(AppColors.accentRed),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
  
  String _formatEventTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${time.day}/${time.month}';
  }
}
