import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import '../../models/product.dart';
import '../../models/sale.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final String _searchQuery = '';
  final String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (status.isDenied) {
        await Permission.storage.request();
      }
    }
  }

  Future<void> _importFromExcel() async {
    try {
      // Check permissions first
      await _checkPermissions();

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecting file...')),
        );
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No file selected')),
          );
        }
        return;
      }

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reading Excel file...')),
        );
      }

      final bytes = result.files.first.bytes;
      if (bytes == null) {
        final file = File(result.files.first.path!);
        final fileBytes = await file.readAsBytes();
        final excelFile = excel.Excel.decodeBytes(fileBytes);
        await _processExcel(excelFile);
      } else {
        final excelFile = excel.Excel.decodeBytes(bytes);
        await _processExcel(excelFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing products: $e')),
        );
      }
      debugPrint('Error importing Excel: $e');
    }
  }

  Future<void> _processExcel(excel.Excel excelFile) async {
    int importedCount = 0;
    debugPrint('Starting Excel import process...');

    for (var table in excelFile.tables.keys) {
      final sheet = excelFile.tables[table]!;
      debugPrint('Processing sheet: $table');
      debugPrint('Number of rows: ${sheet.rows.length}');

      // Skip header row
      for (var row in sheet.rows.skip(1)) {
        if (row.length < 4) {
          debugPrint('Skipping row: Insufficient columns');
          continue;
        }

        final name = row[0]?.value?.toString() ?? '';
        final price = double.tryParse(row[1]?.value?.toString() ?? '0') ?? 0;
        final quantity = int.tryParse(row[2]?.value?.toString() ?? '0') ?? 0;
        final category = row[3]?.value?.toString() ?? 'Uncategorized';

        debugPrint('Processing row:');
        debugPrint('  Name: $name');
        debugPrint('  Price: $price');
        debugPrint('  Quantity: $quantity');
        debugPrint('  Category: $category');

        if (name.isEmpty || price <= 0) {
          debugPrint('Skipping invalid row: Empty name or invalid price');
          continue;
        }

        final product = Product(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          price: price,
          quantity: quantity,
          category: category,
          description: row.length > 4 ? row[4]?.value?.toString() ?? '' : null,
          createdAt: DateTime.now(),
        );

        await Hive.box<Product>('products').add(product);
        importedCount++;
        debugPrint('Successfully imported product: ${product.name}');
      }
    }

    debugPrint('Import complete. Total products imported: $importedCount');
    debugPrint(
        'Total products in database: ${Hive.box<Product>('products').length}');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Successfully imported $importedCount products')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditProductDialog([Product? product]) {
    showDialog(
      context: context,
      builder: (context) => _AddEditProductDialog(product: product),
    );
  }

  void _deleteProduct(Product product) {
    product.delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _importFromExcel,
            tooltip: 'Import from Excel',
          ),
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: () => context.push('/products/add'),
            tooltip: 'Add Product',
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Product>('products').listenable(),
        builder: (context, box, _) {
          final products = box.values.toList();
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No products yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first product by tapping the + button',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Slidable(
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (_) => _showAddEditProductDialog(product),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      icon: Icons.edit,
                      label: 'Edit',
                    ),
                    SlidableAction(
                      onPressed: (_) => _deleteProduct(product),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                      icon: Icons.delete,
                      label: 'Delete',
                    ),
                  ],
                ),
                child: ListTile(
                  title: Text(product.name),
                  subtitle: Text(product.category),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${product.price}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          Text(
                            'Qty: ${product.quantity}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: product.quantity > 0
                            ? () => _decreaseQuantity(product)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                  onTap: () => _showAddEditProductDialog(product),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/products/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _decreaseQuantity(Product product) async {
    if (product.quantity <= 0) return;

    final newQuantity = product.quantity - 1;
    final updatedProduct = Product(
      id: product.id,
      name: product.name,
      price: product.price,
      quantity: newQuantity,
      category: product.category,
      description: product.description,
      createdAt: product.createdAt,
    );

    try {
      final box = Hive.box<Product>('products');
      final index = box.values.toList().indexOf(product);
      await box.putAt(index, updatedProduct);

      // Create a new sale record
      final sale = Sale.create(
        productId: product.id,
        quantity: 1,
        unitPrice: product.price,
      );
      await Hive.box<Sale>('sales').add(sale);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} quantity decreased to $newQuantity'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                final originalProduct = Product(
                  id: product.id,
                  name: product.name,
                  price: product.price,
                  quantity: product.quantity,
                  category: product.category,
                  description: product.description,
                  createdAt: product.createdAt,
                );
                await box.putAt(index, originalProduct);
                // Remove the sale record
                final salesBox = Hive.box<Sale>('sales');
                final saleIndex = salesBox.values.toList().indexOf(sale);
                if (saleIndex != -1) {
                  await salesBox.deleteAt(saleIndex);
                }
              },
            ),
          ),
        );
      }

      // Show warning if stock is low
      if (newQuantity <= 5) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Low stock alert: ${product.name} (Qty: $newQuantity)'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating quantity: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

class _AddEditProductDialog extends StatefulWidget {
  final Product? product;

  const _AddEditProductDialog({this.product});

  @override
  State<_AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends State<_AddEditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _expiryDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _categoryController.text = widget.product!.category;
      _quantityController.text = widget.product!.quantity.toString();
      _priceController.text = widget.product!.price.toString();
      _notesController.text = widget.product!.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final product = Product(
        id: widget.product?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        category: _categoryController.text,
        quantity: int.parse(_quantityController.text),
        price: double.parse(_priceController.text),
        description:
            _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
      );

      if (widget.product == null) {
        await Hive.box<Product>('products').add(product);
      } else {
        final box = Hive.box<Product>('products');
        final index = box.values.toList().indexOf(widget.product!);
        await box.putAt(index, product);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving product: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Edit Product',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                _buildInputField(
                  label: 'Name',
                  controller: _nameController,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Category',
                  controller: _categoryController,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Quantity',
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Price',
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Expiry Date'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _expiryDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (date != null) {
                          setState(() => _expiryDate = date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Theme.of(context).colorScheme.outline),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _expiryDate?.toString().split(' ')[0] ??
                                  'Not set',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _expiryDate ?? DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365 * 5)),
                                );
                                if (date != null) {
                                  setState(() => _expiryDate = date);
                                }
                              },
                              icon: const Icon(Icons.calendar_today, size: 20),
                              label: const Text('Select Date'),
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Notes (Optional)',
                  controller: _notesController,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isLoading ? null : _saveProduct,
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide:
                  BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide:
                  BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide:
                  BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          style: Theme.of(context).textTheme.bodyLarge,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            if (keyboardType == TextInputType.number) {
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
            }
            return null;
          },
        ),
      ],
    );
  }
}
