//import 'dart:html';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
//import 'package:flutter_blue/gen/flutterblue.pb.dart';

void main() {
  runApp(BleApp());
}

class BleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    return MaterialApp(
      title: 'BLE Flutter App',
      theme: ThemeData(primarySwatch: Colors.purple),
      home: HomePage(title: 'BLE-Flutter'),
    );

    //throw UnimplementedError();
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key? key, required this.title}) : super(key: key);

  final String title;
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  // ignore: deprecated_member_use
  final List<BluetoothDevice> devicesList = [];
  final Map<Guid, List<int>> readValues = new Map<Guid, List<int>>();

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final writeController = TextEditingController();
  BluetoothDevice? connectedDevice;
  List<BluetoothService> services = [];

  _addDeviceTolist(final BluetoothDevice device) {
    if (!widget.devicesList.contains(device)) {
      setState(() {
        widget.devicesList.add(device);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    widget.flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        _addDeviceTolist(device);
      }
    });
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        _addDeviceTolist(result.device);
      }
    });
    widget.flutterBlue.startScan();
  }

  // ignore: unused_element
  ListView _buildListViewOfDevices() {
    List<Container> containers = [];
    for (BluetoothDevice device in widget.devicesList) {
      containers.add(Container(
        height: 50,
        child: Row(
          children: <Widget>[
            Expanded(
                child: Column(
              children: <Widget>[
                Text(device.name),
                Text(device.id.toString()),
              ],
            )),
            ElevatedButton(
              child: Text('Connect to Device'),
              onPressed: () async {
                widget.flutterBlue.stopScan();
                try {} catch (e) {
                  if (e != "already_connected") {
                    throw e;
                  }
                } finally {
                  if (device.state == BluetoothDeviceState.disconnected) {
                    services = await device.discoverServices();
                  }
                }
                setState(() {
                  connectedDevice = device;
                });
              },
            )
          ],
        ),
      ));
    }
    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  List<ButtonTheme> _buildReadWriteNotifyButton(
      BluetoothCharacteristic characteristic) {
    List<ButtonTheme> buttons = [];
    if (characteristic.properties.read) {
      buttons.add(ButtonTheme(
        minWidth: 10,
        height: 20,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ElevatedButton(
            child: Text('READ', style: TextStyle(color: Colors.white)),
            onPressed: () async {
              var sub = characteristic.value.listen((value) {
                setState(() {
                  widget.readValues[characteristic.uuid] = value;
                });
              });
              await characteristic.read();
              sub.cancel();
            },
          ),
        ),
      ));
    }
    if (characteristic.properties.write) {
      //finish this function...
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              child: Text('WRITE', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Write"),
                        content: Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: writeController,
                              ),
                            ),
                          ],
                        ),
                        actions: <Widget>[
                          ElevatedButton(
                            child: Text("Send"),
                            onPressed: () {
                              characteristic.write(
                                  utf8.encode(writeController.value.text));
                              Navigator.pop(context);
                            },
                          ),
                          ElevatedButton(
                            child: Text("Cancel"),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    });
              },
            ),
          ),
        ),
      );
    }
    if (characteristic.properties.notify) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              child: Text('NOTIFY', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                characteristic.value.listen((value) {
                  widget.readValues[characteristic.uuid] = value;
                });
                await characteristic.setNotifyValue(true);
              },
            ),
          ),
        ),
      );
    }
    return buttons;
  }

  ListView _buildConnectedDeviceView() {
    List<Container> container = [];
    for (BluetoothService service in services) {
      List<Widget> characteristicsWidget = [];
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        characteristicsWidget.add(Align(
          alignment: Alignment.centerLeft,
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(characteristic.uuid.toString()),
                ],
              ),
              Row(
                children: <Widget>[
                  Text('Value:' +
                      widget.readValues[characteristic.uuid].toString()),
                ],
              ),
              Row(
                children: <Widget>[
                  Text('Value:' +
                      widget.readValues[characteristic.uuid].toString()),
                ],
              ),
              Divider(),
            ],
          ),
        ));
      }
      container.add(Container(
          child: ExpansionTile(
        title: Text(service.uuid.toString()),
        children: characteristicsWidget,
      )));
    }
    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...container,
      ],
    );
  }

  ListView _buildView() {
    if (connectedDevice != null) {
      return _buildConnectedDeviceView();
    }
    return _buildListViewOfDevices();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: _buildView(),
      );
  // @override
  // Widget build(BuildContext context) {
  //   // TODO: implement build
  //   print("Screen running");
  //   throw UnimplementedError();
  // }
}
