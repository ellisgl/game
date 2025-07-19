.macro Print start_hi, start_lo, text, attr
    // .local helps localize variables to this macro,
    // avoiding conflicts with other macros or main code.
    .local print_msg
    .local done_msg
    LDA #start_hi
    STA temp_hi
    LDA #start_lo
    STA temp_lo
    LDA temp_hi
    STA PPUADDR
    LDA temp_lo
    STA PPUADDR
    LDX #0
    print_msg:
        LDA text,X
        BEQ done_msg
        STA PPUDATA
        INX
        JMP print_msg
    done_msg:
.endmacro