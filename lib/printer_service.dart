import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PrinterService {
  Future<List<Uint8List>> getPreviewImages(Uint8List pdfBytes) async {
    final rasterStream = Printing.raster(pdfBytes, pages: [0, 1], dpi: 72);
    final List<PdfRaster> rasters = await rasterStream.toList();
    return Future.wait(rasters.map((r) => r.toPng()));
  }

  Future<void> splitAndPrintComplex({
    required Uint8List pdfBytes,
    required Printer printer1,
    required PdfPageFormat format1,
    required double scale1,
    required Printer printer2,
    required PdfPageFormat format2,
    required double scale2,
  }) async {
    final rasterStream = Printing.raster(pdfBytes, pages: [0, 1], dpi: 200);
    final List<PdfRaster> pages = await rasterStream.toList();

    if (pages.length < 2) throw Exception('PDF tem menos de 2 páginas');

    await _printSinglePage(
      image: pages[0],
      printer: printer1,
      format: format1,
      scale: scale1,
    );

    await _printSinglePage(
      image: pages[1],
      printer: printer2,
      format: format2,
      scale: scale2,
    );
  }

  Future<void> _printSinglePage({
    required PdfRaster image,
    required Printer printer,
    required PdfPageFormat format,
    required double scale,
  }) async {
    final Uint8List pngBytes = await image.toPng();

    // 1. Cálculos Matemáticos
    final double aspectRatio = image.width.toDouble() / image.height.toDouble();
    final double finalWidth = format.width * scale;
    final double finalHeight = finalWidth / aspectRatio;

    // 2. Posição para Esquerda no topo da página
    const double left = 0;
    const double top = 0;

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.zero,
        clip: true,
        build: (pw.Context context) {
          return pw.Container(
            color: PdfColors.white,
            child: pw.Stack(
              children: [
                // CORREÇÃO: Removemos width/height do Positioned
                pw.Positioned(
                  left: left,
                  top: top,
                  // E aplicamos o tamanho diretamente no Container filho
                  child: pw.Container(
                    width: finalWidth,
                    height: finalHeight,
                    child: pw.Image(
                      pw.MemoryImage(pngBytes),
                      fit: pw.BoxFit.fill,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    try {
      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'Impressão Logística Shopee',
        usePrinterSettings: true,
      );
    } catch (e) {
      print('Aviso: $e');
    }
  }
}
