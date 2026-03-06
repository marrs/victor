(local bic (require :src.fennel.bic))
(local xml (require :src.fennel.xml))

(bic.render {:target :svg}
            [:bic {:width 100 :height 120}
             [:circle {:cx 50 :cy 50 :r 45 :fill "yellow" :stroke "black" :stroke-width 2}]
             [:circle {:cx 35 :cy 40 :r 5  :fill "black"}]
             [:circle {:cx 65 :cy 40 :r 5  :fill "black"}]
             [:text {:x 10 :y 110 :font "FreeSans" :size 12 :str "Hello World ☺"}]])

