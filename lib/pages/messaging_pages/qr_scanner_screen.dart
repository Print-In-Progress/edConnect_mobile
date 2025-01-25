import 'package:flutter/material.dart';
import 'package:edconnect_mobile/constants.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:edconnect_mobile/signal_protocol/device_linking_manager.dart';
import 'package:edconnect_mobile/widgets/loading_indicator_overlay.dart';
import 'package:edconnect_mobile/widgets/snackbars.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRCodeGeneratorScreen extends StatefulWidget {
  final String org;
  final String userId;
  const QRCodeGeneratorScreen(
      {super.key, required this.userId, required this.org});

  @override
  State<QRCodeGeneratorScreen> createState() => _QRCodeGeneratorScreenState();
}

class _QRCodeGeneratorScreenState extends State<QRCodeGeneratorScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: DeviceLinkingManager()
          .generateLinkingQRCode(widget.userId, widget.org),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Center(
            child: QrImageView(
              data: snapshot.data!,
              version: QrVersions.auto,
              size: 200.0,
              embeddedImage: const AssetImage(
                  'assets/NewsApp_Logo_Mobile_No_BGxxxhdpi.png'),
            ),
          );
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }
}

class ConnectNewDevice extends StatefulWidget {
  final String userId;
  const ConnectNewDevice({super.key, required this.userId});

  @override
  State<ConnectNewDevice> createState() => _ConnectNewDeviceState();
}

class _ConnectNewDeviceState extends State<ConnectNewDevice> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  void _onQRViewCreated(QRViewController controller, String userCollection,
      String currentUserId, String currentOrg) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (scanData.code != null) {
        try {
          LoadingScreen.instance()
              .show(context: context, text: 'Linking device');
          await DeviceLinkingManager().processScannedQRCode(
            scanData.code!,
            userCollection,
            currentUserId,
            currentOrg,
          );
          LoadingScreen.instance().hide();
          if (mounted) {
            Navigator.of(context).pop('success');
            successMessage(context, 'Device linked successfully');
          }
        } on Exception catch (e) {
          if (e.toString() == 'Invalid QR code. Wrong user or organization.') {
            if (mounted) {
              errorMessage(
                  context, 'Invalid QR code. Wrong user or organization.');
            }
          } else {
            if (mounted) {
              errorMessage(context, 'Error linking device: ${e.toString()}');
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final databaseProvider = Provider.of<DatabaseCollectionProvider>(context);
    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Connect New Device'),
          bottom: TabBar(
              labelColor: themeProvider.darkTheme ? Colors.white : Colors.black,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: <Widget>[
                Tab(text: 'Generate QR Code'),
                Tab(text: 'Scan QR Code'),
              ]),
        ),
        body: TabBarView(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FutureBuilder<String>(
                  future: DeviceLinkingManager().generateLinkingQRCode(
                      widget.userId,
                      databaseProvider.customerSpecificRootCollectionName),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasData) {
                        return Center(
                          child: Card(
                            child: QrImageView(
                              data: snapshot.data!,
                              version: QrVersions.auto,
                              size: 200.0,
                              embeddedImageStyle: QrEmbeddedImageStyle(
                                  size: Size(150, 150),
                                  color: Color.fromARGB(255, 0, 166, 255)),
                              embeddedImage: AssetImage(
                                  'assets/NewsApp_Logo_Mobile_No_BGxxxhdpi.png'),
                            ),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        // Log the error
                        print('Error generating QR code: ${snapshot.error}');
                        return Center(child: Text('Error generating QR code'));
                      } else {
                        // Handle the case where snapshot.data is null
                        return Center(child: Text('No QR code data available'));
                      }
                    } else {
                      return Center(child: CircularProgressIndicator());
                    }
                  },
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Scan the QR code with the new device'),
                  ],
                ),
              ],
            ),
            // Add the second tab content here
            QRView(
              key: qrKey,
              onQRViewCreated: (QRViewController controller) {
                _onQRViewCreated(
                    controller,
                    databaseProvider.customerSpecificCollectionUsers,
                    widget.userId,
                    databaseProvider.customerSpecificRootCollectionName);
              },
            ),
          ],
        ),
      ),
    );
  }
}
