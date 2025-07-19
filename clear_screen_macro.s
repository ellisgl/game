; clear_screen_macro.inc
; Macro to clear the display / NES nametable / PPU VRAM
.macro ClearScreen
    ; Make sure to use .local to avoid conflicts with other macros, or main code.
    .local clear_loop

    ; RAM contents on boot cannot be trusted (visual artifacts)
    ; Clear nametable 0; It is at PPU VRAM's address $2000
    ; CPU registers size is 1 byte, but addresses size is 2 bytes
    LDA PPUSTATUS   ; Clear w register,
                    ; so the next write to PPUADDR is taken as the VRAM's address high byte.
                    ; First, we need the high byte of $2000
                    ;                                  ^^
    LDA #$20

    STA PPUADDR     ; (this also sets the w register,
                    ; so the next write to PPUADDR is taken as the VRAM's address low byte)
                    ; Then, the low byte of  $2000
                    ;                           ^^
    LDA #$00
    STA PPUADDR     ; (this also clears the w register)
    LDX #0
    LDY #4
    clear_loop:
        LDA #$00
        STA PPUDATA
        INX
        BNE clear_loop
        DEY
        BNE clear_loop
.endmacro
