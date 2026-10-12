{{flutter_js}}
{{flutter_build_config}}

// Load CanvasKit from the Flutter SDK instead of gstatic.com.
// The CDN request fails on this network and leaves a blank page.
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/",
  },
});
