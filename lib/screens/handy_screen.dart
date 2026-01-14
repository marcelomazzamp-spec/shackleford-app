import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/handy_service.dart';
import '../services/audio_service.dart';
import '../models/models.dart';
import '../utils/constants.dart';

class HandyScreen extends StatefulWidget {
  final Member? initialMember;
  
  const HandyScreen({super.key, this.initialMember});

  @override
  State<HandyScreen> createState() => _HandyScreenState();
}

class _HandyScreenState extends State<HandyScreen> with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  int _recordingDuration = 0;
  Timer? _durationTimer;
  
  String? _selectedGroupId;
  int? _selectedMemberId;
  
  List<HandyMessage> _messages = [];
  StreamSubscription? _messageSubscription;
  
  late AnimationController _pttController;
  late Animation<double> _pttScale;
  
  @override
  void initState() {
    super.initState();
    
    _pttController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _pttScale = Tween<double>(begin: 1.0, end: 0.95).animate(_pttController);
    
    if (widget.initialMember != null) {
      _selectedMemberId = widget.initialMember!.id;
    }
    
    _messageSubscription = HandyService.messageStream.listen((message) {
      setState(() {
        _messages.insert(0, message);
        if (_messages.length > 50) _messages.removeLast();
      });
    });
  }
  
  @override
  void dispose() {
    _durationTimer?.cancel();
    _messageSubscription?.cancel();
    _pttController.dispose();
    super.dispose();
  }
  
  Future<void> _startRecording() async {
    if (_isRecording) return;
    
    final hasPermission = await AudioService.hasPermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de micrófono requerido')),
      );
      return;
    }
    
    await AudioService.playChirpConnect();
    
    final started = await AudioService.startRecording();
    if (!started) return;
    
    setState(() {
      _isRecording = true;
      _recordingDuration = 0;
    });
    
    _pttController.forward();
    
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordingDuration++);
      if (_recordingDuration >= 60) _stopRecording();
    });
  }
  
  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    
    _durationTimer?.cancel();
    _pttController.reverse();
    
    final audio = await AudioService.stopRecording();
    setState(() => _isRecording = false);
    
    if (audio == null || audio.isEmpty) return;
    
    if (_selectedGroupId != null) {
      await HandyService.sendToGroup(_selectedGroupId!, audio, _recordingDuration);
    } else if (_selectedMemberId != null) {
      await HandyService.sendToMember(_selectedMemberId!, audio, _recordingDuration);
    } else {
      await HandyService.sendToGroup('familia', audio, _recordingDuration);
    }
    
    final provider = context.read<AppProvider>();
    setState(() {
      _messages.insert(0, HandyMessage(
        id: 0,
        fromMemberId: provider.currentMember!.id,
        fromName: provider.currentMember!.name,
        toMemberId: _selectedMemberId,
        groupId: _selectedGroupId ?? (_selectedMemberId == null ? 'familia' : null),
        messageType: 'audio',
        durationSeconds: _recordingDuration,
        createdAt: DateTime.now(),
      ));
    });
  }
  
  Future<void> _sendAlert(int memberId) async {
    await AudioService.playClick();
    await HandyService.sendAlert(memberId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alerta enviada'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HANDY'),
        actions: [
          StreamBuilder<ConnectionState>(
            stream: HandyService.stateStream,
            builder: (context, snapshot) {
              final connected = (snapshot.data ?? HandyService.state) == ConnectionState.connected;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: connected ? const Color(AppColors.success) : const Color(AppColors.danger),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(connected ? 'ONLINE' : 'OFFLINE',
                      style: TextStyle(fontSize: 12, color: connected ? const Color(AppColors.success) : const Color(AppColors.danger)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDestinationSelector(),
          const Divider(height: 1),
          Expanded(child: _buildHistory()),
          _buildPttSection(),
        ],
      ),
    );
  }
  
  Widget _buildDestinationSelector() {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final members = provider.otherMembers;
        return Container(
          padding: const EdgeInsets.all(16),
          color: const Color(AppColors.secondaryBlack),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GRUPOS', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildGroupChip('familia', '👨‍👩‍👦‍👦', 'Familia'),
                  const SizedBox(width: 8),
                  if (provider.isAdmin) _buildGroupChip('padres', '👫', 'Padres'),
                  if (!provider.isAdmin) _buildGroupChip('chicos', '👦👦', 'Chicos'),
                ],
              ),
              const SizedBox(height: 16),
              Text('INDIVIDUAL', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final isOnline = HandyService.isMemberOnline(member.id);
                    final isSelected = _selectedMemberId == member.id && _selectedGroupId == null;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() { _selectedMemberId = member.id; _selectedGroupId = null; });
                        AudioService.playClick();
                      },
                      onLongPress: () => _sendAlert(member.id),
                      child: Container(
                        width: 60,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(AppColors.accentRed).withOpacity(0.2) : const Color(AppColors.cardBlack),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(AppColors.accentRed) : const Color(AppColors.borderGray),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              children: [
                                Text(member.avatar, style: const TextStyle(fontSize: 24)),
                                if (isOnline)
                                  Positioned(
                                    right: -2, bottom: -2,
                                    child: Container(
                                      width: 10, height: 10,
                                      decoration: BoxDecoration(
                                        color: const Color(AppColors.success),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(AppColors.cardBlack), width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(member.name.split(' ')[0], style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildGroupChip(String id, String icon, String name) {
    final isSelected = _selectedGroupId == id;
    return GestureDetector(
      onTap: () {
        setState(() { _selectedGroupId = id; _selectedMemberId = null; });
        AudioService.playClick();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(AppColors.accentRed).withOpacity(0.2) : const Color(AppColors.cardBlack),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(AppColors.accentRed) : const Color(AppColors.borderGray),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(name),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHistory() {
    if (_messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.radio, size: 64, color: Color(AppColors.textMuted)),
            SizedBox(height: 16),
            Text('Sin mensajes', style: TextStyle(color: Color(AppColors.textMuted))),
            SizedBox(height: 8),
            Text('Mantené presionado el botón para hablar', style: TextStyle(color: Color(AppColors.textMuted), fontSize: 12)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final provider = context.read<AppProvider>();
        final isMe = message.fromMemberId == provider.currentMember?.id;
        return _buildMessageBubble(message, isMe);
      },
    );
  }
  
  Widget _buildMessageBubble(HandyMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? const Color(AppColors.accentRed).withOpacity(0.2) : const Color(AppColors.cardBlack),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isMe ? const Color(AppColors.accentRed).withOpacity(0.5) : const Color(AppColors.borderGray)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isMe ? 'Yo' : message.fromName, style: TextStyle(fontWeight: FontWeight.bold, color: isMe ? const Color(AppColors.accentRed) : const Color(AppColors.textPrimary))),
                if (message.isGroup) ...[
                  const SizedBox(width: 8),
                  Text('→ ${HandyGroups.getName(message.groupId!)}', style: const TextStyle(fontSize: 12, color: Color(AppColors.textMuted))),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    if (message.audioData != null) {
                      AudioService.playAudio(Uint8List.fromList(message.audioData!));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(AppColors.secondaryBlack), borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [const Icon(Icons.play_arrow, size: 20), const SizedBox(width: 8), Text(message.durationFormatted)]),
                  ),
                ),
                const SizedBox(width: 8),
                Text(_formatTime(message.createdAt), style: const TextStyle(fontSize: 11, color: Color(AppColors.textMuted))),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPttSection() {
    final provider = context.read<AppProvider>();
    final destinationText = _selectedGroupId != null
        ? HandyGroups.getName(_selectedGroupId!)
        : _selectedMemberId != null
            ? provider.getMember(_selectedMemberId!)?.name ?? 'Seleccionado'
            : 'Familia';
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(AppColors.secondaryBlack),
        border: Border(top: BorderSide(color: Color(AppColors.borderGray))),
      ),
      child: Column(
        children: [
          Text('ENVIANDO A: $destinationText', style: const TextStyle(fontSize: 12, color: Color(AppColors.textMuted), letterSpacing: 1)),
          const SizedBox(height: 16),
          if (_isRecording)
            Text('● REC ${_recordingDuration}s', style: const TextStyle(color: Color(AppColors.danger), fontWeight: FontWeight.bold, fontSize: 18)),
          if (!_isRecording)
            const Text('MANTENÉ PRESIONADO', style: TextStyle(color: Color(AppColors.textMuted), fontSize: 12)),
          const SizedBox(height: 16),
          GestureDetector(
            onTapDown: (_) => _startRecording(),
            onTapUp: (_) => _stopRecording(),
            onTapCancel: () => _stopRecording(),
            child: AnimatedBuilder(
              animation: _pttScale,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pttScale.value,
                  child: Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording ? const Color(AppColors.danger) : const Color(AppColors.accentRed),
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? const Color(AppColors.danger) : const Color(AppColors.accentRed)).withOpacity(0.4),
                          blurRadius: 20, spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(_isRecording ? Icons.mic : Icons.mic_none, size: 48, color: Colors.white),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(_isRecording ? 'Soltá para enviar' : 'PTT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _isRecording ? const Color(AppColors.danger) : const Color(AppColors.textPrimary))),
        ],
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} hs';
    return '${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
