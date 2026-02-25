(local pic (require :src.fennel.pic))
(local xml (require :src.fennel.xml))

(local smiley
  [:pic {:width 100 :height 100}
   [:circle {:cx 50 :cy 50 :r 45 :fill "yellow" :stroke "black" :stroke-width 2}]
   [:circle {:cx 35 :cy 40 :r 5  :fill "black"}]
   [:circle {:cx 65 :cy 40 :r 5  :fill "black"}]])

(let [[issue result] (pic.render {:target :svg} smiley)]
  (when issue (io.stderr:write (.. issue.msg "\n")))
  (print (xml.str result)))
