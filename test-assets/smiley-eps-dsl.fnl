(local eps (require :src.fennel.eps))

;; SVG smiley redrawn in EPS coordinates.
;; EPS origin is bottom-left, y increases upward, so SVG y-coords are flipped:
;;   y_eps = 100 - y_svg
;;
;; Quadratic bezier smile (SVG: M 30 60 Q 50 80 70 60) converted to cubic:
;;   CP1 = P0 + 2/3*(P1-P0) = (43.33, 26.67)
;;   CP2 = P2 + 2/3*(P1-P2) = (56.67, 26.67)

;; Page: A4 (595x842 pts).  Smiley drawn in a 100x100 unit space, scaled 4x
;; to 400x400 pts and centred: tx = (595-400)/2 = 97.5, ty = (842-400)/2 = 221.

(local smiley
  [:eps {:width 595 :height 842}
   [:translate {:tx 97.5 :ty 221}]
   [:scale {:sx 4 :sy 4}]
   ;; Face — yellow fill
   [:newpath]
   [:arc {:cx 50 :cy 50 :r 45 :a1 0 :a2 360}]
   [:setrgbcolor {:r 1 :g 1 :b 0}]
   [:fill]
   ;; Face — black stroke
   [:newpath]
   [:arc {:cx 50 :cy 50 :r 45 :a1 0 :a2 360}]
   [:setrgbcolor {:r 0 :g 0 :b 0}]
   [:setlinewidth {:w 2}]
   [:stroke]
   ;; Left eye
   [:newpath]
   [:arc {:cx 35 :cy 60 :r 5 :a1 0 :a2 360}]
   [:fill]
   ;; Right eye
   [:newpath]
   [:arc {:cx 65 :cy 60 :r 5 :a1 0 :a2 360}]
   [:fill]
   ;; Smile
   [:newpath]
   [:moveto {:x 30 :y 40}]
   [:curveto {:x1 43.33 :y1 26.67 :x2 56.67 :y2 26.67 :x3 70 :y3 40}]
   [:setlinewidth {:w 3}]
   [:stroke]
   ;; Caption below face — NanumGothic covers U+263A (☺) with proper post names
   [:setfont {:name "NanumGothic" :size 8}]
   [:moveto {:x 8 :y -10}]
   [:show {:str "Hello, World! "}]
   [:glyphshow {:name "uni263A"}]])

(print (eps.str smiley))
