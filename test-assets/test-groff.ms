.TL
Test Document
.PP
Here is a an :eps example:
.VIC
(local eps (require :src.fennel.eps))
(eps.str [:eps {:width 100 :height 100}
          [:newpath]
          [:arc {:cx 50 :cy 50 :r 40 :a1 0 :a2 360}]
          [:stroke]])
.ENDVIC
.PP
Here is a :bic example:
.VIC
(local bic (require :src.fennel.bic))
(local eps (require :src.fennel.eps))
(let [[_ doc] (bic.render [:bic {:width 100 :height 100}
               [:rect {:x 0 :y 0 :width 100 :height 100}]])]
  (eps.str doc))
.ENDVIC
.PP
End of document.
