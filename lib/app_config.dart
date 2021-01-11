import 'package:flutter/material.dart';

class Env {
  Env._({@required this.apiBaseUrl});

  final String apiBaseUrl;

  factory Env.dev() {
    return Env._(apiBaseUrl: "https://api.github.com");
  }
}

class Config {
  Config._private();

  static final Config instance = Config._private();

  factory Config({Env environment}) {
    if (environment != null) {
      instance.env = environment;
    }

    return instance;
  }

  Env env;
}
