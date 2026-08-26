class_name AndroidFeedback
extends RefCounted


static func mission_ready(message: String) -> bool:
	if OS.get_name() != "Android" or not Engine.has_singleton("AndroidRuntime"):
		return false
	var runtime = Engine.get_singleton("AndroidRuntime")
	var activity = runtime.getActivity()
	var context = runtime.getApplicationContext()
	if activity == null or context == null:
		return false
	var feedback := func():
		var toast_class = JavaClassWrapper.wrap("android.widget.Toast")
		toast_class.makeText(activity, message, toast_class.LENGTH_LONG).show()
		var vibrator = context.getSystemService("vibrator")
		if vibrator == null or not vibrator.hasVibrator():
			return
		var version_class = JavaClassWrapper.wrap("android.os.Build$VERSION")
		if int(version_class.SDK_INT) >= 26:
			var effect_class = JavaClassWrapper.wrap("android.os.VibrationEffect")
			vibrator.vibrate(effect_class.createOneShot(180, effect_class.DEFAULT_AMPLITUDE))
		else:
			vibrator.vibrate(180)
	activity.runOnUiThread(runtime.createRunnableFromGodotCallable(feedback))
	return true
