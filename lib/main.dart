// ignore_for_file: avoid_print

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Printer Connection'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              // Replace with your printer's IP address
              const printerIp = '192.168.0.87';
              connectToPrinter(printerIp);
            },
            child: const Text('Connect to Printer'),
          ),
        ),
      ),
    );
  }

  Invoice generateRandomInvoice() {
    final random = Random();
    final items = List<InvoiceItem>.generate(5, (index) {
      return InvoiceItem(
        description: 'Item ${index + 1}',
        quantity: random.nextInt(5) + 1,
        price: (random.nextDouble() * 20).roundToDouble(),
      );
    });

    return Invoice(
      invoiceNumber: 'INV-${random.nextInt(1000)}',
      date: DateTime.now(),
      items: items,
    );
  }

  void printInvoice(NetworkPrinter printer, Invoice invoice) {
    final dateFormatter = DateFormat('yyyy-MM-dd');

    printer.text(
      'INVOICE',
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
      linesAfter: 1,
    );

    printer.text('Invoice Number: ${invoice.invoiceNumber}');
    printer.text('Date: ${dateFormatter.format(invoice.date)}');
    printer.hr();

    printer.row([
      PosColumn(
        text: 'Description',
        width: 6,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: 'Qty',
        width: 2,
        styles: const PosStyles(align: PosAlign.right),
      ),
      PosColumn(
        text: 'Price',
        width: 2,
        styles: const PosStyles(align: PosAlign.right),
      ),
      PosColumn(
        text: 'Total',
        width: 2,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    double total = 0;

    for (var item in invoice.items) {
      final itemTotal = item.quantity * item.price;
      total += itemTotal;

      printer.row([
        PosColumn(
          text: item.description,
          width: 6,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: item.quantity.toString(),
          width: 2,
          styles: const PosStyles(align: PosAlign.right),
        ),
        PosColumn(
          text: item.price.toStringAsFixed(2),
          width: 2,
          styles: const PosStyles(align: PosAlign.right),
        ),
        PosColumn(
          text: itemTotal.toStringAsFixed(2),
          width: 2,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    printer.hr();
    printer.row([
      PosColumn(
        text: 'Total',
        width: 8,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
      PosColumn(
        text: total.toStringAsFixed(2),
        width: 4,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);

    printer.feed(2);
    printer.cut();
  }

  Future<void> connectToPrinter(String printerIp) async {
    final profile = await CapabilityProfile.load();
    final printer = NetworkPrinter(PaperSize.mm80, profile);

    final PosPrintResult res = await printer.connect(printerIp, port: 9100);
    if (res == PosPrintResult.success) {
      Get.snackbar("Success", "Connected To Printer");
      final invoice = generateRandomInvoice();
      printInvoice(printer, invoice);
      printer.disconnect();
    } else {
      print('Failed to connect: $res');
    }
  }
}

class InvoiceItem {
  final String description;
  final int quantity;
  final double price;

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.price,
  });
}

class Invoice {
  final String invoiceNumber;
  final DateTime date;
  final List<InvoiceItem> items;

  Invoice({
    required this.invoiceNumber,
    required this.date,
    required this.items,
  });
}
