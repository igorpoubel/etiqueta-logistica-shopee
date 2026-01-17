import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'printer_service.dart';

class DualPrinterScreen extends StatefulWidget {
  const DualPrinterScreen({super.key});

  @override
  State<DualPrinterScreen> createState() => _DualPrinterScreenState();
}

class _DualPrinterScreenState extends State<DualPrinterScreen> {
  final _printerService = PrinterService();

  static const _label100x150 =
      PdfPageFormat(100 * PdfPageFormat.mm, 150 * PdfPageFormat.mm);

  final Map<String, PdfPageFormat> _paperFormats = {
    'A4': PdfPageFormat.a4,
    'Etiqueta 100x150mm': _label100x150,
  };

  List<Printer> _availablePrinters = [];
  bool _isLoading = false;

  PlatformFile? _selectedFile;
  Uint8List? _loadedPdfBytes;
  List<Uint8List>? _previewImages;

  Printer? _printerPage1;
  Printer? _printerPage2;

  final String _defaultFormatKey1 = 'Etiqueta 100x150mm';
  final String _defaultFormatKey2 = 'A4';

  String _selectedFormatKey1 = 'Etiqueta 100x150mm';
  String _selectedFormatKey2 = 'A4';

  double _scale1 = 2.0;
  double _scale2 = 1.0;

  @override
  void initState() {
    super.initState();
    _initSetup();
  }

  Future<void> _initSetup() async {
    setState(() => _isLoading = true);
    await _loadPrinters();
    await _loadPreferences();
    setState(() => _isLoading = false);
  }

  Future<void> _loadPrinters() async {
    try {
      final printers = await Printing.listPrinters();
      setState(() {
        _availablePrinters = printers;
        if (printers.isNotEmpty) {
          _printerPage1 = printers.first;
          _printerPage2 = printers.length > 1 ? printers[1] : printers.first;
        }
      });
    } catch (e) {
      _showSnack('Erro impressoras: $e', isError: true);
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final savedP1 = prefs.getString('p1_name');
      final savedP2 = prefs.getString('p2_name');

      _selectedFormatKey1 = prefs.getString('p1_format') ?? _defaultFormatKey1;
      _selectedFormatKey2 = prefs.getString('p2_format') ?? _defaultFormatKey2;

      _scale1 = prefs.getDouble('p1_scale') ?? 1.0;
      _scale2 = prefs.getDouble('p2_scale') ?? 1.0;

      if (savedP1 != null) {
        try {
          _printerPage1 =
              _availablePrinters.firstWhere((p) => p.name == savedP1);
        } catch (_) {}
      }
      if (savedP2 != null) {
        try {
          _printerPage2 =
              _availablePrinters.firstWhere((p) => p.name == savedP2);
        } catch (_) {}
      }
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (_printerPage1 != null)
      await prefs.setString('p1_name', _printerPage1!.name);
    if (_printerPage2 != null)
      await prefs.setString('p2_name', _printerPage2!.name);
    await prefs.setString('p1_format', _selectedFormatKey1);
    await prefs.setString('p2_format', _selectedFormatKey2);
    await prefs.setDouble('p1_scale', _scale1);
    await prefs.setDouble('p2_scale', _scale2);
  }

  Future<void> _pickFile() async {
    setState(() {
      _isLoading = true;
      _previewImages = null;
      _loadedPdfBytes = null;
    });
    try {
      FilePickerResult? result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      if (result != null) {
        final file = result.files.first;
        Uint8List fileBytes;
        if (file.bytes != null)
          fileBytes = file.bytes!;
        else if (file.path != null)
          fileBytes = await File(file.path!).readAsBytes();
        else
          throw Exception("Erro leitura");

        final images = await _printerService.getPreviewImages(fileBytes);
        setState(() {
          _selectedFile = file;
          _loadedPdfBytes = fileBytes;
          _previewImages = images;
        });
      }
    } catch (e) {
      _showSnack('Erro: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processAndPrint() async {
    if (_loadedPdfBytes == null ||
        _printerPage1 == null ||
        _printerPage2 == null) return;
    await _savePreferences();
    setState(() => _isLoading = true);

    try {
      await _printerService.splitAndPrintComplex(
        pdfBytes: _loadedPdfBytes!,
        printer1: _printerPage1!,
        format1: _paperFormats[_selectedFormatKey1]!,
        scale1: _scale1,
        printer2: _printerPage2!,
        format2: _paperFormats[_selectedFormatKey2]!,
        scale2: _scale2,
      );
      _showSnack('Sucesso!');
    } catch (e) {
      _showSnack('Erro: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impressão Logística Shopee')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Row(children: [
                Expanded(flex: 2, child: _buildFileSection()),
                const SizedBox(width: 24),
                Expanded(flex: 3, child: _buildPrintersSection())
              ]),
      ),
    );
  }

  Widget _buildFileSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("PDF", style: TextStyle(fontWeight: FontWeight.bold)),
            if (_selectedFile != null)
              Text(_selectedFile!.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10)),
            const Divider(),
            Expanded(
                child: _previewImages == null
                    ? const Icon(Icons.picture_as_pdf, size: 40)
                    : _buildPreviewGrid()),
            const SizedBox(height: 10),
            ElevatedButton(
                onPressed: _isLoading ? null : _pickFile,
                child: const Text("Abrir PDF")),
          ],
        ),
      ),
    );
  }

  Widget _buildPagePreview(
      String label, Uint8List bytes, double scale, PdfPageFormat format) {
    // Calculamos a proporção: largura / altura
    final double aspectRatio = format.width / format.height;

    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        // Usamos Center para o AspectRatio não tentar ocupar a largura toda se não couber
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400, width: 2),
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(2, 2))
                  ],
                ),
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.topLeft,
                      child: Image.memory(
                        bytes,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildPagePreview(
            "Página 1",
            _previewImages![0],
            _scale1,
            _paperFormats[_selectedFormatKey1]!, // Passa o formato da Pág 1
          ),
        ),
        const VerticalDivider(width: 20),
        Expanded(
          child: _previewImages!.length > 1
              ? _buildPagePreview(
                  "Página 2",
                  _previewImages![1],
                  _scale2,
                  _paperFormats[
                      _selectedFormatKey2]!, // Passa o formato da Pág 2
                )
              : const Center(child: Text("Sem pág 2")),
        ),
      ],
    );
  }

  Widget _buildPrintersSection() {
    return Column(children: [
      _buildConfigCard(
          "Pág 1 (Etiqueta)",
          _printerPage1,
          _selectedFormatKey1,
          (_scale1 - 1.0),
          (p) => setState(() => _printerPage1 = p),
          (f) => setState(() => _selectedFormatKey1 = f!),
          (s) => setState(() => _scale1 = (s + 1.0))),
      const SizedBox(height: 16),
      _buildConfigCard(
          "Pág 2 (Declaração de Conteúdo)",
          _printerPage2,
          _selectedFormatKey2,
          _scale2,
          (p) => setState(() => _printerPage2 = p),
          (f) => setState(() => _selectedFormatKey2 = f!),
          (s) => setState(() => _scale2 = s)),
      const Spacer(),
      SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
              onPressed: (_loadedPdfBytes != null) ? _processAndPrint : null,
              child: const Text('IMPRIMIR'))),
    ]);
  }

  Widget _buildConfigCard(
      String title,
      Printer? printer,
      String formatKey,
      double scale,
      Function(Printer?) setPrinter,
      Function(String?) setFormat,
      Function(double) setScale) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 8),
          DropdownButtonFormField<Printer>(
            isExpanded: true,
            initialValue: printer,
            decoration: const InputDecoration(
                labelText: 'Impressora',
                isDense: true,
                border: OutlineInputBorder()),
            items: _availablePrinters
                .map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p.name, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (p) {
              setState(() => setPrinter(p));
              _savePreferences(); // Salva a escolha da impressora assim que selecionada
            },
          ),
          const SizedBox(height: 8),
          Text(formatKey,
              style: const TextStyle(
                  fontWeight: FontWeight.normal, color: Colors.black)),
          const SizedBox(height: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text("Zoom:", style: TextStyle(fontSize: 12)),
              Text("${((scale) * 100).round()}%",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            // Slider POTENTE: Vai de 0.5 (metade) até 4.0 (4x o tamanho)
            SizedBox(
                height: 20,
                child: Slider(
                  value: scale,
                  min: 0.5,
                  max: 4.0,
                  divisions: 70,
                  onChanged: (double newValue) {
                    // Arredondamos para evitar o problema do 0.899999999
                    // Multiplicamos por 20, arredondamos e dividimos por 20
                    // (Isso força o número a "encaixar" em passos de 0.05)
                    double roundedValue = (newValue * 20).round() / 20;
                    setScale(roundedValue);
                    _savePreferences();
                  },
                )),
          ]),
        ]),
      ),
    );
  }
}
