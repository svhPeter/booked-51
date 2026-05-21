import 'package:flutter_test/flutter_test.dart';
import 'package:doctor_appointment/main.dart';

void main() {
  testWidgets('App renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const DoctorAppointmentApp());
    expect(find.byType(DoctorAppointmentApp), findsOneWidget);
  });
}
