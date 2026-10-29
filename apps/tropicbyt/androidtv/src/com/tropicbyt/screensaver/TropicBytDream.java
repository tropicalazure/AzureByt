package com.tropicbyt.screensaver;

import android.service.dreams.DreamService;

/**
 * TropicByt screensaver — plays the bundled 4K pixel-art beach loop.
 *
 * All playback lives in {@link ScenePlayer}, shared with {@link PreviewActivity}
 * so the launchable tester and the real screensaver behave identically.
 *
 * Set as the active screensaver with:
 *   adb shell settings put secure screensaver_components \
 *       com.tropicbyt.screensaver/.TropicBytDream
 */
public class TropicBytDream extends DreamService {

    private ScenePlayer scene;

    @Override
    public void onAttachedToWindow() {
        super.onAttachedToWindow();

        // false => the system dismisses the dream on any remote input for us.
        setInteractive(false);
        setFullscreen(true);
        setScreenBright(true);

        scene = new ScenePlayer(this, "dream");
        setContentView(scene.createView());
    }

    @Override
    public void onDreamingStopped() {
        if (scene != null) {
            scene.release();
        }
        super.onDreamingStopped();
    }

    @Override
    public void onDetachedFromWindow() {
        if (scene != null) {
            scene.release();
        }
        super.onDetachedFromWindow();
    }
}
