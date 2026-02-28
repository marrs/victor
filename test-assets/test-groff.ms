.TL
Test Document
.PP
Here is a diagram:
.VIC
(local eps (require :src.fennel.eps))
(eps.str [:eps {:width 100 :height 100}
          [:newpath]
          [:arc {:cx 50 :cy 50 :r 40 :a1 0 :a2 360}]
          [:stroke]])
.ENDVIC
.PP
End of document.
