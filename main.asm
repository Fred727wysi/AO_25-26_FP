; ============================================================================
; EMPLOYEE RECORD TRACKER - NASM Assembly (Windows x86)
; ============================================================================
; A professional CRUD-based employee management system
; Features: Add, Delete, Search, Display employees with Name and Position
; Maximum capacity: 50 employees
; ============================================================================

bits 32

; ============================================================================
; EXTERNAL FUNCTIONS (Windows API)
; ============================================================================
extern _GetStdHandle@4
extern _WriteConsoleA@20
extern _ReadConsoleA@20
extern _ExitProcess@4

; ============================================================================
; DATA SECTION - Constants and Variables
; ============================================================================
section .data
    ; Constants
    MAX_EMPLOYEES equ 50
    NAME_SIZE equ 20
    POSITION_SIZE equ 20
    
    ; System handles
    STD_OUTPUT_HANDLE equ -11
    STD_INPUT_HANDLE equ -10
    
    ; Employee storage arrays
    employee_names: times MAX_EMPLOYEES * NAME_SIZE db 0
    employee_positions: times MAX_EMPLOYEES * POSITION_SIZE db 0
    employee_count: dd 0
    
    ; Menu and UI strings
    menu_header: db 10, 13, '========================================', 10, 13
                 db '   EMPLOYEE RECORD TRACKER SYSTEM', 10, 13
                 db '========================================', 10, 13, 0
    menu_header_len equ $ - menu_header
    
    menu_options: db '1. Add Employee', 10, 13
                  db '2. Delete Employee by Name', 10, 13
                  db '3. Delete Employee by Position', 10, 13
                  db '4. Search Employee by Name', 10, 13
                  db '5. Search Employee by Position', 10, 13
                  db '6. Display All Employees', 10, 13
                  db '7. Display Employees by Position', 10, 13
                  db '8. Exit Program', 10, 13
                  db 'Enter choice: ', 0
    menu_options_len equ $ - menu_options
    
    ; Input prompts
    prompt_name: db 'Enter Name (max 20 chars): ', 0
    prompt_name_len equ $ - prompt_name
    
    prompt_position: db 'Enter Position (max 20 chars): ', 0
    prompt_position_len equ $ - prompt_position
    
    prompt_search_name: db 'Enter Name to search: ', 0
    prompt_search_name_len equ $ - prompt_search_name
    
    prompt_search_pos: db 'Enter Position to search: ', 0
    prompt_search_pos_len equ $ - prompt_search_pos
    
    prompt_delete_name: db 'Enter Name to delete: ', 0
    prompt_delete_name_len equ $ - prompt_delete_name
    
    prompt_delete_pos: db 'Enter Position to delete: ', 0
    prompt_delete_pos_len equ $ - prompt_delete_pos
    
    prompt_group_pos: db 'Enter Position to group by: ', 0
    prompt_group_pos_len equ $ - prompt_group_pos
    
    ; Status messages
    msg_added: db 'Employee added successfully!', 10, 13, 0
    msg_added_len equ $ - msg_added
    
    msg_full: db 'ERROR: Maximum employee limit reached (50)', 10, 13, 0
    msg_full_len equ $ - msg_full
    
    msg_deleted: db 'Record deleted successfully!', 10, 13, 0
    msg_deleted_len equ $ - msg_deleted
    
    msg_not_found: db 'Record not found.', 10, 13, 0
    msg_not_found_len equ $ - msg_not_found
    
    msg_empty: db 'No employees in database.', 10, 13, 0
    msg_empty_len equ $ - msg_empty
    
    msg_invalid: db 'Invalid choice. Please try again.', 10, 13, 0
    msg_invalid_len equ $ - msg_invalid
    
    msg_exit: db 'Exiting program. Goodbye!', 10, 13, 0
    msg_exit_len equ $ - msg_exit
    
    ; Display formatting
    display_header: db 10, 13, '--- Employee List ---', 10, 13, 0
    display_header_len equ $ - display_header
    
    display_name_label: db 'Name: ', 0
    display_name_label_len equ $ - display_name_label
    
    display_pos_label: db '  Position: ', 0
    display_pos_label_len equ $ - display_pos_label
    
    newline: db 10, 13, 0
    newline_len equ $ - newline
    
    separator: db '----------------------------------------', 10, 13, 0
    separator_len equ $ - separator

; ============================================================================
; BSS SECTION - Uninitialized Data
; ============================================================================
section .bss
    input_buffer: resb 64
    bytes_read: resd 1
    stdout_handle: resd 1
    stdin_handle: resd 1
    temp_name: resb NAME_SIZE
    temp_position: resb POSITION_SIZE
    choice: resb 4

; ============================================================================
; CODE SECTION
; ============================================================================
section .text
global _start

; ============================================================================
; MAIN PROGRAM ENTRY POINT
; ============================================================================
_start:
    ; Get standard handles
    push STD_OUTPUT_HANDLE
    call _GetStdHandle@4
    mov [stdout_handle], eax
    
    push STD_INPUT_HANDLE
    call _GetStdHandle@4
    mov [stdin_handle], eax

; ============================================================================
; MAIN MENU LOOP
; ============================================================================
main_loop:
    ; Display menu
    call display_menu
    
    ; Get user choice
    call read_choice
    
    ; Process choice
    mov al, [choice]
    sub al, '0'
    
    cmp al, 1
    je option_add
    cmp al, 2
    je option_delete_name
    cmp al, 3
    je option_delete_position
    cmp al, 4
    je option_search_name
    cmp al, 5
    je option_search_position
    cmp al, 6
    je option_display_all
    cmp al, 7
    je option_display_grouped
    cmp al, 8
    je option_exit
    
    ; Invalid choice
    push msg_invalid_len
    push msg_invalid
    call print_string
    jmp main_loop

; ============================================================================
; MENU OPTIONS HANDLERS
; ============================================================================
option_add:
    call add_employee
    jmp main_loop

option_delete_name:
    call delete_by_name
    jmp main_loop

option_delete_position:
    call delete_by_position
    jmp main_loop

option_search_name:
    call search_by_name
    jmp main_loop

option_search_position:
    call search_by_position
    jmp main_loop

option_display_all:
    call display_all_employees
    jmp main_loop

option_display_grouped:
    call display_by_position
    jmp main_loop

option_exit:
    push msg_exit_len
    push msg_exit
    call print_string
    
    push 0
    call _ExitProcess@4

; ============================================================================
; PROCEDURE: display_menu
; Displays the main menu interface
; ============================================================================
display_menu:
    push ebp
    mov ebp, esp
    
    push menu_header_len
    push menu_header
    call print_string
    
    push menu_options_len
    push menu_options
    call print_string
    
    pop ebp
    ret

; ============================================================================
; PROCEDURE: read_choice
; Reads user menu choice from console
; ============================================================================
read_choice:
    push ebp
    mov ebp, esp
    
    push 0
    push bytes_read
    push 4
    push choice
    push dword [stdin_handle]
    call _ReadConsoleA@20
    
    pop ebp
    ret

; ============================================================================
; PROCEDURE: add_employee
; Adds a new employee to the database
; ============================================================================
add_employee:
    push ebp
    mov ebp, esp
    
    ; Check if database is full
    mov eax, [employee_count]
    cmp eax, MAX_EMPLOYEES
    jge .full
    
    ; Prompt for name
    push prompt_name_len
    push prompt_name
    call print_string
    
    push NAME_SIZE
    push temp_name
    call read_input
    
    ; Prompt for position
    push prompt_position_len
    push prompt_position
    call print_string
    
    push POSITION_SIZE
    push temp_position
    call read_input
    
    ; Calculate storage offset
    mov eax, [employee_count]
    mov ebx, NAME_SIZE
    mul ebx                      ; EAX = offset for name
    
    ; Copy name to storage
    mov esi, temp_name
    lea edi, [employee_names + eax]
    mov ecx, NAME_SIZE
    rep movsb
    
    ; Calculate position offset
    mov eax, [employee_count]
    mov ebx, POSITION_SIZE
    mul ebx                      ; EAX = offset for position
    
    ; Copy position to storage
    mov esi, temp_position
    lea edi, [employee_positions + eax]
    mov ecx, POSITION_SIZE
    rep movsb
    
    ; Increment employee count
    inc dword [employee_count]
    
    ; Success message
    push msg_added_len
    push msg_added
    call print_string
    
    jmp .done

.full:
    push msg_full_len
    push msg_full
    call print_string

.done:
    pop ebp
    ret

; ============================================================================
; PROCEDURE: delete_by_name
; Deletes employee record(s) by name
; ============================================================================
delete_by_name:
    push ebp
    mov ebp, esp
    sub esp, 4                   ; Local variable for found flag
    
    ; Prompt for name
    push prompt_delete_name_len
    push prompt_delete_name
    call print_string
    
    push NAME_SIZE
    push temp_name
    call read_input
    
    mov dword [ebp-4], 0         ; found = false
    xor esi, esi                 ; index = 0

.search_loop:
    cmp esi, [employee_count]
    jge .check_found
    
    ; Calculate offset
    mov eax, esi
    mov ebx, NAME_SIZE
    mul ebx
    
    ; Compare name
    lea edi, [employee_names + eax]
    mov ecx, NAME_SIZE
    push esi
    push edi
    push ecx
    push temp_name
    call string_compare
    
    cmp eax, 1
    jne .next
    
    ; Found match - delete it
    mov dword [ebp-4], 1
    push esi
    call shift_records_up
    jmp .search_loop             ; Don't increment, check same index again

.next:
    inc esi
    jmp .search_loop

.check_found:
    cmp dword [ebp-4], 0
    je .not_found
    
    push msg_deleted_len
    push msg_deleted
    call print_string
    jmp .done

.not_found:
    push msg_not_found_len
    push msg_not_found
    call print_string

.done:
    add esp, 4
    pop ebp
    ret

; ============================================================================
; PROCEDURE: delete_by_position
; Deletes employee record(s) by position
; ============================================================================
delete_by_position:
    push ebp
    mov ebp, esp
    sub esp, 4                   ; Local variable for found flag
    
    ; Prompt for position
    push prompt_delete_pos_len
    push prompt_delete_pos
    call print_string
    
    push POSITION_SIZE
    push temp_position
    call read_input
    
    mov dword [ebp-4], 0         ; found = false
    xor esi, esi                 ; index = 0

.search_loop:
    cmp esi, [employee_count]
    jge .check_found
    
    ; Calculate offset
    mov eax, esi
    mov ebx, POSITION_SIZE
    mul ebx
    
    ; Compare position
    lea edi, [employee_positions + eax]
    mov ecx, POSITION_SIZE
    push esi
    push edi
    push ecx
    push temp_position
    call string_compare
    
    cmp eax, 1
    jne .next
    
    ; Found match - delete it
    mov dword [ebp-4], 1
    push esi
    call shift_records_up
    jmp .search_loop             ; Don't increment

.next:
    inc esi
    jmp .search_loop

.check_found:
    cmp dword [ebp-4], 0
    je .not_found
    
    push msg_deleted_len
    push msg_deleted
    call print_string
    jmp .done

.not_found:
    push msg_not_found_len
    push msg_not_found
    call print_string

.done:
    add esp, 4
    pop ebp
    ret

; ============================================================================
; PROCEDURE: search_by_name
; Searches and displays employees by name
; ============================================================================
search_by_name:
    push ebp
    mov ebp, esp
    sub esp, 4                   ; found flag
    
    push prompt_search_name_len
    push prompt_search_name
    call print_string
    
    push NAME_SIZE
    push temp_name
    call read_input
    
    push newline_len
    push newline
    call print_string
    
    mov dword [ebp-4], 0
    xor esi, esi

.loop:
    cmp esi, [employee_count]
    jge .check_found
    
    ; Compare name
    mov eax, esi
    mov ebx, NAME_SIZE
    mul ebx
    lea edi, [employee_names + eax]
    
    push esi
    push edi
    push NAME_SIZE
    push temp_name
    call string_compare
    
    cmp eax, 1
    jne .next
    
    mov dword [ebp-4], 1
    pop esi
    push esi
    call display_employee_record
    jmp .continue

.next:
    pop esi

.continue:
    inc esi
    jmp .loop

.check_found:
    cmp dword [ebp-4], 0
    jne .done
    
    push msg_not_found_len
    push msg_not_found
    call print_string

.done:
    add esp, 4
    pop ebp
    ret

; ============================================================================
; PROCEDURE: search_by_position
; Searches and displays employees by position
; ============================================================================
search_by_position:
    push ebp
    mov ebp, esp
    sub esp, 4
    
    push prompt_search_pos_len
    push prompt_search_pos
    call print_string
    
    push POSITION_SIZE
    push temp_position
    call read_input
    
    push newline_len
    push newline
    call print_string
    
    mov dword [ebp-4], 0
    xor esi, esi

.loop:
    cmp esi, [employee_count]
    jge .check_found
    
    mov eax, esi
    mov ebx, POSITION_SIZE
    mul ebx
    lea edi, [employee_positions + eax]
    
    push esi
    push edi
    push POSITION_SIZE
    push temp_position
    call string_compare
    
    cmp eax, 1
    jne .next
    
    mov dword [ebp-4], 1
    pop esi
    push esi
    call display_employee_record
    jmp .continue

.next:
    pop esi

.continue:
    inc esi
    jmp .loop

.check_found:
    cmp dword [ebp-4], 0
    jne .done
    
    push msg_not_found_len
    push msg_not_found
    call print_string

.done:
    add esp, 4
    pop ebp
    ret

; ============================================================================
; PROCEDURE: display_all_employees
; Displays all employee records
; ============================================================================
display_all_employees:
    push ebp
    mov ebp, esp
    
    cmp dword [employee_count], 0
    je .empty
    
    push display_header_len
    push display_header
    call print_string
    
    xor esi, esi

.loop:
    cmp esi, [employee_count]
    jge .done
    
    push esi
    call display_employee_record
    
    inc esi
    jmp .loop

.empty:
    push msg_empty_len
    push msg_empty
    call print_string

.done:
    push separator_len
    push separator
    call print_string
    
    pop ebp
    ret

; ============================================================================
; PROCEDURE: display_by_position
; Displays employees grouped by position
; ============================================================================
display_by_position:
    push ebp
    mov ebp, esp
    sub esp, 4
    
    cmp dword [employee_count], 0
    je .empty
    
    push prompt_group_pos_len
    push prompt_group_pos
    call print_string
    
    push POSITION_SIZE
    push temp_position
    call read_input
    
    push newline_len
    push newline
    call print_string
    
    mov dword [ebp-4], 0
    xor esi, esi

.loop:
    cmp esi, [employee_count]
    jge .check_found
    
    mov eax, esi
    mov ebx, POSITION_SIZE
    mul ebx
    lea edi, [employee_positions + eax]
    
    push esi
    push edi
    push POSITION_SIZE
    push temp_position
    call string_compare
    
    cmp eax, 1
    jne .next
    
    mov dword [ebp-4], 1
    pop esi
    push esi
    call display_employee_record
    jmp .continue

.next:
    pop esi

.continue:
    inc esi
    jmp .loop

.check_found:
    cmp dword [ebp-4], 0
    jne .done
    
    push msg_not_found_len
    push msg_not_found
    call print_string
    jmp .finish

.empty:
    push msg_empty_len
    push msg_empty
    call print_string
    jmp .finish

.done:
    push separator_len
    push separator
    call print_string

.finish:
    add esp, 4
    pop ebp
    ret

; ============================================================================
; PROCEDURE: display_employee_record
; Displays a single employee record
; Parameters: [ebp+8] = employee index
; ============================================================================
display_employee_record:
    push ebp
    mov ebp, esp
    push esi
    push edi
    
    mov esi, [ebp+8]             ; Get index
    
    ; Display "Name: "
    push display_name_label_len
    push display_name_label
    call print_string
    
    ; Display name
    mov eax, esi
    mov ebx, NAME_SIZE
    mul ebx
    lea edi, [employee_names + eax]
    
    push NAME_SIZE
    push edi
    call print_string
    
    ; Display "  Position: "
    push display_pos_label_len
    push display_pos_label
    call print_string
    
    ; Display position
    mov eax, esi
    mov ebx, POSITION_SIZE
    mul ebx
    lea edi, [employee_positions + eax]
    
    push POSITION_SIZE
    push edi
    call print_string
    
    ; Newline
    push newline_len
    push newline
    call print_string
    
    pop edi
    pop esi
    pop ebp
    ret

; ============================================================================
; PROCEDURE: shift_records_up
; Shifts all records up from given index (used in deletion)
; Parameters: [ebp+8] = index to delete
; ============================================================================
shift_records_up:
    push ebp
    mov ebp, esp
    push esi
    push edi
    
    mov esi, [ebp+8]             ; Start index

.loop:
    mov eax, esi
    inc eax
    cmp eax, [employee_count]
    jge .finish
    
    ; Copy name from next record
    mov eax, esi
    mov ebx, NAME_SIZE
    mul ebx
    lea edi, [employee_names + eax]
    
    mov eax, esi
    inc eax
    mov ebx, NAME_SIZE
    mul ebx
    lea esi, [employee_names + eax]
    
    mov ecx, NAME_SIZE
    rep movsb
    
    ; Copy position from next record
    mov eax, [ebp+8]
    mov esi, eax
    mov ebx, POSITION_SIZE
    mul ebx
    lea edi, [employee_positions + eax]
    
    mov eax, esi
    inc eax
    mov ebx, POSITION_SIZE
    mul ebx
    lea esi, [employee_positions + eax]
    
    mov ecx, POSITION_SIZE
    rep movsb
    
    mov esi, [ebp+8]
    inc esi
    mov [ebp+8], esi
    jmp .loop

.finish:
    dec dword [employee_count]
    
    pop edi
    pop esi
    pop ebp
    ret

; ============================================================================
; PROCEDURE: string_compare
; Compares two strings (null-terminated or size-limited)
; Parameters: [ebp+8]=str1, [ebp+12]=max_len, [ebp+16]=str2
; Returns: EAX=1 if equal, 0 if not equal
; ============================================================================
string_compare:
    push ebp
    mov ebp, esp
    push esi
    push edi
    push ecx
    
    mov esi, [ebp+8]             ; str1
    mov edi, [ebp+16]            ; str2
    mov ecx, [ebp+12]            ; max length

.loop:
    cmp ecx, 0
    je .equal
    
    mov al, [esi]
    mov bl, [edi]
    
    ; Check for null terminator or newline
    cmp al, 0
    je .check_bl_null
    cmp al, 10
    je .check_bl_null
    cmp al, 13
    je .check_bl_null
    
    cmp bl, 0
    je .not_equal
    cmp bl, 10
    je .not_equal
    cmp bl, 13
    je .not_equal
    
    cmp al, bl
    jne .not_equal
    
    inc esi
    inc edi
    dec ecx
    jmp .loop

.check_bl_null:
    cmp bl, 0
    je .equal
    cmp bl, 10
    je .equal
    cmp bl, 13
    je .equal
    jmp .not_equal

.equal:
    mov eax, 1
    jmp .done

.not_equal:
    mov eax, 0

.done:
    pop ecx
    pop edi
    pop esi
    pop ebp
    ret

; ============================================================================
; PROCEDURE: read_input
; Reads input from console into buffer
; Parameters: [ebp+8]=buffer, [ebp+12]=max_size
; ============================================================================
read_input:
    push ebp
    mov ebp, esp
    push esi
    push edi
    
    ; Clear buffer
    mov edi, [ebp+8]
    mov ecx, [ebp+12]
    xor al, al
    rep stosb
    
    ; Read from console
    push 0
    push bytes_read
    push 64
    push input_buffer
    push dword [stdin_handle]
    call _ReadConsoleA@20
    
    ; Copy to destination buffer
    mov esi, input_buffer
    mov edi, [ebp+8]
    mov ecx, [ebp+12]
    
.copy_loop:
    lodsb
    cmp al, 13                   ; Carriage return
    je .done
    cmp al, 10                   ; Line feed
    je .done
    cmp al, 0
    je .done
    stosb
    loop .copy_loop

.done:
    ; Null-terminate
    mov byte [edi], 0
    
    pop edi
    pop esi
    pop ebp
    ret

; ============================================================================
; PROCEDURE: print_string
; Prints a string to console
; Parameters: [ebp+8]=string, [ebp+12]=length
; ============================================================================
print_string:
    push ebp
    mov ebp, esp
    push esi
    
    mov esi, [ebp+8]
    mov ecx, [ebp+12]
    
    ; Calculate actual length if 0-terminated
    cmp ecx, 0
    jne .write
    
    mov edi, esi
    xor eax, eax
    mov ecx, -1
    repne scasb
    not ecx
    dec ecx

.write:
    push 0
    push bytes_read
    push ecx
    push esi
    push dword [stdout_handle]
    call _WriteConsoleA@20
    
    pop esi
    pop ebp
    ret
