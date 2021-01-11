import 'package:webrtc/app_config.dart';
import 'package:webrtc/my_app.dart';

void main() async {
  Config(environment: Env.dev());
  await myMain();
}
