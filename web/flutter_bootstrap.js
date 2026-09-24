{{flutter_js}}
{{flutter_build_config}}

// Fade out the HTML splash once the first Flutter frame is on screen.
_flutter.loader.load({
  onEntrypointLoaded: async (engineInitializer) => {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    const splash = document.getElementById('splash');
    if (splash) {
      splash.classList.add('done');
      setTimeout(() => splash.remove(), 400);
    }
  },
});
