; Macro to draw a bordered box
; Example usage: DrawBoarder $20, $41, 25, $2A, $00 ; Draw box with '*' tile, default attribute
.macro DrawBoarder start_hi, start_lo, rows, tile, attr
    ; .local helps localize variables to this macro,
    ; avoiding conflicts with other macros or main code.
    .local box_loop
    .local draw_top
    .local top_inner
    .local draw_bottom
    .local bottom_inner
    .local next_row
    .local no_row_carry2
    LDA #start_hi
    STA temp_hi
    LDA #start_lo
    STA temp_lo
    LDY #rows
box_loop:
        LDA temp_hi
        STA PPUADDR
        LDA temp_lo
        STA PPUADDR
        CPY #rows
        BEQ draw_top
        CPY #1
        BEQ draw_bottom
        ; Draw vertical sides
        LDA #tile
        STA PPUDATA
        LDA temp_lo
        CLC
        ADC #$1D
        TAX
        LDA temp_hi
        STA PPUADDR
        TXA
        STA PPUADDR
        LDA #tile
        STA PPUDATA
        JMP next_row
    draw_top:
        LDX #$00
    top_inner:
            LDA #tile
            STA PPUDATA
            INX
            CPX #$1E
            BNE top_inner
        JMP next_row
    draw_bottom:
        LDX #$00
    bottom_inner:
            LDA temp_hi
            STA PPUADDR
            TXA
            CLC
            ADC temp_lo
            STA PPUADDR
            LDA #tile
            STA PPUDATA
            INX
            CPX #$1E
            BNE bottom_inner
        JMP next_row
    next_row:
        LDA temp_lo
        CLC
        ADC #$20
        STA temp_lo
        BCC no_row_carry2
        INC temp_hi
    no_row_carry2:
        DEY
        BNE box_loop
.endmacro
