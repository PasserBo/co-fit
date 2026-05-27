enum TemplateCardSessionStatus {
  started,
  paused,
  completed,
}

class TemplateCardSession {
  const TemplateCardSession({
    required this.templateId,
    required this.sessionId,
    required this.roomId,
    required this.userId,
    required this.status,
    required this.startedAt,
  });

  final String templateId;
  final String sessionId;
  final String roomId;
  final String userId;
  final TemplateCardSessionStatus status;
  final DateTime startedAt;

  TemplateCardSession copyWith({
    String? templateId,
    String? sessionId,
    String? roomId,
    String? userId,
    TemplateCardSessionStatus? status,
    DateTime? startedAt,
  }) {
    return TemplateCardSession(
      templateId: templateId ?? this.templateId,
      sessionId: sessionId ?? this.sessionId,
      roomId: roomId ?? this.roomId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
    );
  }
}
