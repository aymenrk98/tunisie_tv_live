import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/channels.dart';
import '../models/channel.dart';
import '../theme.dart';
import '../widgets/channel_card.dart';
import '../widgets/player_view.dart';

const _kFavoritesKey = 'tntv:favorites';
const _kLastChannelKey = 'tntv:lastChannel';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<PlayerViewState> _playerKey = GlobalKey<PlayerViewState>();
  String _query = '';
  Channel _activeChannel = kChannels.first;
  final Set<String> _favorites = {};
  SharedPreferences? _prefs;
  late Timer _clockTimer;
  String _clockText = '--:--:--';

  @override
  void initState() {
    super.initState();
    _tickClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tickClock());
    _loadPrefs();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  void _tickClock() {
    // Tunisia is fixed at UTC+1 year-round (no DST).
    final tn = DateTime.now().toUtc().add(const Duration(hours: 1));
    final h = tn.hour.toString().padLeft(2, '0');
    final m = tn.minute.toString().padLeft(2, '0');
    final s = tn.second.toString().padLeft(2, '0');
    if (mounted) setState(() => _clockText = '$h:$m:$s');
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final storedFavorites = prefs.getStringList(_kFavoritesKey) ?? [];
    final lastChannelId = prefs.getString(_kLastChannelKey);
    final startChannel = kChannels.firstWhere(
      (c) => c.id == lastChannelId,
      orElse: () => kChannels.first,
    );
    setState(() {
      _prefs = prefs;
      _favorites.addAll(storedFavorites);
      _activeChannel = startChannel;
    });
  }

  void _playChannel(Channel channel) {
    setState(() => _activeChannel = channel);
    _prefs?.setString(_kLastChannelKey, channel.id);
  }

  void _toggleFavorite(String channelId) {
    setState(() {
      if (_favorites.contains(channelId)) {
        _favorites.remove(channelId);
      } else {
        _favorites.add(channelId);
      }
    });
    _prefs?.setStringList(_kFavoritesKey, _favorites.toList());
  }

  List<Channel> get _filteredChannels {
    final q = _query.trim().toLowerCase();
    final list = kChannels.where((c) {
      return q.isEmpty || c.name.toLowerCase().contains(q);
    }).toList();
    list.sort((a, b) {
      final favA = _favorites.contains(a.id) ? 0 : 1;
      final favB = _favorites.contains(b.id) ? 0 : 1;
      return favA.compareTo(favB);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredChannels;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.open_in_full_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'لتفادي الإعلانات، اضغط مرة واحدة على الشاشة لتكبيرها',
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PlayerView(key: _playerKey, url: _activeChannel.embedUrl),
                  const SizedBox(height: 14),
                  _buildNowPlaying(),
                  const SizedBox(height: 8),
                  const Text(
                    "Si l'image ne s'affiche pas, réessayez dans quelques secondes.",
                    style: TextStyle(color: AppColors.textDim, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'Aucune chaîne ne correspond à votre recherche.',
                          style: TextStyle(color: AppColors.textDim, fontSize: 14),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      itemCount: filtered.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        if (i == filtered.length) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Text(
                              "Flux fournis par des sources publiques tierces (elahmad.ru). "
                              "Tunisie TV Live n'héberge aucun contenu vidéo.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textDim, fontSize: 11, height: 1.4),
                            ),
                          );
                        }
                        final ch = filtered[i];
                        return ChannelCard(
                          channel: ch,
                          isActive: ch.id == _activeChannel.id,
                          isFavorite: _favorites.contains(ch.id),
                          onTap: () => _playChannel(ch),
                          onToggleFavorite: () => _toggleFavorite(ch.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/branding/app_logo.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text),
                        children: [
                          TextSpan(text: 'Tunisie TV '),
                          TextSpan(text: 'Live', style: TextStyle(color: AppColors.tnRedLight)),
                        ],
                      ),
                    ),
                    const Text(
                      'Chaînes tunisiennes en direct',
                      style: TextStyle(color: AppColors.textDim, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _clockText,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 12,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 18, color: AppColors.textDim),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    style: const TextStyle(color: AppColors.text, fontSize: 14),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Rechercher une chaîne…',
                      hintStyle: TextStyle(color: AppColors.textDim),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNowPlaying() {
    final isFav = _favorites.contains(_activeChannel.id);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.tnRed.withValues(alpha: 0.15),
            border: Border.all(color: AppColors.tnRed.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LiveDot(),
              SizedBox(width: 6),
              Text(
                'DIRECT',
                style: TextStyle(
                  color: AppColors.tnRedLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _activeChannel.name,
            style: const TextStyle(color: AppColors.text, fontSize: 17, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          onPressed: () => _playerKey.currentState?.reload(),
          icon: const Icon(Icons.refresh_rounded, color: AppColors.text),
          tooltip: 'Recharger',
        ),
        IconButton(
          onPressed: () => _toggleFavorite(_activeChannel.id),
          icon: Icon(
            isFav ? Icons.star_rounded : Icons.star_border_rounded,
            color: isFav ? AppColors.gold : AppColors.text,
          ),
        ),
      ],
    );
  }

}

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.35).animate(_controller),
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(color: AppColors.tnRed, shape: BoxShape.circle),
      ),
    );
  }
}
