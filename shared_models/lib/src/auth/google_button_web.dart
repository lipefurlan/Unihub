import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

const googleButtonSupported = true;

Widget renderGoogleButton() => web.renderButton(
      configuration: web.GSIButtonConfiguration(
        text: web.GSIButtonText.continueWith,
        shape: web.GSIButtonShape.pill,
        size: web.GSIButtonSize.large,
        locale: 'pt-BR',
        minimumWidth: 320,
      ),
    );
