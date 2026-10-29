package com.tropicbyt.screensaver;

import android.app.Activity;
import android.os.Bundle;
import android.view.KeyEvent;
import android.view.WindowManager;

/**
 * Launchable tester for the screensaver.
 *
 * The real dream only starts after ~10 minutes of idle and cannot be forced
 * from adb without root, which makes iterating on it painful. This activity
 * runs the identical {@link ScenePlayer}, so launching it answers "does the
 * screensaver work?" immediately.
 *
 * Launch it from the Google TV home screen, or:
 *   adb shell am start -n com.tropicbyt.screensaver/.PreviewActivity
 *
 * Any key exits, mirroring the dream's setInteractive(false) behaviour.
 */
public class PreviewActivity extends Activity {

    private ScenePlayer scene;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // Screensavers do not dim; match that so the preview is representative.
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        scene = new ScenePlayer(this, "preview");
        setContentView(scene.createView());
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        finish();  // any input dismisses, exactly as the dream does
        return true;
    }

    @Override
    protected void onDestroy() {
        scene.release();
        super.onDestroy();
    }
}
