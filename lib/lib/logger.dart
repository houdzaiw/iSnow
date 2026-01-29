import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

class CustomExtendedLoggerFormatter implements LoggerFormatter {
  const CustomExtendedLoggerFormatter();

  @override
  String fmt(LogDetails details, TalkerLoggerSettings settings) {
    final underline = ConsoleUtils.getUnderline(
      settings.maxLineWidth,
      lineSymbol: settings.lineSymbol,
      withCorner: true,
    );
    final topLine = ConsoleUtils.getTopline(
      settings.maxLineWidth,
      lineSymbol: settings.lineSymbol,
      withCorner: true,
    );
    final msg = details.message?.toString() ?? '';
    final msgBorderedLines = msg.split('\n').map((e) => '│ $e');
    if (!settings.enableColors) {
      return '\n$topLine\n${msgBorderedLines.join('\n')}\n$underline';
    }
    var lines = [topLine, ...msgBorderedLines, underline];
    lines = lines.map((e) => details.pen.write(e)).toList();
    final coloredMsg = lines.join('\n');
    return coloredMsg;
  }
}

class Logger {
  static final Logger _instance = Logger._internal();

  factory Logger() => _instance;

  Logger._internal() {
    _talker = TalkerFlutter.init(
      settings: TalkerSettings(colors: {
        // TalkerLogType.debug.toString(): AnsiPen()..blue(),

      }),
      logger: TalkerLogger(
          formatter: const CustomExtendedLoggerFormatter(),
          settings: TalkerLoggerSettings(enableColors: Platform.isAndroid)),
    );
  }

  static Talker get talker => _instance._talker;

  late final Talker _talker;

  static void infoWrite(
    dynamic msg, [
    Object? exception,
    StackTrace? stackTrace,
  ]) {
    String fileName = _getTraceMethod(StackTrace.current);
    String strMsg = "$fileName\n ${msg.toString()}";
    _instance._talker.debug(strMsg, exception, stackTrace);
    // NadyLogger.infoLog(
    //     'msg:$msg\nexception:${exception.toString()}\n${stackTrace.toString()}',
    //     name: 'nady',
    //     tag: 'undefined');
  }

  static void logByType(String logType, dynamic msg, [
    Object? exception,
    StackTrace? stackTrace,
  ]) {
    if(logType == "debug") {
      Logger.debug(msg, exception, stackTrace);
    } else if(logType == "info") {
      Logger.info(msg, exception, stackTrace);
    } else if(logType == "critical") {
      Logger.critical(msg, exception, stackTrace);
    } else if(logType == "error") {
      Logger.error(msg, exception, stackTrace);
    } else if(logType == "warning") {
      Logger.warning(msg, exception, stackTrace);
    } else if(logType == "verbose") {
      Logger.verbose(msg, exception, stackTrace);
    } else {
      Logger.info(msg, exception, stackTrace);
    }
  }

  static void debug(
    dynamic msg, [
    Object? exception,
    StackTrace? stackTrace,
  ]) {
    String fileName = _getTraceMethod(StackTrace.current);
    String strMsg = "$fileName\n ${msg.toString()}";
    _instance._talker.debug(strMsg, exception, stackTrace);
  }

  static void info(
    dynamic msg, [
    Object? exception,
    StackTrace? stackTrace,
  ]) {
    String fileName = _getTraceMethod(StackTrace.current);
    String strMsg = "$fileName\n ${msg.toString()}";
    _instance._talker.info(strMsg, exception, stackTrace);
  }

  static void critical(
    dynamic msg, [
    Object? exception,
    StackTrace? stackTrace,
  ]) {
    String fileName = _getTraceMethod(StackTrace.current);
    String strMsg = "$fileName\n ${msg.toString()}";
    _instance._talker.critical(strMsg, exception, stackTrace);
  }

  static void error(
    dynamic msg, [
    Object? exception,
    StackTrace? stackTrace,
  ]) {
    String fileName = _getTraceMethod(StackTrace.current);
    String strMsg = "$fileName\n ${msg.toString()}";
    _instance._talker.error(strMsg, exception, stackTrace);
    // NadyLogger.errorLog(
    //     'msg:$msg\nexception:${exception.toString()}\n${stackTrace.toString()}',
    //     name: 'nady',
    //     tag: 'error');
  }

  static void warning(
    dynamic msg, [
    Object? exception,
    StackTrace? stackTrace,
  ]) {
    String fileName = _getTraceMethod(StackTrace.current);
    String strMsg = "$fileName\n ${msg.toString()}";
    _instance._talker.warning(strMsg, exception, stackTrace);
    // NadyLogger.warnLog(
    //     'msg:$msg\nexception:${exception.toString()}\n${stackTrace.toString()}',
    //     name: 'nady',
    //     tag: 'undefined');
  }

  static void verbose(
    dynamic msg, [
    Object? exception,
    StackTrace? stackTrace,
  ]) {
    String fileName = _getTraceMethod(StackTrace.current);
    String strMsg = "$fileName\n ${msg.toString()}";
    _instance._talker.verbose(strMsg, exception, stackTrace);
  }

  static void handle(
    Object exception, [
    StackTrace? stackTrace,
    dynamic msg,
  ]) =>
      _instance._talker.handle(exception, stackTrace, msg);

  static String _getTraceMethod(StackTrace trace) {
    var frames = trace
        .toString()
        .split("\n")
        .where((element) => element.contains(".dart"))
        .toList();
    String fileName = "";
    if (frames.length >= 2) {
      String frame = frames[1];
      var parts = frame.split(" ");
      if (parts.isNotEmpty) parts.removeAt(0);
      fileName = parts.join(" ".trim());
    }
    return fileName;
  }
}

class ProviderLoggerObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (provider.name != "roomCapturedAudioProvider" &&
        provider.name != "micPositionProvider" &&
        provider.name != "luckyBagListProvider" &&
        provider.name != "nadyRoomPendantControllerProvider" &&
        provider.name != "gameInfoStateProvider" &&
        provider.name != "miningGameRecordListControllerProvider"
    ) {
      Logger.info(
          'provider: ${provider.name ?? provider.runtimeType} didUpdateProvider, previousValue: $previousValue, newValue: $newValue');
    }
  }

  @override
  void didDisposeProvider(
      ProviderBase<Object?> provider, ProviderContainer container) {
    Logger.info(
        'provider: ${provider.name ?? provider.runtimeType} argument : ${provider.argument} didDisposeProvider');
  }

  @override
  void didAddProvider(ProviderBase<Object?> provider, Object? value,
      ProviderContainer container) {
    Logger.info(
        'provider: ${provider.name ?? provider.runtimeType} argument : ${provider.argument} didAddProvider, value: $value');
  }

  @override
  void providerDidFail(ProviderBase<Object?> provider, Object error,
      StackTrace stackTrace, ProviderContainer container) {
    Logger.error(
        'provider: ${provider.name ?? provider.runtimeType} providerDidFail',
        error,
        stackTrace);
  }
}
