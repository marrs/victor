(local xml (require :src.fennel.xml))

(local smiley
  [:svg {:xmlns   "http://www.w3.org/2000/svg"
         :viewBox "0 0 100 100"
         :width   "100"
         :height  "100"}
   [:circle {:cx "50" :cy "50" :r "45"
             :fill "yellow" :stroke "black" :stroke-width "2"}]
   [:circle {:cx "35" :cy "40" :r "5" :fill "black"}]
   [:circle {:cx "65" :cy "40" :r "5" :fill "black"}]
   [:path   {:d "M 30 60 Q 50 80 70 60"
             :fill "none" :stroke "black" :stroke-width "3"}]])

(print (xml.str smiley))
