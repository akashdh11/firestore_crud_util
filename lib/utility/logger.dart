import 'package:logger/logger.dart';

var logger = Logger();
var loggerNoStack =
    Logger(printer: PrettyPrinter(methodCount: 0, printEmojis: false));
