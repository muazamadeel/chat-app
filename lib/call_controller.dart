import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

class CallController extends GetxController {
  static CallController get to => Get.find();

  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  bool ismute = false;
  bool isRenderersInitialized = false;

  // ✅ Proper async initialization
  Future<void> initilizeRTcREneders() async {
    try {
      print('🎥 Initializing video renderers...');

      // Avoid re-initialization
      if (isRenderersInitialized &&
          localRenderer.textureId != null &&
          remoteRenderer.textureId != null) {
        print('⚠️ Renderers already initialized');
        return;
      }

      // Initialize local renderer
      await localRenderer.initialize();
      print(
        '✅ Local renderer initialized (textureId: ${localRenderer.textureId})',
      );

      // Initialize remote renderer
      await remoteRenderer.initialize();
      print(
        '✅ Remote renderer initialized (textureId: ${remoteRenderer.textureId})',
      );

      isRenderersInitialized = true;
      update();
    } catch (e) {
      print('❌ Error initializing renderers: $e');
      isRenderersInitialized = false;
      rethrow;
    }
  }

  // ✅ CRITICAL: Proper disposal sequence
  Future<void> disposeRenderers() async {
    try {
      print('🧹 Starting renderer disposal...');

      // ✅ Step 1: Clear srcObject and stop tracks for LOCAL renderer
      if (localRenderer.srcObject != null) {
        print('🛑 Stopping local tracks...');
        try {
          final tracks = localRenderer.srcObject!.getTracks();
          for (var track in tracks) {
            try {
              await track.stop();
              print('✅ Stopped track: ${track.kind}');
            } catch (e) {
              print('⚠️ Error stopping track: $e');
            }
          }
          // ✅ CRITICAL: Set srcObject to null
          localRenderer.srcObject = null;
          print('✅ Local srcObject cleared');
        } catch (e) {
          print('⚠️ Error clearing local srcObject: $e');
        }
      }

      // ✅ Step 2: Clear srcObject and stop tracks for REMOTE renderer
      if (remoteRenderer.srcObject != null) {
        print('🛑 Stopping remote tracks...');
        try {
          final tracks = remoteRenderer.srcObject!.getTracks();
          for (var track in tracks) {
            try {
              await track.stop();
              print('✅ Stopped track: ${track.kind}');
            } catch (e) {
              print('⚠️ Error stopping track: $e');
            }
          }
          // ✅ CRITICAL: Set srcObject to null
          remoteRenderer.srcObject = null;
          print('✅ Remote srcObject cleared');
        } catch (e) {
          print('⚠️ Error clearing remote srcObject: $e');
        }
      }

      // ✅ Step 3: Small delay to ensure cleanup completes
      await Future.delayed(const Duration(milliseconds: 100));

      // ✅ Step 4: Dispose LOCAL renderer
      if (localRenderer.textureId != null) {
        try {
          await localRenderer.dispose();
          print('✅ Local renderer disposed');
        } catch (e) {
          print('⚠️ Error disposing local renderer: $e');
          // Try to force dispose
          try {
            localRenderer.srcObject = null;
            await Future.delayed(const Duration(milliseconds: 50));
            await localRenderer.dispose();
          } catch (e2) {
            print('❌ Force dispose failed: $e2');
          }
        }
      }

      // ✅ Step 5: Dispose REMOTE renderer
      if (remoteRenderer.textureId != null) {
        try {
          await remoteRenderer.dispose();
          print('✅ Remote renderer disposed');
        } catch (e) {
          print('⚠️ Error disposing remote renderer: $e');
          // Try to force dispose
          try {
            remoteRenderer.srcObject = null;
            await Future.delayed(const Duration(milliseconds: 50));
            await remoteRenderer.dispose();
          } catch (e2) {
            print('❌ Force dispose failed: $e2');
          }
        }
      }

      // ✅ Step 6: Recreate fresh renderers for next call
      localRenderer = RTCVideoRenderer();
      remoteRenderer = RTCVideoRenderer();
      isRenderersInitialized = false;

      print('✅ Renderers disposed and recreated');
      update();
    } catch (e) {
      print('❌ Critical error in disposeRenderers: $e');

      // ✅ Force reset everything
      try {
        localRenderer.srcObject = null;
        remoteRenderer.srcObject = null;
      } catch (_) {}

      localRenderer = RTCVideoRenderer();
      remoteRenderer = RTCVideoRenderer();
      isRenderersInitialized = false;
      update();
    }
  }

  // ✅ Change mute status
  void changeMuteStatus(bool value) {
    ismute = value;
    update();
  }

  // ✅ Safe cleanup of specific renderer
  Future<void> cleanupRenderer(RTCVideoRenderer renderer) async {
    try {
      if (renderer.srcObject != null) {
        renderer.srcObject!.getTracks().forEach((track) {
          track.stop();
        });
        renderer.srcObject = null;
      }

      await Future.delayed(const Duration(milliseconds: 50));

      if (renderer.textureId != null) {
        await renderer.dispose();
      }
    } catch (e) {
      print('Error cleaning up renderer: $e');
    }
  }

  @override
  void onClose() {
    print('🔴 CallController closing...');
    // Don't dispose here - let screens handle it properly
    super.onClose();
  }
}
