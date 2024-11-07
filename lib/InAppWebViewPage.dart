import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dynamic_icon/flutter_dynamic_icon.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:savemaxcid/AppIconIOS.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'IconChanger.dart';

class InAppWebViewPage extends StatefulWidget {
  @override
  State<InAppWebViewPage> createState() => _InAppWebViewPageState();
}

class _InAppWebViewPageState extends State<InAppWebViewPage> {

  AppIconIOS? currentIcon;

  InAppWebViewController? webViewController;
  String? url; // Holds the current URL to be loaded
  bool isFloatingButtonsVisible = false;
  late double _statusBarHeight;

  // URLs for each country
  final String urlCanada = "https://savemax.com/";
  final String urlIndia = "https://savemax.in/";
  final String urlUAE = "https://savemax.ae/";

  @override
  void initState() {

    if(Platform.isIOS) {
      FlutterDynamicIcon.setApplicationIconBadgeNumber(2);
      FlutterDynamicIcon.getAlternateIconName().then((iconName) {
        setState(() {
          currentIcon = AppIconIOS.values.byName(iconName ?? 'canada');
        });
      });
    }

    super.initState();
    _loadSavedCountryUrl(); // Load the saved URL on app launch
  }


  void changeIOSAppIcon(AppIconIOS icon) async {
    try {
      // Check if the device supports alternate icons
      if (await FlutterDynamicIcon.supportsAlternateIcons) {
        // Change the icon
        await FlutterDynamicIcon.setAlternateIconName(icon.name);
        setState(() {
          currentIcon = icon; // Update the currentIcon value
        });
      }else {
        print('notSupportAlternativeIcon');
      }
    } on PlatformException catch (_) {
      print('Failed to change app icon');
    }
  }


  // Load saved URL from SharedPreferences
  Future<void> _loadSavedCountryUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUrl = prefs.getString('selectedCountryUrl');
    setState(() {
      url = savedUrl ?? urlCanada; // Default to Canada URL if no saved URL
    });

    if (url != null) await _loadCookiesForUrl(url!);

  }


  Future<void> _loadCookiesForUrl(String currentUrl) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? cookies = prefs.getStringList('cookies_$currentUrl');

    if (cookies != null) {
      for (String cookie in cookies) {

        print('Loading full cookie data: $cookie');


        // Split cookie string into name and value
        var cookieParts = cookie.split('=');
        if (cookieParts.length == 2) {
          String name = cookieParts[0];
          String value = cookieParts[1];

          // Console log the cookie name and value
        //  print('Loading cookie - Name: $name, Value: $value');

          // Set the cookie in the WebView
          await CookieManager.instance().setCookie(
            url: WebUri(currentUrl),
            name: name,
            value: value,
          );
        }
      }
    } else {
      print('No cookies found for $currentUrl');
    }
  }


  Future<void> _saveCookies(String currentUrl) async {
    List<Cookie> cookies = await CookieManager.instance().getCookies(url: WebUri(currentUrl));
    List<String> cookieStrings = cookies.map((c) => '${c.name}=${c.value}').toList();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('cookies_$currentUrl', cookieStrings);
  }



  // Save selected URL to SharedPreferences
  Future<void> _saveSelectedCountryUrl(String selectedUrl) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedCountryUrl', selectedUrl);
  }

  // Clear cache and history when switching countries
  Future<void> _clearCacheAndLoadNewUrl(String newUrl) async {
    if (webViewController != null) {
      await webViewController!.clearCache();
      await _loadCookiesForUrl(newUrl);
      await webViewController!.loadUrl(
        urlRequest: URLRequest(url: WebUri(newUrl)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: url == null
          ? Center(child: CircularProgressIndicator()) // Show a loader until URL is set
          : Container(
        margin: EdgeInsets.only(top: _statusBarHeight),
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(url!)),

          onWebViewCreated: (controller) {
            webViewController = controller;
          },
          onLoadStop: (controller, url) async {
            print('Finished loading: $url');
            if (url != null) {
              await _saveCookies(url.toString()); // Save cookies after page loads
            }
          },
        ),
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

// Method to build floating action buttons
  Widget _buildFloatingActionButtons() {
    return Stack(
      children: [
        // Main Floating Action Button
        Positioned(
          bottom: 55,
          right: 16,
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                isFloatingButtonsVisible =
                !isFloatingButtonsVisible; // Toggle visibility
              });
            },
            child: Icon(isFloatingButtonsVisible ? Icons.close : Icons.add),
          ),
        ),
        // Additional Floating Action Buttons
        if (isFloatingButtonsVisible) ...[
          Positioned(
            bottom: 120, // Adjust position for the first button
            right: 16,
            child: FloatingActionButton(
              onPressed: () async {
                // Switch to Canada URL
                await _clearCacheAndLoadNewUrl(urlCanada);
                await _saveSelectedCountryUrl(urlCanada); // Save the selected country

                if(Platform.isAndroid) {
                  IconChanger.switchIcon('MainActivityCanada');
                }else {
                  changeIOSAppIcon(AppIconIOS.canada);
                }

                setState(() {
                  url = urlCanada; // Update the URL state
                });
              },
              child: Image.asset(
                'assets/images/canada_flag.png',
                // Replace with your flag image path
                height: 24,
                width: 24,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            bottom: 185, // Adjust position for the second button
            right: 16,
            child: FloatingActionButton(
              onPressed: () async {
                // Switch to India URL
                await _clearCacheAndLoadNewUrl(urlIndia);
                await _saveSelectedCountryUrl(urlIndia); // Save the selected country

                if (Platform.isAndroid) {
                  IconChanger.switchIcon('MainActivityIndia');
                }else {
                  changeIOSAppIcon(AppIconIOS.india);
                }

                setState(() {
                  url = urlIndia; // Update the URL state
                });
              },
              child: Image.asset(
                'assets/images/india_flag.png',
                // Replace with your flag image path
                height: 24,
                width: 24,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            bottom: 250, // Adjust position for the third button
            right: 16,
            child: FloatingActionButton(
              onPressed: () async {
                // Switch to UAE URL
                await _clearCacheAndLoadNewUrl(urlUAE);
                await _saveSelectedCountryUrl(urlUAE); // Save the selected country

                if (Platform.isAndroid) {
                  IconChanger.switchIcon('MainActivityDubai');
                }else {
                  changeIOSAppIcon(AppIconIOS.dubai);
                }

                setState(() {
                  url = urlUAE; // Update the URL state
                });
              },
              child: Image.asset(
                'assets/images/dubai_flag.png',
                // Replace with your flag image path
                height: 24,
                width: 24,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
