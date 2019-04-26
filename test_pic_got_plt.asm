cpu ia64
bits 64
default rel

;typedef struct {
;	godot_bool in_editor;
;	uint64_t core_api_hash;
;	uint64_t editor_api_hash;
;	uint64_t no_api_hash;
;	void (*report_version_mismatch)(const godot_object *p_library, const char *p_what, godot_gdnative_api_version p_want, godot_gdnative_api_version p_have);
;	void (*report_loading_error)(const godot_object *p_library, const char *p_what);
;	godot_object *gd_native_library; // pointer to GDNativeLibrary that is being initialized
;	const struct godot_gdnative_core_api_struct *api_struct;
;	const godot_string *active_library_path;
;} godot_gdnative_init_options;
; assuming 8-byte alignment
gdnopt_in_editor				dd	0x00
gdnopt_core_api_hash				dd	0x08
gdnopt_editor_api_hash				dd	0x10
gdnopt_no_api_hash				dd	0x18
gdnopt_pf_report_version_mismatch		dd	0x20
gdnopt_pf_report_loading_error			dd	0x28
gdnopt_p_gd_native_library			dd	0x30
gdnopt_p_api_struct				dd	0x38
gdnopt_p_active_library_path			dd	0x40

section .text

api			dq	0
api_nativescript	dq	0

global dllMain
dllMain:
	; dllMain is a win64 thing so the three args,
	; should they be needed, will be in rcx,rdx,r8
	xor		eax,eax
	ret

; win64 param order: (rcx,rdx,r8,r9,... rest via stack...)
;         mungeable: rcx,rdx,r8,r9,rax,r10,r11
;      return value: int/ptr via RAX
; linux param order: (rdi,rsi,rdx,rcx,r8,r9,... rest via stack...)
;         mungeable: rdi,rsi,rdx,rcx,r8,r9,rax,r10,r11
;      return value: int/ptr via RAX,RDX

global godot_gdnative_init
godot_gdnative_init:

	;   win64: godot_gdnative_init(godot_gdnative_options *p_options_volarg@rcx)
	;   lin64: godot_gdnative_init(godot_gdnative_options *p_options_volarg@rdi)
	; returns: void

	; prologue (rsp mod 16=8 due to return address)
	push	r15
	push	r14
	push	r13
	push	r12			; save to allow use as localvars (save pairs to stay alignment-neutral)
	push 	rbp			; rsp mod 16=0 (now aligned)
	mov	rbp,rsp
	; allocate a minimum of 32 bytes (4 registers) in multiples of 16
	sub	rsp,0x40
	
	; var p_options@r15=p_options_volarg@rcx (@rdi in linux64)
	mov	r15,rcx
	; api=p_options->api_struct
	mov	rax,[abs r15+gdnopt_p_api_struct]
	mov	[rel api],rax

	; epilogue
	leave
	pop	r12
	pop	r13
	pop	r14
	pop	r15
	ret

global godot_gdnative_terminate
godot_gdnative_terminate:
	;   win64: godot_gdnative_terminate(godot_gdnative_terminate_options *p_options_volarg@rcx)
	;   lin64: godot_gdnative_terminate(godot_gdnative_terminate_options *p_options_volarg@rdi)
	; returns: void
	xor	eax,eax
	mov [rel api],rax
	mov	[rel api_nativescript],rax
	ret

global godot_nativescript_init
	;   win64: godot_nativescript_init(void *p_handle@rcx)
	;   lin64: godot_nativescript_init(void *p_handle@rdi)
	; returns: void
	
	; nothing for now
	ret
