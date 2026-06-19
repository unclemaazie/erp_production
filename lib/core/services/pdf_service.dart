import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<Uint8List> generateInvoice({
    required String invoiceNumber,
    required String customerName,
    required DateTime date,
    required List<Map<String, dynamic>> items,
    required double total,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('INVOICE', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text('Invoice #: \$invoiceNumber'),
            pw.Text('Date: \${date.toIso8601String().split("T").first}'),
            pw.Text('Customer: \$customerName'),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Description', 'Qty', 'Unit Price', 'Total'],
              data: items.map((i) => [
                i['description'] ?? '',
                (i['quantity'] ?? 0).toString(),
                'R \${i['unit_price'] ?? 0}',
                'R \${i['line_total'] ?? 0}',
              ]).toList(),
            ),
            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('TOTAL: R \$total', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
    return pdf.save();
  }

  static Future<void> printInvoice(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }

  static Future<void> shareInvoice(Uint8List bytes, String fileName) async {
    // Requires share_plus integration
  }
}
