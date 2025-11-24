import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _scanning = false;
  String _errorMessage = '';
  String _id = '';
  String _name = '';
  int _value = 0;
  int _amount = 0;

  void _startNFCReading() async {
    try {
      setState(() {
        _scanning = true;
        _errorMessage = '';
      });

      NFCTag tag = await FlutterNfcKit.poll();
      String dataTag = jsonEncode(tag.toJson());
      debugPrint(dataTag);
      setState(() {
        _scanning = false;
      });
      requestProduct(dataTag);
    } catch (e) {
      setState(() {
        _scanning = false;
        _errorMessage = 'Error leyendo el NFC: $e';
      });
    } finally {
      await FlutterNfcKit.finish();
    }
  }

  void requestProduct(tagInfo) async {
    try {
      var response = await http.post(
        Uri.parse('http://192.168.88.251:3000/product'),
        headers: {'Content-Type': 'text/plain'},
        body: tagInfo,
      );

      if (response.statusCode == 404) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateProductPage(tagInfo: tagInfo),
          ),
        );
        return;
      }

      if (response.statusCode != 200) {
        return setState(() {
          _errorMessage = 'Error en la solicitud';
        });
      }

      var data = jsonDecode(response.body);
      setState(() {
        _id = data['id'];
        _name = data['name'];
        _value = data['value'];
        _amount = data['amount'];
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViewProductPage(
            id: _id,
            name: _name,
            value: _value,
            amount: _amount,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage =
            'Verifique su conexion a internet o intentelo de nuevo mas tarde.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lector de NFC'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _scanning ? null : _startNFCReading,
              child: const Text('Lectura NFC'),
            ),
            const SizedBox(height: 20),
            if (_scanning)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                  'Acerque la tarjeta por la parte superior trasera del celular.'),
            ),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}

class CreateProductPage extends StatefulWidget {
  final String tagInfo;
  const CreateProductPage({super.key, required this.tagInfo});

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  final _amountController = TextEditingController();

  void createProduct() async {
    try {
      final tagData = jsonDecode(widget.tagInfo);
      final nfcId = tagData['id'];

      Map newProduct = {
        'name': _nameController.text,
        'value': int.tryParse(_valueController.text),
        'amount': int.tryParse(_amountController.text),
        'nfcId': nfcId,
      };

      final request = jsonEncode(newProduct);

      var response = await http.post(
        Uri.parse('http://192.168.88.251:3000/create'),
        headers: {'Content-Type': 'text/plain'},
        body: request,
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        setState(() {
          _tagInfo = 'Producto creado correctamente.';
        });
      }
    } catch (e) {
      setState(() {
        _tagInfo = 'Error: ${e.toString()}';
      });
    }
  }

  String _tagInfo = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Producto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Este producto no se encuentra en la base de datos.'),
            const Text('Ingresa los datos del producto.'),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration:
                  const InputDecoration(labelText: 'Nombre del Producto'),
            ),
            TextField(
              controller: _valueController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Valor del Producto'),
            ),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Cantidad del Producto'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: createProduct,
              child: const Text('Crear Producto'),
            ),
            const SizedBox(height: 20),
            if (_tagInfo.isNotEmpty) Text(_tagInfo),
          ],
        ),
      ),
    );
  }
}

class ViewProductPage extends StatefulWidget {
  final String id;
  final String name;
  final int value;
  final int amount;

  const ViewProductPage({
    super.key,
    required this.id,
    required this.name,
    required this.value,
    required this.amount,
  });

  @override
  State<ViewProductPage> createState() => _ViewProductPageState();
}

class _ViewProductPageState extends State<ViewProductPage> {
  late String id;
  late String name;
  late int value;
  late int amount;

  @override
  void initState() {
    super.initState();
    id = widget.id;
    name = widget.name;
    value = widget.value;
    amount = widget.amount;
  }

  void updateProduct() async {
    final updatedProduct = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateProductPage(
          id: id,
          name: name,
          value: value,
          amount: amount,
        ),
      ),
    );

    setState(() {
      id = updatedProduct['id'];
      name = updatedProduct['name'];
      value = updatedProduct['value'];
      amount = updatedProduct['amount'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ver Producto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Id: $id'),
            Text('Nombre: $name'),
            Text('Valor: $value'),
            Text('Cantidad: $amount'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateProduct,
              child: const Text('Actualizar Producto'),
            ),
          ],
        ),
      ),
    );
  }
}

class UpdateProductPage extends StatefulWidget {
  final String id;
  final String name;
  final int value;
  final int amount;

  const UpdateProductPage({
    super.key,
    required this.id,
    required this.name,
    required this.value,
    required this.amount,
  });

  @override
  State<UpdateProductPage> createState() => _UpdateProductPageState();
}

class _UpdateProductPageState extends State<UpdateProductPage> {
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.name;
    _valueController.text = widget.value.toString();
    _amountController.text = widget.amount.toString();
  }

  void updateProduct() async {
    try {
      Map updatedProduct = {
        'id': widget.id,
        'name': _nameController.text,
        'value': int.tryParse(_valueController.text) ?? 0,
        'amount': int.tryParse(_amountController.text) ?? 0,
      };

      final request = jsonEncode(updatedProduct);

      var response = await http.post(
        Uri.parse('http://192.168.88.251:3000/update'),
        headers: {'Content-Type': 'text/plain'},
        body: request,
      );

      if (response.statusCode != 200) {
        return setState(() {
          _errorMessage =
              'Error al actualizar el producto. Inténtelo de nuevo.';
        });
      }

      Navigator.pop(context, updatedProduct);
    } catch (e) {
      setState(() {
        _errorMessage = 'Intentelo de nuevo mas tarde.';
      });
    }
  }

  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actualizar Producto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration:
                  const InputDecoration(labelText: 'Nombre del Producto'),
            ),
            TextField(
              controller: _valueController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Valor del Producto'),
            ),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Cantidad del Producto'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateProduct,
              child: const Text('Guardar Cambios'),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
