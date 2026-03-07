import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(locale: 'it_IT', symbol: '€');
final _dayFmt = DateFormat('EEE d MMM', 'it_IT');
final _dateFmt = DateFormat('dd/MM/yyyy');

String euro(num v) => _currency.format(v);
String dayLabel(DateTime d) => _dayFmt.format(d);
String dateLabel(DateTime d) => _dateFmt.format(d);
