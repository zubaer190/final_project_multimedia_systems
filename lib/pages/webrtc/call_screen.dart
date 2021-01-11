import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:webrtc/pages/webrtc/signaling.dart';
import 'package:clipboard/clipboard.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CallScreen extends StatelessWidget {
  final String ip;

  const CallScreen({Key key, @required this.ip}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (_) => CallProvider(),
        child: CallBody(
          ip: ip,
        ));
  }
}

class CallBody extends StatefulWidget {
  Signaling _signaling;
  static String tag = 'call_sample';
  final String ip;

  CallBody({Key key, @required this.ip}) : super(key: key);

  @override
  _CallBodyState createState() {
    return _CallBodyState(serverIP: ip);
  }
}

class _CallBodyState extends State<CallBody> {
  Signaling _signaling;
  var _selfId;
  String selfSocketId = "";
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  bool _inCalling = false;
  final String serverIP;

  final TextEditingController textEditingController = TextEditingController();

  _CallBodyState({Key key, @required this.serverIP});

  initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  @override
  void initState() {
    super.initState();
    initRenderers();
    _connect();
  }

  @override
  deactivate() {
    super.deactivate();
    if (_signaling != null) _signaling.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
  }

  void _connect() async {
    if (_signaling == null) {
      _signaling = Signaling(serverIP)..connect();

      _signaling.onStateChange = (SignalingState state) {
        switch (state) {
          case SignalingState.CallStateNew:
            this.setState(() {
              _inCalling = true;
            });
            break;
          case SignalingState.CallStateBye:
            this.setState(() {
              _localRenderer.srcObject = null;
              _remoteRenderer.srcObject = null;
              _inCalling = false;
            });
            break;
          case SignalingState.CallStateInvite:
          case SignalingState.CallStateConnected:
          case SignalingState.CallStateRinging:
          case SignalingState.ConnectionClosed:
          case SignalingState.ConnectionError:
          case SignalingState.ConnectionOpen:
            break;
        }
      };

      _signaling.onEventUpdate = ((event) {
        final clientId = event['clientId'];
        selfSocketId = clientId;
        context.read<CallProvider>().updateClientIp(clientId);
      });

      _signaling.onPeersUpdate = ((event) {
        this.setState(() {
          _selfId = event['self'];
        });
      });

      _signaling.onLocalStream = ((stream) {
        _localRenderer.srcObject = stream;
      });

      _signaling.onAddRemoteStream = ((stream) {
        _remoteRenderer.srcObject = stream;
      });

      _signaling.onRemoveRemoteStream = ((stream) {
        _remoteRenderer.srcObject = null;
      });
    }
  }

  _copyONClipborad(context) async {
    String myId = selfSocketId.replaceAll("Id: ", "");
    FlutterClipboard.copy(myId).then(( value ) => print('copied'));

    Fluttertoast.showToast(
        msg: myId,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.grey,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }

  _invitePeer(context, peerId, useScreen) async {
    if (_signaling != null && peerId != _selfId) {
      _signaling.invite(peerId, 'video', useScreen);
    }
  }

  _hangUp() {
    if (_signaling != null) {
      _signaling.bye();
    }
  }

  _switchCamera() {
    _signaling.switchCamera();
  }

  _muteMic() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<CallProvider>(
          builder: (context, provider, child) {
            final clientId = provider.clientid;
            return clientId.isNotEmpty
                ? Text('$clientId')
                : Text('P2P Call Sample');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: null,
            tooltip: 'setup',
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _inCalling
          ? SizedBox(
              width: 200.0,
              child: Row(
                children: [
                  FloatingActionButton(
                      onPressed: _switchCamera,
                      child: const Icon(Icons.switch_camera)),
                  FloatingActionButton(
                    onPressed: _hangUp,
                    child: const Icon(Icons.call_end),
                    tooltip: 'Hangup',
                  ),
                  FloatingActionButton(
                    onPressed: _muteMic,
                    child: const Icon(Icons.mic_off),
                  )
                ],
              ),
            )
          : null,
      body: _inCalling
          ? OrientationBuilder(builder: (context, orientation) {
              return Container(
                child: Stack(
                  children: [
                    Positioned(
                        left: 0.0,
                        right: 0.0,
                        top: 0.0,
                        bottom: 0.0,
                        child: Container(
                          child: Container(
                            margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height,
                            child: RTCVideoView(_remoteRenderer),
                            decoration: BoxDecoration(color: Colors.black54),
                          ),
                        )),
                    Positioned(
                        left: 20.0,
                        top: 20.0,
                        child: Container(
                          width: orientation == Orientation.portrait
                              ? 90.0
                              : 120.0,
                          height: orientation == Orientation.portrait
                              ? 120.0
                              : 90.0,
                          child: RTCVideoView(_localRenderer),
                          decoration: BoxDecoration(color: Colors.black54),
                        ))
                  ],
                ),
              );
            })
          : Container(
              color: Colors.black12,
              child: Column(
                children: [
                  FlatButton(
                    onPressed: () {
                      _copyONClipborad(context);
                    },
                    child: Text('Copy Your Caller Id'),
                    color: Colors.grey,
                  ),
                  TextField(
                    controller: textEditingController,
                  ),
                  FlatButton(
                    onPressed: () {
                      _invitePeer(context, textEditingController.text, false);
                    },
                    child: Text('Call'),
                    color: Colors.amber,
                  )
                ],
              ),
            ),
    );
  }
}

class CallProvider with ChangeNotifier {
  String clientid = "";

  void updateClientIp(String newClientId) {
    clientid = newClientId;
    notifyListeners();
  }
}
