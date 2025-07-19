; TheGame.s --- CA65 assembler source file
; It display's a start screen that uses text from the CHR ROM, nothing else.
; Pressing start at the start screen will go on to the next screen, which is only text.

; Memory-Mapped Input/Output (MMIO) registers
; Basically we are created variables that map to the PPU's registers.
PPUCTRL   = $2000
PPUMASK   = $2001
PPUSTATUS = $2002
PPUSCROLL = $2005
PPUADDR   = $2006
PPUDATA   = $2007

; Every NES cartridge has a header.
; This one is iNES 1.0 format, using the NROM mapper.
; Wonder if I can go smaller?
; https://www.nesdev.org/wiki/Nintendo_header
.segment "HEADER"
    .byte "NES", $1A              ; Defines the first 4 bytes of the header to identify the file as a NES ROM
    .byte 2                       ; Number of 16KB PRG-ROM banks
    .byte 1                       ; Number of 8KB CHR-ROM banks
    .byte %00000001               ; Flags: Vertical mirroring, no save RAM, no mapper
    .byte %00000000               ; No special-case flags set, no mapper, VS/Player Choice (NES 2.0)
    .byte 0                       ; PRG-RAM size. Rarely used, and we don't use it either. =)
    .byte 0                       ; TV system (0 = NTSC, 1 = PAL, 2 = Dendy). Rarely used.
    .byte 0                       ; TV System, PRG-RAM presences. Rarely used, and not official.
    .byte $45, $4C, $4C, $49, $53 ; Unused bytes. Typically set to 0s for padding,
                                  ; but you can put your name here.

.segment "CHR"
    .incbin "TheGame.chr" ; include the CHR ROM file created with NEXXT

; 6502 requires this segment
; It contains the reset, NMI, and IRQ handlers.
; .addr defined the word size of the these sections of code. It's an alias for .word
.segment "VECTORS" ;
    .addr nmi_handler
    .addr reset_handler
    .addr irq_handler

; Zero Page (AKA Direct Page or ZP) variables
; These are used to store temporary values, like the PPU address high and low bytes.
; The Zero Page only has 256 bytes, so we use it for frequently accessed variables.
; It's address from $0000-$00FF
.segment "ZEROPAGE"
    temp_lo: .res 1
    temp_hi: .res 1


.segment "RODATA"
    message_a: .BYTE $22, "GAME", $22, 0 ; "GAME" in quotes
    message_b: .BYTE  "PRESS  START", 0
    message_c: .BYTE "Congratulations", 0
    message_d: .BYTE "You  have", 0
    message_e: .BYTE "L-O-S-T", 0
    message_f: .BYTE "The  Game", 0

.include "draw_border_macro.s" ; Include the macro to draw a box with a border
.include "clear_screen_macro.s" ; Include the macro to clear the screen
.include "print_macro.s" ; Include the macro to print text from CHR ROM

.segment "CODE"
    .export irq_handler
         .proc irq_handler ; 6502 requires this handler
            RTI ; Just exit, we have no use for this handler in this program.
         .endproc

    .export nmi_handler
        .proc nmi_handler ; 6502 requires this handler
            RTI ; Just exit, we have no use for this handler in this program.
        .endproc

    .export reset_handler
        .proc reset_handler ; 6502 requires this handler
            SEI ; Deactivate IRQ (non-NMI interrupts)
            CLD ; Deactivate non-existing decimal mode
               ; NES CPU is a MOS 6502 clone without decimal mode
            LDX #%00000000
            STX PPUCTRL ; PPU is unstable on boot, ignore NMI for now
            STX PPUMASK ; Deactivate PPU drawing, so CPU can safely write to PPU's VRAM
            BIT PPUSTATUS ; Clear the vblank flag; its value on boot cannot be trusted
            vblankwait1: ; PPU unstable on boot, wait for vertical blanking
                BIT PPUSTATUS ; Clear the vblank flag;
                ; and store its value into bit 7 of CPU status register
                BPL vblankwait1 ; repeat until bit 7 of CPU status register is set (1)
            vblankwait2: ; PPU still unstable, wait for another vertical blanking
                BIT PPUSTATUS
                BPL vblankwait2
                ; PPU should be stable enough now

            ClearScreen

            ; Background color (index 0 of first color palette)
            ; is at PPU's VRAM address 3f00
            LDX #$3F ; 3FXX
            STX PPUADDR

            LDX #$00 ; XX00
            STX PPUADDR

            ; Finally, we need indexes of two PPU's internal color
            LDA #$0F ; black for the transparency color (palette 0 color 0)
            STA PPUDATA

            ;LDA #$1C ; cyan for the first background color (palette 0 color 1)
            LDA #$30 ;  White for the first background color (palette 0 color 1)
            STA PPUDATA

            LDA #$30 ; palette 0 color 2 White
            STA PPUDATA

            LDA #$30 ; palette 0 color 3 White
            STA PPUDATA

            ; Example usage: DrawBoarder $20, $41, 25, $2A, $00 ; Draw box with '*' tile, default attribute
            DrawBoarder $20, $41, 25, $2A, $00

            ; Nametable 0
            ; I have chosen a position near the center of the screen
            Print $21, $8D, message_a, $00
            Print $22, $EA, message_b, $00

            ; center viewer to nametable 0
            LDA #0
            STA PPUSCROLL ; X position (this also sets the w register)
            STA PPUSCROLL ; Y position (this also clears the w register)

            ;     BGRsbMmG ?
            LDA #%00001010
            STA PPUMASK ; Enable background drawing and leftmost 8 pixels of screen

            forever:
                NMI:
                    LDA #$00
                    STA $2003       ; set the low byte (00) of the RAM address
                    LDA #$02
                    STA $4014       ; set the high byte (02) of the RAM address, start the transfer
                LatchController:
                    LDA #$01
                    STA $4016
                    LDA #$00
                    STA $4016       ; tell both the controllers to latch buttons
                ReadStart:
                    LDA $4016       ; A
                    LDA $4016       ; B
                    LDA $4016       ; Select
                    LDA $4016       ; Start
                    AND #%00000001  ; only look at bit 0 (Start)
                    BEQ forever   ; branch to forever if Start is NOT pressed (0)

                ; Start pressed! Clear screen and print message
                ; Disable rendering before VRAM writes
                LDA #$00
                STA PPUMASK

                ; Wait for VBlank before clearing
                wait_vblank1:
                    BIT PPUSTATUS
                    BPL wait_vblank1

                ; Clear nametable 0
                ClearScreen

                ; Wait for VBlank before printing message
                wait_vblank2:
                    BIT PPUSTATUS
                    BPL wait_vblank2

                Print $21, $48, message_c, $00
                Print $21, $8B, message_d, $00
                Print $21, $CC, message_e, $00
                Print $22, $0B, message_f, $00

            done_msg:
               ; center viewer to nametable 0
                LDA #0
                STA PPUSCROLL ; X position (this also sets the w register)
                STA PPUSCROLL ; Y position (this also clears the w register)
                ; Re-enable rendering after VRAM writes
                LDA #%00001010
                STA PPUMASK
                JMP done_msg
        .endproc
