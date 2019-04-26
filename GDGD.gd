extends Node
class_name GDGD

export var blacklist:Array=[]

#
#  GD-to-GD GDNative transpiler
#  NASM is used mainly because it has portable distributions and a liberal
#  BSD 2-clause license.  No C/C++ compiler and runtime libraries will be
#  used.  Actually, since we're making GDNative's one could say Godot is the
#  runtime library.
#
#  To use GDGD simply drop the contents of the GDGD distribution (the nasm
#  folder, GDGD.tscn, GDGD.tscn) into the project top-level folder, 
#  and have the root node emit GDGD_INIT as a signal.  The transpiler
#  will do its thing and emit GDGD_READY when done.
#
#  There is a blacklist export on the scene node for which any .gd's that
#  should not be processed into a GDNative may be placed in the form of
#  res:// based filenames (eg: res://bug_infested_script.gd)
#
#  In Windows we make DLL's, in linux SO's
#  TODO:	Mac?  Portables?
#  We'll start with Windows first.
#
#  TODO:	We may also want an editor plugin that may seamlessly
#       	reassemble GDNatives of any modified sources prior to running
#			a project as compiling at runtime most likely requires a restart
#			of the game, or at the very least, a reload of the root scene.
#       	run SHA256 on .gd's encountered in the project, store the hashes
#			in user:// using a mangled filename format that uniquely names
#			this hash file so we don't collide with a downstream project's
#			user:// contents.  We want to reassemble only .gd's that have
#			been altered.
#

#  EBNF
const TK_REQUIRE	= 1						# Token must occur at least once
const TK_MULTI		= 2						# Token may occur more than once
const TK_REGEX		= 4						# 1==Token is a regex
const TK_OPT		= 0						# ? (zero or one)
const TK_ONCE		= TK_REQUIRE			# unadorned (one)
const TK_STAR		= TK_MULTI				# * (zero or more)
const TK_PLUS		= TK_MULTI|TK_REQUIRE	# + (one or more)

# EBNF language for lexer/parse
# dict key is token name
# each pair is [op, token]
# op is the EBNF operator
# token is the token which is either a string
# referencing another key (token) or a RegExp
var GDLang={
	"gd":			[[TK_ONCE,"extend_spec"]],
	"extend":		[[TK_ONCE|TK_REGEX,"extends"]]
}

signal GDGD_INIT
signal GDGD_READY
signal GDGD_ERROR

const ERR_NOT_X86:=1
const ERRORS={
	ERR_NOT_X86				:	"NASM only supports x86 architectures."
}

onready var root=get_node("/root").get_child(0)

var host={
	"arch"		:	OS.get_name(),
	"64-bit"	:	OS.has_feature("64"),
	"x86"		:	OS.has_feature("x86") or OS.has_feature("x86_64"),
	"x86_32"	:	OS.has_feature("x86"),
	"x86_64"	:	OS.has_feature("x86_64"),
}

var gdgd_run:=false
var gdgd_done:=false
var gdgd_error:=false
var error_details={"code":0,"reason":"Default error code."}

func _ready():
	root.connect("GDGD_INIT",self,"GDGD_Start")

	if not host.x86:
		gdgd_error=true
		error_details.code=ERR_NOT_X86
		error_details.reason=ERRORS[ERR_NOT_X86]

	if root==self:
		connect("GDGD_ERROR",self,"on_gdgd_error")
		emit_signal("GDGD_INIT")
		yield(self,"GDGD_READY")
		print("GDGD reported done.")

func on_gdgd_error(failure):
	print("GDGD reported error ",failure.code,": ",failure.reason)

func GDGD_Start():
	gdgd_run=true

func _process(delta):
	if gdgd_run:
		if gdgd_done:
			gdgd_run=false
			emit_signal("GDGD_READY")
		if gdgd_error:
			gdgd_run=false
			emit_signal("GDGD_ERROR",error_details)
	if gdgd_run:
		print("GDGD working...")
		gdgd_done=true

