extends SceneTree

const AndroidFeedbackScript = preload("res://scripts/android_feedback.gd")


func _init() -> void:
	if OS.get_name() == "Android":
		print("PASS: Android feedback boundary is available to the runtime build")
		quit(0)
		return
	if AndroidFeedbackScript.mission_ready("Target located"):
		printerr("FAIL: non-Android runtime claimed native mission feedback")
		quit(1)
		return
	print("PASS: Android feedback remains a safe platform boundary")
	quit(0)
