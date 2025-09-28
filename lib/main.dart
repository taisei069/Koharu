import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart'; // Google Fontsをインポート

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '小春や珈琲労働時間計算アプリ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // アプリ全体のフォントをNoto Sans JPに設定
        textTheme: GoogleFonts.notoSansJpTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const WorkTimeCalculatorPage(),
    );
  }
}

class WorkTimeCalculatorPage extends StatefulWidget {
  const WorkTimeCalculatorPage({super.key});

  @override
  _WorkTimeCalculatorPageState createState() => _WorkTimeCalculatorPageState();
}

class _WorkTimeCalculatorPageState extends State<WorkTimeCalculatorPage> {
  // フォーカス管理のためのFocusNode
  final _checkInFocusNode = FocusNode();
  final _checkOutFocusNode = FocusNode();
  final _breakFocusNode = FocusNode();

  // 入力値のコントローラー
  final TextEditingController _checkInController = TextEditingController();
  final TextEditingController _checkOutController = TextEditingController();
  final TextEditingController _breakController = TextEditingController();

  String _workTimeResult = "労働時間：0時間0分";
  String _decimalTimeResult = "労働時間：0.00時間";

  @override
  void initState() {
    super.initState();
    _checkInController.addListener(() {
      _handleTimeInput(_checkInController, _checkOutFocusNode);
    });
    _checkOutController.addListener(() {
      _handleTimeInput(_checkOutController, _breakFocusNode);
    });
    _breakController.addListener(() {
      _calculateWorkTime();
    });
  }

  @override
  void dispose() {
    _checkInFocusNode.dispose();
    _checkOutFocusNode.dispose();
    _breakFocusNode.dispose();
    _checkInController.dispose();
    _checkOutController.dispose();
    _breakController.dispose();
    super.dispose();
  }

  // 時間入力のフォーマットとフォーカス移動を処理
  void _handleTimeInput(TextEditingController controller, FocusNode nextFocusNode) {
    String text = controller.text;

    if (text.length == 2 && !text.contains(':')) {
      final String formattedText = '$text:';
      controller.value = controller.value.copyWith(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length),
      );
    }
    
    if (text.length == 5) {
      FocusScope.of(context).requestFocus(nextFocusNode);
    }
  }

  // 労働時間を計算するロジック
  void _calculateWorkTime() {
    try {
      final String checkInText = _checkInController.text;
      final String checkOutText = _checkOutController.text;
      final int breakMinutes = int.tryParse(_breakController.text) ?? 0;

      final RegExp timeRegExp = RegExp(r"^\d{2}:\d{2}$");
      if (!timeRegExp.hasMatch(checkInText) || !timeRegExp.hasMatch(checkOutText)) {
        setState(() {
          _workTimeResult = "入力形式が不正です（例: 08:00）";
          _decimalTimeResult = "労働時間：計算できませんでした";
        });
        return;
      }

      final int checkInHour = int.parse(checkInText.substring(0, 2));
      final int checkInMinute = int.parse(checkInText.substring(3, 5));
      final int checkOutHour = int.parse(checkOutText.substring(0, 2));
      final int checkOutMinute = int.parse(checkOutText.substring(3, 5));

      final DateTime checkIn = DateTime(2025, 1, 1, checkInHour, checkInMinute);
      final DateTime checkOut = DateTime(2025, 1, 1, checkOutHour, checkOutMinute);

      final Duration totalDuration = checkOut.difference(checkIn);
      final int workMinutes = totalDuration.inMinutes - breakMinutes;

      if (workMinutes < 0) {
        setState(() {
          _workTimeResult = "退勤時間は出勤時間より後でなければなりません";
          _decimalTimeResult = "労働時間：計算できませんでした";
        });
        return;
      }

      final int finalHours = workMinutes ~/ 60;
      final int finalMinutes = workMinutes % 60;

      final double decimalHours = finalHours + (finalMinutes / 60);

      setState(() {
        _workTimeResult = "労働時間：$finalHours時間$finalMinutes分";
        _decimalTimeResult = "労働時間：${decimalHours.toStringAsFixed(2)}時間";
      });
    } catch (e) {
      setState(() {
        _workTimeResult = "計算できませんでした";
        _decimalTimeResult = "労働時間：計算できませんでした";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('労働時間計算アプリ'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildInputField(
                controller: _checkInController,
                labelText: '出勤時間',
                hintText: '例: 08:00',
                focusNode: _checkInFocusNode,
              ),
              const SizedBox(height: 20),
              _buildInputField(
                controller: _checkOutController,
                labelText: '退勤時間',
                hintText: '例: 18:00',
                focusNode: _checkOutFocusNode,
              ),
              const SizedBox(height: 20),
              _buildInputField(
                controller: _breakController,
                labelText: '休憩時間 (分)',
                hintText: '例: 60',
                focusNode: _breakFocusNode,
                isTimeInput: false,
              ),
              const SizedBox(height: 40),
              Text(
                _workTimeResult,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                _decimalTimeResult,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 共通の入力フィールドウィジェット
  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required FocusNode focusNode,
    bool isTimeInput = true,
  }) {
    return SizedBox(
      width: 200,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: isTimeInput ? TextInputType.number : const TextInputType.numberWithOptions(decimal: false),
        inputFormatters: [
          LengthLimitingTextInputFormatter(isTimeInput ? 5 : 4),
          if (isTimeInput) _TimeInputFormatter() else FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

// ユーザーが数字のみを入力できるようにし、コロンを自動挿入するカスタムフォーマッター
class _TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text;
    
    // 数字以外の文字を削除
    newText = newText.replaceAll(RegExp(r'[^\d:]'), '');

    // コロンを挿入
    if (newText.length > 2 && newText[2] != ':') {
      newText = newText.substring(0, 2) + ':' + newText.substring(2);
    }
    
    // 最大長を5に制限
    if (newText.length > 5) {
      newText = newText.substring(0, 5);
    }

    // カーソル位置を調整
    int newSelectionOffset = newValue.selection.end;
    if (oldValue.text.length < newText.length) {
      if (oldValue.text.length == 2 && newValue.text.length == 3 && newValue.text[2] == ':') {
        newSelectionOffset++;
      }
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newSelectionOffset),
    );
  }
}