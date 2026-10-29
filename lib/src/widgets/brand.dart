import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';
import 'package:url_launcher/url_launcher.dart';

const wingsCrewHomeUrl = 'https://wingscrew.com/';

final Uri wingsCrewHomeUri = Uri.parse(wingsCrewHomeUrl);

/// Opens the WingsCrew site. On the web this is a new tab.
Future<void> openWingsCrewHome() {
  return launchUrl(
    wingsCrewHomeUri,
    mode: LaunchMode.externalApplication,
    webOnlyWindowName: '_blank',
  );
}

/// A tappable WingsCrew mark. The accessible name is "WingsCrew home".
class WingsCrewHomeLink extends StatelessWidget {
  const WingsCrewHomeLink({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      label: 'WingsCrew home',
      child: Link(
        uri: wingsCrewHomeUri,
        target: LinkTarget.blank,
        builder: (context, followLink) {
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: followLink,
              child: ExcludeSemantics(child: child),
            ),
          );
        },
      ),
    );
  }
}

/// Small credit shown at the top of the app.
class ByWingsCrewCredit extends StatelessWidget {
  const ByWingsCrewCredit({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(12, 2, 12, 0),
      child: Align(
        alignment: Alignment.center,
        child: WingsCrewHomeLink(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image(
                image: AssetImage('assets/brand/logo.png'),
                height: 28,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 6),
              Text(
                'by WingsCrew',
                style: TextStyle(
                  color: Color(0xFFFFF6EA),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  shadows: [Shadow(color: Color(0xAA000000), blurRadius: 6)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MoreFromWingsCrewButton extends StatelessWidget {
  const MoreFromWingsCrewButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Link(
      uri: wingsCrewHomeUri,
      target: LinkTarget.blank,
      builder: (context, followLink) {
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: followLink,
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('More from WingsCrew'),
          ),
        );
      },
    );
  }
}

/// Renders [text] unchanged, with each "WingsCrew" opening the site.
class WingsCrewText extends StatefulWidget {
  const WingsCrewText(this.text, {super.key, this.style, this.textAlign});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  State<WingsCrewText> createState() => _WingsCrewTextState();
}

class _WingsCrewTextState extends State<WingsCrewText> {
  late final TapGestureRecognizer _recognizer = TapGestureRecognizer()..onTap = openWingsCrewHome;

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const word = 'WingsCrew';
    final pieces = widget.text.split(word);
    return Text.rich(
      TextSpan(
        style: widget.style,
        children: [
          for (var i = 0; i < pieces.length; i++) ...[
            if (pieces[i].isNotEmpty) TextSpan(text: pieces[i]),
            if (i != pieces.length - 1)
              TextSpan(
                text: word,
                style: const TextStyle(decoration: TextDecoration.underline),
                recognizer: _recognizer,
                mouseCursor: SystemMouseCursors.click,
              ),
          ],
        ],
      ),
      textAlign: widget.textAlign ?? TextAlign.start,
    );
  }
}
