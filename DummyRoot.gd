extends Node

signal GDGD_INIT

func _ready():
	print("Dummy root node")
	var gdgd=get_node("GDGD")
	gdgd.connect("GDGD_ERROR",self,"on_gdgd_error")
	emit_signal("GDGD_INIT")
	yield(gdgd,"GDGD_READY")
	print("GDGD completed.")

func on_gdgd_error(failure):
	var dlg=get_node("ErrorMessage")
	var msg=dlg.get_node("msg")
	var btn=dlg.get_node("cancel")
	msg.text=str(failure.code)+": "+failure.reason
	dlg.show()
	yield(btn,"pressed")
	dlg.hide()
	get_tree().quit()
