import 'package:flutter/material.dart';
import '../services/authen_service/auth_controller.dart';

class SessionInfoWidget extends StatefulWidget {
  final bool showSessionDuration;
  final bool showAsCard;
  final Color? backgroundColor;
  final EdgeInsets? padding;

  const SessionInfoWidget({
    super.key,
    this.showSessionDuration = true,
    this.showAsCard = true,
    this.backgroundColor,
    this.padding,
  });

  @override
  State<SessionInfoWidget> createState() => _SessionInfoWidgetState();
}

class _SessionInfoWidgetState extends State<SessionInfoWidget> {
  final AuthController _authController = AuthController();
  late String _currentUser;

  @override
  void initState() {
    super.initState();
    _updateSessionInfo();
    // Update session duration every minute
    _startSessionTimer();
  }

  void _updateSessionInfo() {
    setState(() {
      _currentUser = _authController.getCurrentUser() ?? 'Unknown';
    });
  }

  void _startSessionTimer() {
    Future.delayed(const Duration(minutes: 1), () {
      if (mounted && _authController.isLoggedIn()) {
        _updateSessionInfo();
        _startSessionTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_authController.isLoggedIn()) {
      return const SizedBox.shrink();
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(
              Icons.account_circle,
              size: 20,
              color: Colors.deepPurple,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Welcome to map, $_currentUser',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        if (widget.showSessionDuration) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 16,
                color: Color.fromARGB(255, 168, 16, 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Session: ${_authController.getSessionInfo().split('Session: ')[1]}',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ],
      ],
    );

    if (widget.showAsCard) {
      return Card(
        color: widget.backgroundColor ?? Colors.white,
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: widget.padding ?? const EdgeInsets.all(12),
          child: content,
        ),
      );
    }

    return Padding(padding: widget.padding ?? EdgeInsets.zero, child: content);
  }
}

// Simple text widget showing just the username
class WelcomeUserWidget extends StatelessWidget {
  final AuthController _authController = AuthController();

  WelcomeUserWidget({super.key});

  @override
  Widget build(BuildContext context) {
    if (!_authController.isLoggedIn()) {
      return const SizedBox.shrink();
    }

    final username = _authController.getCurrentUser();

    return Text(
      'Hi, $username!',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}
