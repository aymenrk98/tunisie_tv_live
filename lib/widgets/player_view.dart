import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme.dart';

class PlayerView extends StatefulWidget {
  final String url;

  const PlayerView({super.key, required this.url});

  @override
  State<PlayerView> createState() => PlayerViewState();
}

class PlayerViewState extends State<PlayerView> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = _buildController(widget.url);
  }

  @override
  void didUpdateWidget(covariant PlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      setState(() {
        _loading = true;
        _error = null;
      });
      _controller.loadRequest(
        Uri.parse(widget.url),
        headers: const {'Referer': 'https://www.elahmad.ru/'},
      );
    }
  }

  void reload() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _controller.reload();
  }

  static const _mobileUserAgent =
      'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';

  // Ad scripts on the source page try to hijack the view with a full-page
  // redirect to a different domain (fake "play button" overlays, etc.).
  // Only the source's own host is ever a legitimate top-level navigation —
  // the actual video is fetched as a sub-resource (not a navigation), so
  // blocking everything else stops the ad redirects without breaking playback.
  static const _allowedHost = 'www.elahmad.ru';

  WebViewController _buildController(String url) {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(_mobileUserAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final host = Uri.tryParse(request.url)?.host;
            return host == _allowedHost
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
          onPageFinished: (_) {
            // The source page's own ad script relies on window.open() to
            // pop a new tab/window for its ad. Neutering it is safe: it
            // does not touch the page's separate anti-adblock probe, so it
            // won't trigger the "please disable your ad-blocker" lockout.
            //
            // Separately: the browser's Fullscreen API renders the
            // fullscreened element in an isolated top layer, excluding any
            // sibling ad overlay the page injected elsewhere in the DOM —
            // this is why manually tapping the page's own "enlarge" button
            // makes ads disappear. Fullscreen can only be requested from a
            // real user gesture, so we can't trigger it on load — instead we
            // arm a one-shot listener that fires it on the viewer's first
            // tap anywhere on the player, piggybacking on that gesture.
            _controller.runJavaScript('''
              window.open = function(){ return null; };
              (function() {
                function goFullscreen() {
                  var el = document.getElementById('player');
                  if (!el) return;
                  var req = el.requestFullscreen || el.webkitRequestFullscreen ||
                            el.webkitRequestFullScreen || el.mozRequestFullScreen ||
                            el.msRequestFullscreen;
                  if (req) { try { req.call(el); } catch (e) {} }
                }
                document.addEventListener('click', goFullscreen, {capture: true, once: true});
                document.addEventListener('touchend', goFullscreen, {capture: true, once: true});
              })();
            ''');
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            // Ignore failures from sub-resources (ads, trackers, embedded
            // iframes) — only a failure of the top-level page should be
            // reported as the channel being unavailable.
            if (error.isForMainFrame == false) return;
            if (mounted) {
              setState(() {
                _loading = false;
                _error = 'Chaîne indisponible pour le moment.';
              });
            }
          },
        ),
      )
      ..loadRequest(
        Uri.parse(url),
        headers: const {'Referer': 'https://www.elahmad.ru/'},
      );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              WebViewWidget(controller: _controller),
              if (_loading || _error != null)
                Container(
                  color: AppColors.bg,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_error == null) ...[
                        const SizedBox(
                          width: 34,
                          height: 34,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppColors.tnRedLight,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Chargement de la chaîne…',
                          style: TextStyle(color: AppColors.textDim, fontSize: 13),
                        ),
                      ] else
                        Text(
                          _error!,
                          style: const TextStyle(color: AppColors.textDim, fontSize: 13),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
