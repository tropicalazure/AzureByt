package com.tropicbyt.screensaver;

import android.content.Context;
import android.content.res.AssetFileDescriptor;
import android.graphics.Color;
import android.media.MediaPlayer;
import android.util.Log;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;

/**
 * Plays the bundled beach loop onto a full-screen surface.
 *
 * Shared by {@link TropicBytDream} (the real screensaver) and
 * {@link PreviewActivity} (the launchable tester) so the two cannot drift —
 * whatever you see in the preview is exactly what the screensaver does.
 *
 * The MP4 is stored uncompressed in the APK (see build.ps1's `-0 mp4`), which is
 * what makes AssetManager.openFd() work: MediaPlayer needs a real file
 * descriptor with an offset and length, and a deflated asset has neither.
 */
class ScenePlayer implements SurfaceHolder.Callback,
                             MediaPlayer.OnPreparedListener,
                             MediaPlayer.OnErrorListener {

    static final String TAG = "TropicByt";
    private static final String ASSET = "tropicbyt.mp4";

    private final Context context;
    private final String owner;   // tags log lines so the two callers are distinguishable
    private MediaPlayer player;

    ScenePlayer(Context context, String owner) {
        this.context = context;
        this.owner = owner;
    }

    /** Builds the view hierarchy and wires up the surface callback. */
    View createView() {
        FrameLayout root = new FrameLayout(context);
        // Black backing so nothing flashes through before the first frame lands.
        root.setBackgroundColor(Color.BLACK);

        SurfaceView surface = new SurfaceView(context);
        root.addView(surface, new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT));
        surface.getHolder().addCallback(this);
        return root;
    }

    @Override
    public void surfaceCreated(SurfaceHolder holder) {
        release();
        AssetFileDescriptor afd = null;
        try {
            afd = context.getAssets().openFd(ASSET);
            player = new MediaPlayer();
            player.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());
            player.setSurface(holder.getSurface());
            player.setLooping(true);
            player.setVolume(0f, 0f);
            player.setOnPreparedListener(this);
            player.setOnErrorListener(this);
            player.prepareAsync();
        } catch (Exception e) {
            Log.e(TAG, owner + ": failed to start " + ASSET, e);
            release();
        } finally {
            if (afd != null) {
                try {
                    afd.close();
                } catch (Exception ignored) {
                    // Descriptor already handed to MediaPlayer; closing is best-effort.
                }
            }
        }
    }

    @Override
    public void surfaceChanged(SurfaceHolder holder, int format, int w, int h) {
        // Nothing to do: the surface fills the screen and the video is 16:9,
        // matching the display, so stretching to fit is already correct.
    }

    @Override
    public void surfaceDestroyed(SurfaceHolder holder) {
        release();
    }

    @Override
    public void onPrepared(MediaPlayer mp) {
        mp.start();
        Log.i(TAG, owner + ": playback started ("
                + mp.getVideoWidth() + "x" + mp.getVideoHeight()
                + ", " + mp.getDuration() + "ms)");
    }

    @Override
    public boolean onError(MediaPlayer mp, int what, int extra) {
        Log.e(TAG, owner + ": MediaPlayer error what=" + what + " extra=" + extra);
        return true;  // handled; suppresses the completion callback
    }

    void release() {
        if (player != null) {
            try {
                player.release();
            } catch (Exception e) {
                Log.w(TAG, owner + ": release failed", e);
            }
            player = null;
        }
    }
}
