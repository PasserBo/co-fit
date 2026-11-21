// 会话循环改写自 a2ui_flutter 官方 v1.0 example 的 ChatSession
// (Apache-2.0, Google LLC):
// https://github.com/a2ui-project/a2ui/tree/main/dart/a2ui_flutter/example
// 改动:CoFit 教练指令 + 运动记录上下文;可选推理格式;每一步写 CoachSessionLog。

import 'dart:async';
import 'dart:convert';

import 'package:a2ui_agent/a2ui_agent.dart';
import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_flutter/basic_catalog.dart';
import 'package:flutter/foundation.dart';

import '../domain/coach_model_client.dart';
import '../domain/coach_session_log.dart';

/// 教练指令(在运动记录上下文与 A2UI prompt 片段之前)。
const String coachInstructions = '''
You are the beta "AI coach" inside CoFit, a social fitness app where friends
work out together in a shared virtual gym and start an exercise by playing an
"action card". You answer questions about the user's own workout records, given
below. Reply in the user's language (usually Simplified Chinese). Keep text to a
sentence or two and put plans, summaries, lists, forms and choices in A2UI
surfaces. Base every number on the records; never invent workouts. You cannot
change any data in the app (you cannot create cards, decks or records), so do
not offer buttons that pretend to.

- Give each new surface a new surfaceId, and set "sendDataModel": true on a
  surface with inputs.
- Bind each input to a data model path. Give a submit button an event action
  whose context reads those paths.
- When the user acts on a surface, the next user turn is JSON whose "a2ui"
  holds the renderer's v1.0 messages, {"messages": [...]}. A message is an
  action, with its name and resolved context, or an error the renderer met.
- Once a surface is created with sendDataModel, a user turn carries
  "metadata": {"a2uiRendererDataModel": ...}, which holds the data model of each
  such surface: beside "a2ui" in the JSON of an action or error turn, or as
  JSON after the text of a typed turn.
- Answer an action by updating its surface, or with a new surface. Answer an
  error by correcting the surface it names.
''';

/// 模型被要求使用的 A2UI 推理格式。
enum CoachFormat {
  /// `<a2ui-json>` 内的 JSON,边流式边渲染(默认)。
  json,

  /// 紧凑的 Express DSL,整段回答结束后才编译渲染。
  express;

  InferenceFormatFactory get factory => switch (this) {
    json => const DirectJsonFormatFactory(progressiveKeys: {'text', 'label'}),
    express => const ExpressFormatFactory(),
  };

  static CoachFormat parse(String value) =>
      value == express.name ? express : json;
}

enum CoachEntryKind { user, model, surface, sent, error }

/// 对话中显示的一条。
class CoachEntry {
  CoachEntry(this.kind, this.text) : surface = null;

  CoachEntry.surface(SurfaceModel<ComponentImplementation> this.surface)
    : kind = CoachEntryKind.surface,
      text = '';

  final CoachEntryKind kind;

  /// 模型文本在流式过程中会增长。
  String text;

  final SurfaceModel<ComponentImplementation>? surface;
}

/// 一次教练会话:模型用文字与 A2UI 卡片回答,卡片上的操作与渲染错误作为下一轮发回。
/// 每一步写入 [log]。页面销毁时 [dispose],对话即清空(规格:对话不保存)。
class CoachChatController extends ChangeNotifier {
  CoachChatController({
    required this.client,
    required this.log,
    required String recordsContext,
    required int recordCount,
    this.format = CoachFormat.json,
  }) : _agent =
           A2uiGenerator(
             catalogs: [CatalogConfig(_catalog)],
             inferenceFormatFactory: format.factory,
           ).createProcessor(
             A2uiRendererCapabilities.forCatalogIds([
               BasicCatalog.v1_0Id,
             ], version: A2uiProtocolVersion.v1_0),
           ) {
    systemPrompt =
        '$coachInstructions\n$recordsContext\n${_agent.promptSnippet}';
    processor = MessageProcessor(
      catalogs: [_catalog],
      defaultVersion: A2uiProtocolVersion.v1_0,
      validationConfig: ValidationConfig.relaxed,
      outboundListener: _sendOutbound,
      unifiedOutbound: true,
    );
    processor.model.onSurfaceCreated.subscribe(_addSurface);
    processor.model.onSurfaceDeleted.subscribe(_removeSurface);
    log.write('session_start', {
      'model': client.name,
      'format': format.name,
      'protocol': _version,
      'catalog': BasicCatalog.v1_0Id,
      'packages': packageVersions,
      'records': recordCount,
    });
    log.write('system_prompt', {
      'chars': systemPrompt.length,
      'text': systemPrompt,
    });
  }

  /// 与 pubspec.lock 一致;升级时同步(日志里用于区分不同版本的试用结果)。
  static const Map<String, String> packageVersions = {
    'a2ui_flutter': '0.4.0',
    'a2ui_core': '0.8.0',
    'a2ui_agent': '0.4.0',
  };

  /// 只用协议自带的基础组件;不传 openUrl,模型生成的链接不会被打开。
  static final CatalogImplementation _catalog = basicCatalog();

  static final String _version = A2uiProtocolVersion.v1_0.jsonValue;

  /// 连续回给模型的错误轮数上限(用户下一次发言前)。
  static const int maxErrorTurns = 2;

  final CoachModelClient client;
  final CoachSessionLog log;
  final CoachFormat format;

  late final String systemPrompt;
  late final MessageProcessor<ComponentImplementation> processor;

  final A2uiRequestProcessor _agent;
  late final RendererState _state = _agent.createState();

  final List<CoachEntry> entries = [];
  final List<CoachTurn> _turns = [];
  Future<void> _queue = Future.value();
  int _queued = 0;
  StreamIterator<String>? _reading;
  bool _disposed = false;

  int _turnIndex = -1;
  final Stopwatch _turnClock = Stopwatch();
  int? _firstA2uiMs;
  int _a2uiMessages = 0;
  int _textChars = 0;

  /// 是否有一轮在等待或读取回答。
  bool get busy => _queued > 0;

  /// 是否已有用户发言(决定「导出日志」是否有意义)。
  bool get hasTurns => _turnIndex >= 0;

  /// 发送用户发言;[preset] 只影响日志里的 kind。
  Future<void> send(String text, {bool preset = false}) {
    entries.add(CoachEntry(CoachEntryKind.user, text));
    _errorTurns = 0;
    return _enqueue(() {
      final Map<String, Object?> metadata = _metadata();
      return _runTurn(
        metadata.isEmpty ? text : '$text\n\n${jsonEncode(metadata)}',
        kind: preset ? 'preset' : 'typed',
      );
    });
  }

  Future<void> _enqueue(Future<void> Function() turn) {
    if (_disposed) {
      return Future.value();
    }
    _queued++;
    _notify();
    return _queue = _queue
        .then((_) => turn())
        .catchError((Object error) {
          log.write('turn_failed', {'error': '$error'});
          _addEntry(CoachEntryKind.error, '这一轮失败了:$error');
        })
        .whenComplete(() {
          _queued--;
          _notify();
        });
  }

  CoachEntry? _modelText;

  Future<void> _runTurn(String userTurn, {required String kind}) async {
    if (_disposed) {
      return;
    }
    final int turn = ++_turnIndex;
    _turns.add((fromUser: true, text: userTurn));
    _reported.clear();
    _firstA2uiMs = null;
    _a2uiMessages = 0;
    _textChars = 0;
    log.write('user_turn', {
      'turn': turn,
      'kind': kind,
      'chars': userTurn.length,
      'text': userTurn,
    });
    ResponseStream? stream = _agent.openStream(state: _state);
    final reply = StringBuffer();
    var complete = true;
    var chunkIndex = 0;
    int? ttfbMs;
    String? failure;
    _modelText = null;
    _turnClock
      ..reset()
      ..start();
    final StreamIterator<String> chunks = _reading = StreamIterator(
      client.generate(systemPrompt, List.of(_turns)),
    );
    try {
      while (await chunks.moveNext()) {
        if (_disposed) {
          break;
        }
        final int dt = _turnClock.elapsedMilliseconds;
        ttfbMs ??= dt;
        log.write('model_chunk', {
          'turn': turn,
          'i': chunkIndex++,
          'dt_ms': dt,
          'text': chunks.current,
        });
        reply.write(chunks.current);
        stream = _read(stream, (s) => s.feed(chunks.current));
        _notify();
      }
    } on Object catch (error) {
      complete = false;
      failure = '$error';
      entries.add(CoachEntry(CoachEntryKind.error, '请求失败:$error'));
    }
    _reading = null;
    if (_disposed) {
      return;
    }
    if (complete) {
      _read(stream, (s) => s.close());
    } else {
      try {
        stream?.close();
      } on Object catch (_) {}
    }
    _turnClock.stop();
    log.write('model_reply', {
      'turn': turn,
      'ok': complete,
      'error': ?failure,
      'ttfb_ms': ttfbMs,
      'first_a2ui_ms': _firstA2uiMs,
      'total_ms': _turnClock.elapsedMilliseconds,
      'chunks': chunkIndex,
      'chars': reply.length,
      'text_chars': _textChars,
      'a2ui_messages': _a2uiMessages,
      'text': '$reply',
    });
    if (reply.isEmpty) {
      _turns.removeLast();
      if (complete) {
        entries.add(CoachEntry(CoachEntryKind.error, '教练没有回答,请再问一次。'));
      }
    } else {
      _turns.add((fromUser: false, text: '$reply'));
    }
  }

  ResponseStream? _read(
    ResponseStream? stream,
    List<ResponsePart> Function(ResponseStream stream) read,
  ) {
    if (stream == null) {
      return null;
    }
    try {
      for (final ResponsePart part in read(stream)) {
        switch (part) {
          case TextPart(:final String text):
            _textChars += text.length;
            _showText(text);
          case A2uiPart(:final List<AgentToRendererMessage> a2ui):
            a2ui.forEach(_process);
        }
      }
      return stream;
    } on Object catch (error) {
      log.write('stream_rejected', {
        'turn': _turnIndex,
        'type': error.runtimeType.toString(),
        'error': '$error',
      });
      _reportFailure(error, '');
      return null;
    }
  }

  void _showText(String text) {
    (_modelText ??= _addEntry(CoachEntryKind.model)).text += text;
  }

  void _process(AgentToRendererMessage message) {
    _modelText = null;
    _firstA2uiMs ??= _turnClock.elapsedMilliseconds;
    _a2uiMessages++;
    final String surfaceId = _surfaceIdOf(message);
    log.write('a2ui_message', {
      'turn': _turnIndex,
      'type': message.runtimeType.toString(),
      'surface': surfaceId,
      'dt_ms': _turnClock.elapsedMilliseconds,
      'message': message.toJson(),
    });
    try {
      processor.processMessages(AgentToRendererMessagePayload.of(message));
    } on Object catch (error) {
      log.write('processor_rejected', {
        'turn': _turnIndex,
        'surface': surfaceId,
        'code': error is A2uiError ? error.code : null,
        'error': '$error',
      });
      _reportFailure(error, surfaceId);
    }
  }

  static String _surfaceIdOf(AgentToRendererMessage message) =>
      switch (message) {
        CreateSurfaceMessage(:final String surfaceId) ||
        UpdateComponentsMessage(:final String surfaceId) ||
        UpdateDataModelMessage(:final String surfaceId) ||
        DeleteSurfaceMessage(:final String surfaceId) => surfaceId,
        _ => '',
      };

  CoachEntry _addEntry(CoachEntryKind kind, [String text = '']) {
    final entry = CoachEntry(kind, text);
    entries.add(entry);
    return entry;
  }

  void _addSurface(SurfaceModel<ComponentImplementation> surface) {
    log.write('surface_created', {
      'turn': _turnIndex,
      'surface': surface.id,
      'metadata': ?surface.metadata,
    });
    surface.onError.subscribe(_report);
    entries.add(CoachEntry.surface(surface));
    _modelText = null;
    _notify();
  }

  void _removeSurface(String surfaceId) {
    log.write('surface_deleted', {'turn': _turnIndex, 'surface': surfaceId});
    entries.removeWhere((entry) => entry.surface?.id == surfaceId);
    _notify();
  }

  /// [processor] 发往 agent 的消息:action 等作为下一轮发言;ErrorMessage 丢弃
  /// (processor 同时会抛出该错误,由 [_reportFailure] 处理)。
  void _sendOutbound(RendererToAgentMessage message) {
    log.write('outbound', {
      'type': message.runtimeType.toString(),
      'message': message.toJson(),
    });
    if (message is ErrorMessage) {
      return;
    }
    _errorTurns = 0;
    final String turn = _clientTurn([message]);
    unawaited(_enqueue(() => _runTurn(turn, kind: 'action')));
  }

  String _clientTurn(List<RendererToAgentMessage> messages) {
    final String turn = jsonEncode({
      'a2ui': RendererToAgentMessagePayload(messages).toJson(),
      ..._metadata(),
    });
    _addEntry(
      CoachEntryKind.sent,
      [
        for (final RendererToAgentMessage message in messages)
          switch (message) {
            ActionMessage(:final A2uiRendererAction action) =>
              'action ${action.name}',
            ErrorMessage(:final A2uiRendererError error) =>
              'error ${error.code}',
            CallAgentFunctionMessage(:final String functionCallId) =>
              'function call $functionCallId',
            _ => message.runtimeType.toString(),
          },
      ].join(', '),
    );
    return turn;
  }

  Map<String, Object?> _metadata() {
    final Map<String, dynamic>? dataModel = processor.getRendererDataModel();
    return {
      if (dataModel != null) 'metadata': {'a2uiRendererDataModel': dataModel},
    };
  }

  final Set<String> _reported = {};
  final List<A2uiRendererError> _unsent = [];
  int _errorTurns = 0;

  void _reportFailure(Object error, String surfaceId) {
    final A2uiError failure = error is A2uiError ? error : A2uiError('$error');
    final String? path = failure is A2uiValidationError ? failure.path : null;
    final bool pathless =
        failure.code == A2uiRendererError.validationFailedCode &&
        (path == null || path.isEmpty);
    _report(
      A2uiRendererError(
        code: pathless ? 'UNKNOWN_ERROR' : failure.code,
        surfaceId: surfaceId,
        message: failure.message,
        path: pathless ? null : path,
      ),
    );
  }

  void _report(A2uiRendererError error) {
    if (!_reported.add(jsonEncode(error))) {
      return;
    }
    log.write('renderer_error', {
      'turn': _turnIndex,
      'code': error.code,
      'surface': error.surfaceId,
      'path': error.path,
      'message': error.message,
    });
    _addEntry(CoachEntryKind.error, '卡片显示出错(${error.code})');
    _modelText = null;
    _unsent.add(error);
    _notify();
    unawaited(_enqueue(_sendErrors));
  }

  Future<void> _sendErrors() async {
    if (_disposed || _unsent.isEmpty) {
      return;
    }
    final List<RendererToAgentMessage> errors = [
      for (final A2uiRendererError error in _unsent)
        ErrorMessage(version: _version, error: error),
    ];
    _unsent.clear();
    if (_errorTurns >= maxErrorTurns) {
      log.write('errors_dropped', {'count': errors.length});
      return;
    }
    _errorTurns++;
    await _runTurn(_clientTurn(errors), kind: 'error');
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    log.write('session_end', {'turns': _turnIndex + 1});
    unawaited(_reading?.cancel());
    unawaited(log.close());
    processor.dispose();
    _state.dispose();
    super.dispose();
  }
}
