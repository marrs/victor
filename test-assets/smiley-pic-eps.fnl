(local pic (require :src.fennel.pic))
(local eps (require :src.fennel.eps))

(local smiley
  [:pic {:width 100 :height 120}
   [:circle {:cx 50 :cy 50 :r 45 :fill "yellow" :stroke "black" :stroke-width 2}]
   [:circle {:cx 35 :cy 40 :r 5  :fill "black"}]
   [:circle {:cx 65 :cy 40 :r 5  :fill "black"}]
   [:text {:x 10 :y 110 :font "FreeSans" :size 12 :str "Hello World ☺"}]])

(let [[issue result] (pic.render {:target :eps} smiley)]
  (when issue (io.stderr:write (.. issue.msg "\n")))
  (print (eps.str result)))
