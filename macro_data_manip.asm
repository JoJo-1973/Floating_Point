; ----------------------------------
; Movement between FAC1/2 and memory
; ----------------------------------

; Load a FP number from memory to FAC1/2 (direct addressing)
!macro LoadMEMinFAC fac,addr {
  !if (fac - 2) {
    lda #$00                    ; Number is assumed to be already rounded
    sta FAC1_ROUND

    lda addr+4                  ; Fourth byte of mantissa
    sta FAC1_MANT+3
    lda addr+3                  ; Third byte of mantissa
    sta FAC1_MANT+2
    lda addr+2                  ; Second byte of mantissa
    sta FAC1_MANT+1

    lda addr+1                  ; First byte of mantissa
    sta FAC1_SIGN               ; Bit #7 stores the sign
    ora #%10000000              ; Restore bit #7 of mantissa to "1"
    sta FAC1_MANT

    lda addr                    ; Exponent
    sta FAC1_EXP
  } else {
    lda addr+4                  ; Fourth byte of mantissa
    sta FAC2_MANT+3
    lda addr+3                  ; Third byte of mantissa
    sta FAC2_MANT+2
    lda addr+2                  ; Second byte of mantissa
    sta FAC2_MANT+1

    lda addr+1                  ; First byte of mantissa
    sta FAC2_SIGN               ; Bit #7 stores the sign
    ora #%10000000              ; Restore bit #7 of mantissa to "1"
    sta FAC2_MANT

    lda addr                    ; Exponent
    sta FAC2_EXP
  }
  +AdjustSigns
}

; Load a FP number from memory to FAC1/2 (indirect addressing)
!macro LoadMEMinFAC_Ind fac,addr {
  !if (fac - 2) {
    lda addr                    ; Copy pointer v2 to .A/.Y
    ldy addr+1
    jsr MOVFM                   ; Copy to FAC1
  } else {
    lda addr                    ; Copy pointer v2 to INDEX
    ldy addr+1
    sta INDEX
    sty INDEX+1

    ldy #$04                    ; Fourth byte of mantissa
    lda (INDEX),y
    sta FAC2_MANT+3
    dey                         ; Third byte of mantissa
    lda (INDEX),y
    sta FAC2_MANT+2
    dey                         ; Second byte of mantissa
    lda (INDEX),y
    sta FAC2_MANT+1

    dey                         ; First byte of mantissa
    lda (INDEX),y
    sta FAC2_SIGN               ; Bit #7 stores the sign
    ora #%10000000              ; Restore bit #7 of mantissa to "1"
    sta FAC2_MANT

    dey                         ; Exponent
    lda (INDEX),y
    sta FAC2_EXP
  }
  +AdjustSigns
}

; Store a FP number from FAC1/2 to memory (direct addressing)
!macro StoreFACinMEM fac,addr {
  !if (fac - 2) {
    jsr ROUND                   ; Round the number

    lda FAC1_MANT+3             ; Fourth byte of mantissa
    sta addr+4
    lda FAC1_MANT+2             ; Third byte of mantissa
    sta addr+3
    lda FAC1_MANT+1             ; Second byte of mantissa
    sta addr+2

    lda FAC1_SIGN               ; Put bit #7 of sign in first byte of mantissa
    ora #%01111111              ; .A now is either $7F (+) or $FF (-)
    and FAC1_MANT               ; Overwrite bit #7 of mantissa with sign bit
    sta addr+1

    lda FAC1_EXP                ; Exponent
    sta addr
    lda #$00                    ; set .A to zero
    sta FAC1_ROUND              ; Clear rounding byte
  } else {
    lda FAC2_MANT+3             ; Fourth byte of mantissa
    sta addr+4
    lda FAC2_MANT+2             ; Third byte of mantissa
    sta addr+3
    lda FAC2_MANT+1             ; Second byte of mantissa
    sta addr+2

    lda FAC2_SIGN               ; Put bit #7 of sign in first byte of mantissa
    ora #%01111111              ; .A now is either $7F (+) or $FF (-)
    and FAC2_MANT               ; Overwrite bit #7 of mantissa with sign bit
    sta addr+1

    lda FAC2_EXP                ; Exponent
    sta addr
  }
}

; Store a FP number from FAC1/2 to memory (indirect addressing)
!macro StoreFACinMEM_Ind fac,addr {
  !if (fac - 2) {
    ldx addr                    ; Copy pointer v2 to .X/.Y
    ldy addr+1
    jsr MOVMF                   ; Store FAC1 in memory
  } else {
    ldx addr                      ; Copy pointer v2 to INDEX
    ldy addr+1
    stx INDEX
    sty INDEX+1

    ldy #$04                    ; Fourth byte of mantissa
    lda FAC2_MANT+3
    sta (INDEX),y
    dey                         ; Third byte of mantissa
    lda FAC2_MANT+2
    sta (INDEX),y
    dey                         ; Second byte of mantissa
    lda FAC2_MANT+1
    sta (INDEX),y

    dey                         ; Put bit #7 of sign in first byte of mantissa
    lda FAC2_SIGN
    ora #%01111111              ; .A now is either $7F (+) or $FF (-)
    and FAC2_MANT
    sta (INDEX),y

    dey                         ; Exponent
    lda FAC2_EXP
    sta (INDEX),y
  }
}

; Overwrite FAC2 with FAC1
!macro CopyFAC1toFAC2 {
  jsr ROUND                     ; TODO: FAC2 must be rounded, but FAC1 shouldn't be modified
  lda FAC1_SIGN
  sta FAC2_SIGN

  lda FAC1_MANT+3
  sta FAC2_MANT+3
  lda FAC1_MANT+2
  sta FAC2_MANT+2
  lda FAC1_MANT+1
  sta FAC2_MANT+1
  lda FAC1_MANT
  sta FAC2_MANT

  lda FAC1_EXP
  sta FAC2_EXP

  lda #$00                      ; FAC1 and FAC2 now have the same sign
  sta ARISGN
}

; Overwrite FAC1 with FAC2
!macro CopyFAC2toFAC1 {
  lda FAC2_SIGN
  sta FAC1_SIGN

  lda FAC2_MANT+3
  sta FAC1_MANT+3
  lda FAC2_MANT+2
  sta FAC1_MANT+2
  lda FAC2_MANT+1
  sta FAC1_MANT+1
  lda FAC2_MANT
  sta FAC1_MANT

  lda FAC2_EXP
  sta FAC1_EXP

  lda #$00                      ; FAC1 and FAC2 now have the same sign
  sta ARISGN
  sta FAC1_ROUND                ; Values coming from FAC2 are always exact
}

; Swap FAC1 and FAC2
!macro SwapFAC {
  jsr ROUND                     ; FAC2 can't store extra-precision values, therefore let's round FAC1

  ldx FAC1_SIGN
  ldy FAC2_SIGN
  stx FAC2_SIGN
  sty FAC1_SIGN

  ldx FAC1_MANT+3
  ldy FAC2_MANT+3
  stx FAC2_MANT+3
  sty FAC1_MANT+3

  ldx FAC1_MANT+2
  ldy FAC2_MANT+2
  stx FAC2_MANT+2
  sty FAC1_MANT+2

  ldx FAC1_MANT+1
  ldy FAC2_MANT+1
  stx FAC2_MANT+1
  sty FAC1_MANT+1

  ldx FAC1_MANT
  ldy FAC2_MANT
  stx FAC2_MANT
  sty FAC1_MANT

  ldx FAC1_EXP
  ldy FAC2_EXP
  stx FAC2_EXP
  sty FAC1_EXP
}
