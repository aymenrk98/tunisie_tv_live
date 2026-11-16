import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/channel.dart';
import '../theme.dart';

/// A compact single-line row for a channel — logo, name, category, favorite.
class ChannelCard extends StatelessWidget {
  final Channel channel;
  final bool isActive;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const ChannelCard({
    super.key,
    required this.channel,
    required this.isActive,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isActive ? AppColors.surface2 : AppColors.surface,
          border: Border.all(
            color: isActive ? AppColors.tnRedLight.withValues(alpha: 0.6) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            _ChannelLogo(channel: channel, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                channel.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            if (isActive)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.play_circle_fill_rounded, color: AppColors.tnRedLight, size: 20),
              ),
            IconButton(
              onPressed: onToggleFavorite,
              icon: Icon(
                isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                color: isFavorite ? AppColors.gold : AppColors.textDim,
                size: 20,
              ),
              visualDensity: VisualDensity.compact,
              splashRadius: 18,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the channel's real logo asset on a white rounded tile when one is
/// available, falling back to the gradient initials badge otherwise (or if
/// the asset fails to decode).
class _ChannelLogo extends StatelessWidget {
  final Channel channel;
  final double size;

  const _ChannelLogo({required this.channel, this.size = 52});

  @override
  Widget build(BuildContext context) {
    final asset = channel.logoAsset;
    if (asset == null) return _initialsBadge();

    final image = asset.endsWith('.svg')
        ? SvgPicture.asset(
            asset,
            fit: BoxFit.contain,
            placeholderBuilder: (_) => _initialsBadge(),
          )
        : Image.asset(
            asset,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => _initialsBadge(),
          );

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.27),
        color: Colors.white,
      ),
      child: image,
    );
  }

  Widget _initialsBadge() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.27),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: channel.colors,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        channel.logo,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.29,
        ),
      ),
    );
  }
}
